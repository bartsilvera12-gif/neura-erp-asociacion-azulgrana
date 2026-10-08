/**
 * Envio del Evento de Cancelacion a SET usando libs Paraguayas en produccion:
 *   - facturacionelectronicapy-xmlgen → arma el XML del evento
 *   - facturacionelectronicapy-xmlsign → firma con el .p12
 *   - facturacionelectronicapy-setapi → envia por SOAP+mTLS al endpoint de eventos
 *
 * Las 3 libs son del mismo autor (marcosjara, TIPS SA) y se usan en facturaSend
 * y otros integradores PY. Replican la combinacion exacta de SOAP/XSD/firma
 * que SET producción acepta — en vez de reinventarla a mano.
 *
 * Como las libs toman el .p12 como PATH (no Buffer), descargamos el certificado
 * a un archivo temporal, usamos, borramos.
 */

import { NextRequest, NextResponse } from "next/server";
import { errorResponse, successResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { decryptSecret } from "@/lib/sifen/security";
import { downloadSifenCertificadoObject } from "@/lib/sifen/sifen-certificados-storage";
import type { AmbienteSifen } from "@/lib/sifen/types";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";
import * as crypto from "node:crypto";
import xmlgen from "facturacionelectronicapy-xmlgen";
import xmlsign from "facturacionelectronicapy-xmlsign";
import setApi from "facturacionelectronicapy-setapi";

function parseAmbiente(v: string): AmbienteSifen | null {
  if (v === "test" || v === "produccion") return v;
  return null;
}

/** Mapea "produccion" → "prod" (lo que esperan las libs TIPS). */
function toSetEnv(a: AmbienteSifen): "test" | "prod" {
  return a === "produccion" ? "prod" : "test";
}

export async function handleCancelarSetPost(
  request: NextRequest,
  params: Promise<{ id: string }>
): Promise<NextResponse> {
  // Wrapper global para que CUALQUIER excepcion termine devolviendo JSON con
  // el mensaje real, en vez de un 500 con body vacio que no dice nada.
  try {
    return await handleCancelarSetPostInner(request, params);
  } catch (e) {
    const m = e instanceof Error ? e.message : String(e);
    const stack = e instanceof Error ? e.stack : "";
    console.error("[cancelar-set][OUTER]", m, stack);
    return NextResponse.json(
      errorResponse(`Error inesperado en cancelar-set: ${m}`),
      { status: 500 }
    );
  }
}

async function handleCancelarSetPostInner(
  request: NextRequest,
  params: Promise<{ id: string }>
): Promise<NextResponse> {
  const ctx = await getFacturasSupabaseFromAuth(request);
  if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
  const { auth, supabase } = ctx;

  const { id: facturaId } = await params;
  const fid = (facturaId ?? "").trim();
  if (!fid) return NextResponse.json(errorResponse("id de factura es obligatorio"), { status: 400 });

  const body = (await request.json().catch(() => ({}))) as { motivo?: string };
  const motivo = (body.motivo ?? "").trim();
  if (motivo.length < 5 || motivo.length > 500) {
    return NextResponse.json(
      errorResponse("motivo es obligatorio y debe tener entre 5 y 500 caracteres."),
      { status: 400 }
    );
  }

  // 1. Factura electronica
  const { data: feRow, error: feErr } = await supabase
    .from("factura_electronica")
    .select("id, estado_sifen, cdc, sifen_aprobado_at, set_cancelacion_estado")
    .eq("factura_id", fid)
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (feErr) return NextResponse.json(errorResponse(feErr.message), { status: 400 });
  if (!feRow) return NextResponse.json(errorResponse("No hay documento electrónico para esta factura."), { status: 404 });

  const estado = String(feRow.estado_sifen ?? "");
  if (estado !== "aprobado" && estado !== "cancelado") {
    return NextResponse.json(
      errorResponse(`Solo se puede cancelar en SET un documento aprobado. Estado actual: "${estado}".`),
      { status: 409 }
    );
  }
  if (String(feRow.set_cancelacion_estado ?? "") === "aprobado") {
    return NextResponse.json(
      errorResponse("Esta factura ya fue cancelada en SET (aprobada por SET)."),
      { status: 409 }
    );
  }
  const cdc = String(feRow.cdc ?? "").trim();
  if (!/^\d{44}$/.test(cdc)) {
    return NextResponse.json(errorResponse("La factura no tiene CDC válido."), { status: 400 });
  }

  // 2. Config SIFEN
  const { data: cfg, error: cfgErr } = await supabase
    .from("empresa_sifen_config")
    .select("ambiente, activo, certificado_path, certificado_password_encrypted, ruc, razon_social, timbrado_numero, sifen_evento_seq")
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (cfgErr) return NextResponse.json(errorResponse(cfgErr.message), { status: 400 });
  if (!cfg) return NextResponse.json(errorResponse("No hay configuración SIFEN para esta empresa."), { status: 400 });
  if (!cfg.activo) return NextResponse.json(errorResponse("La configuración SIFEN está inactiva."), { status: 400 });

  const ambiente = parseAmbiente(String(cfg.ambiente ?? ""));
  if (!ambiente) return NextResponse.json(errorResponse("Ambiente SIFEN inválido."), { status: 400 });

  const certPath = String(cfg.certificado_path ?? "").trim();
  const encPwd = String(cfg.certificado_password_encrypted ?? "").trim();
  if (!certPath || !encPwd) {
    return NextResponse.json(errorResponse("Falta certificado P12 o su contraseña en configuración SIFEN."), { status: 400 });
  }

  let p12Password: string;
  try {
    p12Password = decryptSecret(encPwd);
  } catch (e) {
    const m = e instanceof Error ? e.message : "Error al descifrar la contraseña del certificado";
    return NextResponse.json(errorResponse(m), { status: 500 });
  }

  const p12Dl = await downloadSifenCertificadoObject(supabase, certPath);
  if (!p12Dl.ok) {
    return NextResponse.json(errorResponse(`No se pudo descargar el .p12: ${p12Dl.message}`), { status: 500 });
  }

  // 3. Secuencia atomica para dId
  const { data: seqRow, error: seqErr } = await supabase
    .from("empresa_sifen_config")
    .update({ sifen_evento_seq: (Number(cfg.sifen_evento_seq ?? 0) + 1) })
    .eq("empresa_id", auth.empresa_id)
    .select("sifen_evento_seq")
    .maybeSingle();
  if (seqErr || !seqRow) {
    return NextResponse.json(errorResponse(`No se pudo incrementar la secuencia de eventos: ${seqErr?.message ?? "sin fila"}`), { status: 500 });
  }
  const dId = Number(seqRow.sifen_evento_seq);

  // 4. Escribir el .p12 en un tmp (las libs TIPS esperan path, no Buffer)
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "sifen-event-"));
  const tmpP12 = path.join(tmpDir, `${crypto.randomUUID()}.p12`);
  await fs.writeFile(tmpP12, p12Dl.data);

  let xmlEvento = "";
  let xmlFirmado = "";
  let setRespStr = "";
  let setRespParsed: unknown = null;
  try {
    // 5. Generar XML del evento
    const paramsXmlgen = {
      version: 150,
      ruc: String(cfg.ruc ?? "").trim(),
      razonSocial: String(cfg.razon_social ?? "").trim() || "Emisor",
      timbradoNumero: String(cfg.timbrado_numero ?? "").trim(),
      timbradoFecha: "2024-01-01", // valor dummy — los eventos no validan este campo
      tipoContribuyente: 2,
      tipoRegimen: 8,
      establecimientos: [{ codigo: "001" }],
    };
    const xmlEventoRaw = await xmlgen.generateXMLEventoCancelacion(dId, paramsXmlgen, { cdc, motivo });
    // xmlgen hardcodea `rEve Id="1"` siempre. SIFEN usa (emisor, Id) para
    // detectar duplicados: si antes alguien envio un evento con Id="1" el
    // nuevo rebota con 0100 "Error Inesperado". Lo reemplazo por nuestro
    // dSecMsg que es unico por emisor.
    const idRevUnico = String(dId);
    xmlEvento = xmlEventoRaw.replace(/<rEve Id="1">/g, `<rEve Id="${idRevUnico}">`);

    // 6. Firmar — IMPORTANTE:
    //   - signXMLEvento firma el nodo <rEve>; signXML firmaría <DE> (equivocado).
    //   - 4to param = true fuerza la impl en Node puro. El default es Java y
    //     el container no tiene JDK → se cuelga esperando el proceso Java.
    xmlFirmado = await xmlsign.signXMLEvento(xmlEvento, tmpP12, p12Password, true);

    // 7. Enviar a SET con hard-timeout afuera (Promise.race) — axios timeout
    // interno NO funciona si el handshake mTLS cuelga.
    const env = toSetEnv(ambiente);
    console.log("[cancelar-set] enviando a SET...", { dId, env, xmlLen: xmlFirmado.length });
    const t0 = Date.now();
    const setResp = await Promise.race([
      setApi.evento(dId, xmlFirmado, env, tmpP12, p12Password, {
        debug: true,
        timeout: 20000,
      }),
      new Promise((_r, reject) =>
        setTimeout(() => reject(new Error("Hard timeout 22s en setApi.evento (posible cuelgue mTLS)")), 22000)
      ),
    ]);
    console.log("[cancelar-set] respuesta recibida de SET", { ms: Date.now() - t0 });
    setRespParsed = setResp;
    try {
      // JSON.stringify puede fallar si hay circular refs — fallback a inspect-like.
      setRespStr = typeof setResp === "string" ? setResp : JSON.stringify(setResp, null, 2);
    } catch (serErr) {
      console.error("[cancelar-set] JSON.stringify fallo", serErr);
      setRespStr = "[respuesta no serializable: " + (serErr instanceof Error ? serErr.message : String(serErr)) + "]";
    }
  } catch (e) {
    await fs.rm(tmpDir, { recursive: true, force: true }).catch(() => {});
    const m = e instanceof Error ? e.message : String(e);
    console.error("[cancelar-set] fallo en flujo SIFEN:", m, e instanceof Error ? e.stack : "");
    // Guardar la traza del fallo para debug.
    try {
      await supabase.from("factura_electronica_evento").insert({
        empresa_id: auth.empresa_id,
        factura_electronica_id: feRow.id,
        tipo: "cancelacion",
        detalle: {
          origen: "api_cancelar_set_tips_fallo",
          error: m,
          dId,
          xml_evento: xmlEvento,
          xml_firmado: xmlFirmado,
        },
      });
    } catch {}
    return NextResponse.json(errorResponse(`Error en el flujo SIFEN: ${m}`), { status: 500 });
  }
  await fs.rm(tmpDir, { recursive: true, force: true }).catch(() => {});

  // 8. Parsear respuesta — setApi.evento devuelve el env:Body parseado (objeto).
  // Buscamos los campos SIFEN recursivamente por nombre, ignorando el prefijo
  // de namespace (puede ser ns2:, ns3:, o default). Funciona tanto si setResp
  // viene como objeto parseado como si setRespStr viene como JSON string.
  const findInTree = (node: unknown, name: string, depth = 0): string | null => {
    if (depth > 20) return null; // guard contra circulares
    if (node == null) return null;
    if (typeof node === "string" || typeof node === "number") {
      return String(node);
    }
    if (Array.isArray(node)) {
      for (const el of node) {
        const r = findInTree(el, name, depth + 1);
        if (r != null) return r;
      }
      return null;
    }
    if (typeof node === "object") {
      const o = node as Record<string, unknown>;
      for (const k of Object.keys(o)) {
        const bare = k.replace(/^[^:]+:/, "");
        if (bare === name) {
          const v = o[k];
          if (typeof v === "string" || typeof v === "number") return String(v);
          if (v && typeof v === "object" && "_" in (v as Record<string, unknown>)) {
            const under = (v as Record<string, unknown>)._;
            if (typeof under === "string" || typeof under === "number") return String(under);
          }
          const nested = findInTree(v, name, depth + 1);
          if (nested != null) return nested;
        }
      }
      for (const k of Object.keys(o)) {
        const r = findInTree(o[k], name, depth + 1);
        if (r != null) return r;
      }
    }
    return null;
  };
  const codEve = (findInTree(setRespParsed, "dCodResEve") ?? findInTree(setRespParsed, "dCodRes") ?? "").trim();
  const codLote = (findInTree(setRespParsed, "dCodRes") ?? "").trim();
  const msgEve = (findInTree(setRespParsed, "dMsgResEve") ?? findInTree(setRespParsed, "dMsgRes") ?? "").trim();
  const protAut = (findInTree(setRespParsed, "dProtAut") ?? "").trim() || null;
  const aprobado = codEve === "0601" || codLote === "0601";
  const loteRechazado = codLote !== "" && codLote !== "0300" && codLote !== "0601";
  const nuevoSetEstado: "enviado" | "aprobado" | "rechazado" = aprobado
    ? "aprobado"
    : codEve || loteRechazado
      ? "rechazado"
      : "enviado";

  // 9. Guardar en la factura electronica
  const updates: Record<string, unknown> = {
    set_cancelacion_estado: nuevoSetEstado,
    set_cancelacion_cod_res: codEve || codLote || null,
    set_cancelacion_msg_res: msgEve || null,
    set_cancelacion_d_prot_aut: protAut,
    set_cancelacion_at: new Date().toISOString(),
    set_cancelacion_motivo: motivo,
    set_cancelacion_d_sec_msg: String(dId),
  };
  if (aprobado && estado !== "cancelado") {
    updates.estado_sifen = "cancelado";
    updates.sifen_cancelado_at = new Date().toISOString();
    updates.sifen_cancelacion_motivo = motivo;
  }

  const { error: updErr } = await supabase
    .from("factura_electronica")
    .update(updates)
    .eq("id", feRow.id)
    .eq("empresa_id", auth.empresa_id);
  if (updErr) {
    return NextResponse.json(errorResponse(`Evento enviado pero no se pudo guardar: ${updErr.message}`), { status: 500 });
  }

  // 10. Traza con XMLs + respuesta cruda
  await supabase.from("factura_electronica_evento").insert({
    empresa_id: auth.empresa_id,
    factura_electronica_id: feRow.id,
    tipo: "cancelacion",
    detalle: {
      origen: "api_cancelar_set_tips",
      ambiente,
      dId,
      dCodRes: codLote,
      dMsgRes: findInTree(setRespParsed, "dMsgRes"),
      dCodResEve: codEve,
      dMsgResEve: msgEve,
      dProtAut: protAut,
      aprobado,
      motivo,
      xml_evento_sin_firmar: xmlEvento,
      xml_evento_firmado: xmlFirmado,
      soap_response_cruda: setRespStr,
    },
  });

  return NextResponse.json(
    successResponse({
      aprobado,
      set_cancelacion_estado: nuevoSetEstado,
      d_cod_res_eve: codEve,
      d_msg_res_eve: msgEve,
      d_prot_aut: protAut,
      d_sec_msg: String(dId),
    })
  );
}
