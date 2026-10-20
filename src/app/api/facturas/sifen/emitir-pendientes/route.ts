import { NextRequest, NextResponse } from "next/server";
import { getAuthWithRol, isAdmin } from "@/lib/middleware/auth";
import { getFacturasServiceClientForEmpresa } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { correrPaso, estadoSifen, pasosPendientes } from "@/lib/facturacion/server/sifen-pasos";

/**
 * POST /api/facturas/sifen/emitir-pendientes   (SOLO admin)
 *
 * Emite en lote el documento electrónico de las facturas de aporte PAGADAS que
 * todavía no tienen DE aprobado (backlog). Corre borrador→xml→firmar→enviar y
 * después consulta-lote, con los mismos handlers del módulo Facturas.
 *
 * Es BEST-EFFORT por factura: si una falla (p. ej. rechazo SET), sigue con la
 * siguiente y la reporta. Idempotente: las ya aprobadas/enviadas se saltean.
 *
 * Body: { limit?: number }  → procesa como máximo `limit` facturas (para probar
 * con pocas antes de emitir todo). Sin límite = todas (tope de seguridad 1000).
 */
export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthWithRol(request);
    if (!auth?.empresa_id) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    if (!isAdmin(auth)) {
      return NextResponse.json(
        errorResponse("Solo usuarios administradores pueden emitir en lote."),
        { status: 403 }
      );
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      body = {};
    }
    const b = body != null && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const limit = Math.max(1, Math.min(1000, Number(b.limit) > 0 ? Math.floor(Number(b.limit)) : 1000));

    const supabase = await getFacturasServiceClientForEmpresa(auth.empresa_id);
    const empresaId = auth.empresa_id;

    const { data: cfg } = await supabase
      .from("empresa_sifen_config")
      .select("activo")
      .eq("empresa_id", empresaId)
      .maybeSingle();
    if (!(cfg as { activo?: boolean } | null)?.activo) {
      return NextResponse.json(errorResponse("SIFEN no está activo para esta empresa."), { status: 400 });
    }

    // Candidatas: aporte, PAGADAS, no anuladas. Se filtra DE/ítems factura por factura.
    const { data: facData, error: errF } = await supabase
      .from("facturas")
      .select("id, numero_factura")
      .eq("empresa_id", empresaId)
      .eq("estado", "Pagado")
      .is("anulado_at", null)
      .in("tipo", ["suscripcion", "credito"])
      .order("fecha", { ascending: true });
    if (errF) return NextResponse.json(errorResponse(errF.message), { status: 400 });
    const candidatas = (facData ?? []) as Array<{ id: string; numero_factura: string | null }>;

    const resumen = {
      candidatas_totales: candidatas.length,
      intentadas: 0,
      aprobadas: 0,
      enviadas: 0,
      rechazadas: 0,
      sin_lineas: 0,
      saltadas_ya_emitidas: 0,
      errores: 0,
      detalle: [] as Array<{ numero: string; resultado: string; error?: string }>,
    };

    const FINALES = new Set(["aprobado", "enviado", "cancelado"]);

    for (const f of candidatas) {
      if (resumen.intentadas >= limit) break;

      const antes = await estadoSifen(supabase, empresaId, f.id);
      if (antes.estado_sifen && FINALES.has(antes.estado_sifen)) {
        resumen.saltadas_ya_emitidas++;
        continue;
      }

      // Sin líneas de detalle → no se puede armar el DE; se salta.
      const { count: items } = await supabase
        .from("factura_items")
        .select("id", { count: "exact", head: true })
        .eq("factura_id", f.id)
        .eq("empresa_id", empresaId);
      if (!items || items < 1) {
        resumen.sin_lineas++;
        resumen.detalle.push({ numero: String(f.numero_factura), resultado: "sin_lineas" });
        continue;
      }

      resumen.intentadas++;
      try {
        let fallo: string | null = null;
        for (const paso of pasosPendientes(antes.estado_sifen)) {
          const r = await correrPaso(request, f.id, paso);
          if (!r.ok) {
            fallo = r.message;
            break;
          }
        }
        // Consulta de lote para avanzar enviado → aprobado/rechazado.
        if (!fallo) {
          const est = await estadoSifen(supabase, empresaId, f.id);
          if (est.estado_sifen === "enviado" || est.estado_sifen === "en_proceso") {
            await correrPaso(request, f.id, "consulta-lote");
          }
        }
        const fin = await estadoSifen(supabase, empresaId, f.id);
        const e = fin.estado_sifen ?? "";
        if (e === "aprobado") {
          resumen.aprobadas++;
          resumen.detalle.push({ numero: String(f.numero_factura), resultado: "aprobado" });
        } else if (e === "enviado") {
          resumen.enviadas++;
          resumen.detalle.push({ numero: String(f.numero_factura), resultado: "enviado" });
        } else if (e === "rechazado") {
          resumen.rechazadas++;
          resumen.detalle.push({ numero: String(f.numero_factura), resultado: "rechazado", error: fin.error ?? fallo ?? undefined });
        } else {
          resumen.errores++;
          resumen.detalle.push({ numero: String(f.numero_factura), resultado: e || "error", error: fin.error ?? fallo ?? undefined });
        }
      } catch (e) {
        resumen.errores++;
        resumen.detalle.push({ numero: String(f.numero_factura), resultado: "excepcion", error: e instanceof Error ? e.message : String(e) });
      }
    }

    return NextResponse.json(successResponse(resumen));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
