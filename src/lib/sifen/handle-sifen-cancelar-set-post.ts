/**
 * Orquestacion del envio del Evento de Cancelacion SIFEN a SET.
 *
 * Flujo:
 *   1. Leer factura + factura_electronica (requiere estado 'aprobado' o 'cancelado')
 *   2. Validar que haya CDC
 *   3. Cargar empresa_sifen_config (p12, password, csc, ambiente, ruc, razon social)
 *   4. Incrementar sifen_evento_seq atomicamente para armar dSecMsg
 *   5. Construir XML del evento, firmarlo, enviarlo por SOAP a /de/ws/eventos/
 *   6. Guardar respuesta en factura_electronica.set_cancelacion_* y traza en
 *      factura_electronica_evento
 *   7. Si SET aprueba (dCodResEve=0601), estado_sifen pasa a 'cancelado' y
 *      set_cancelacion_estado = 'aprobado'
 */

import { NextRequest, NextResponse } from "next/server";
import { errorResponse, successResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { decryptSecret } from "@/lib/sifen/security";
import { downloadSifenCertificadoObject } from "@/lib/sifen/sifen-certificados-storage";
import type { AmbienteSifen } from "@/lib/sifen/types";
import { extractKeyAndCertFromP12 } from "@/lib/sifen/sign-xml";
import { signSifenEventoXml } from "@/lib/sifen/sign-evento-xml";
import { buildCancelacionEventXml } from "@/lib/sifen/rde-evento-cancelacion";
import { enviarEventoSifen } from "@/lib/sifen/enviar-evento-sifen";
import { splitRucParaXml } from "@/lib/sifen/sifen-cdc";

function parseAmbiente(v: string): AmbienteSifen | null {
  if (v === "test" || v === "produccion") return v;
  return null;
}

export async function handleCancelarSetPost(
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

  // 2. Config SIFEN (cert + emisor)
  const { data: cfg, error: cfgErr } = await supabase
    .from("empresa_sifen_config")
    .select("ambiente, activo, certificado_path, certificado_password_encrypted, ruc, razon_social, sifen_evento_seq")
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
    return NextResponse.json(errorResponse("Falta certificado P12 o su contraseña en la configuración SIFEN."), { status: 400 });
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

  // 3. RUC + DV del emisor
  const rucRaw = String(cfg.ruc ?? "").trim();
  const nombreEmisor = String(cfg.razon_social ?? "").trim() || "Emisor";
  let rucEmisor: string, dvEmisor: string;
  try {
    const { cuerpo, dDV } = splitRucParaXml(rucRaw);
    rucEmisor = cuerpo;
    dvEmisor = dDV;
  } catch (e) {
    return NextResponse.json(errorResponse(`RUC del emisor invalido en configuración SIFEN: ${(e as Error).message}`), { status: 400 });
  }

  // 4. Secuencia atomica para dSecMsg
  const { data: seqRow, error: seqErr } = await supabase
    .from("empresa_sifen_config")
    .update({ sifen_evento_seq: (Number(cfg.sifen_evento_seq ?? 0) + 1) })
    .eq("empresa_id", auth.empresa_id)
    .select("sifen_evento_seq")
    .maybeSingle();
  if (seqErr || !seqRow) {
    return NextResponse.json(errorResponse(`No se pudo incrementar la secuencia de eventos: ${seqErr?.message ?? "sin fila"}`), { status: 500 });
  }
  const dSecMsg = String(seqRow.sifen_evento_seq);

  // 5. Armar XML, firmar, enviar
  let xmlEvento: string;
  try {
    xmlEvento = buildCancelacionEventXml({
      cdc,
      motivo,
      dSecMsg,
      rucEmisor,
      dvEmisor,
      nombreEmisor,
    }).xml;
  } catch (e) {
    return NextResponse.json(errorResponse(`Error armando XML del evento: ${(e as Error).message}`), { status: 500 });
  }

  let xmlFirmado: string;
  try {
    const material = extractKeyAndCertFromP12(p12Dl.data, p12Password);
    xmlFirmado = signSifenEventoXml(xmlEvento, material);
  } catch (e) {
    return NextResponse.json(errorResponse(`Error firmando el evento: ${(e as Error).message}`), { status: 500 });
  }

  let resp;
  try {
    resp = await enviarEventoSifen({
      empresaConfig: {
        ambiente,
        certificadoP12: p12Dl.data,
        certificadoPassword: p12Password,
      },
      xmlEventoFirmado: xmlFirmado,
    });
  } catch (e) {
    return NextResponse.json(errorResponse(`Fallo al enviar el evento a SET: ${(e as Error).message}`), { status: 502 });
  }

  // 6. Interpretar respuesta
  const codEve = (resp.dCodResEve ?? "").trim();
  const msgEve = (resp.dMsgResEve ?? resp.dMsgRes ?? "").trim();
  const protAut = (resp.dProtAut ?? "").trim() || null;
  const aprobado = codEve === "0601";  // SIFEN: evento registrado
  const nuevoSetEstado: "enviado" | "aprobado" | "rechazado" = aprobado
    ? "aprobado"
    : codEve
      ? "rechazado"
      : "enviado";

  // 7. Guardar en la factura electronica
  const updates: Record<string, unknown> = {
    set_cancelacion_estado: nuevoSetEstado,
    set_cancelacion_cod_res: codEve || resp.dCodRes || null,
    set_cancelacion_msg_res: msgEve || null,
    set_cancelacion_d_prot_aut: protAut,
    set_cancelacion_at: new Date().toISOString(),
    set_cancelacion_motivo: motivo,
    set_cancelacion_d_sec_msg: dSecMsg,
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
    return NextResponse.json(errorResponse(`Evento enviado pero no se pudo guardar el resultado: ${updErr.message}`), { status: 500 });
  }

  // 8. Traza
  await supabase.from("factura_electronica_evento").insert({
    empresa_id: auth.empresa_id,
    factura_electronica_id: feRow.id,
    tipo: "cancelacion",
    detalle: {
      origen: "api_cancelar_set",
      ambiente,
      dSecMsg,
      dCodRes: resp.dCodRes,
      dMsgRes: resp.dMsgRes,
      dCodResEve: codEve,
      dMsgResEve: msgEve,
      dProtAut: protAut,
      httpStatus: resp.httpStatus,
      aprobado,
      motivo,
    },
  });

  return NextResponse.json(
    successResponse({
      aprobado,
      set_cancelacion_estado: nuevoSetEstado,
      d_cod_res_eve: codEve,
      d_msg_res_eve: msgEve,
      d_prot_aut: protAut,
      d_sec_msg: dSecMsg,
      http_status: resp.httpStatus,
    })
  );
}
