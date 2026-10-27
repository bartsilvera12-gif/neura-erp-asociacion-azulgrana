import { NextRequest, NextResponse } from "next/server";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/**
 * POST /api/facturas/consolidar
 *
 * Consolida 2+ cuotas cobradas juntas (del mismo cliente) en UNA sola factura
 * electrónica: la cuota más vieja queda de "portadora" (carrier) con una línea por
 * mes; las demás se anulan marcadas como "consolidada en <portadora>" para no
 * duplicar montos en reportería. Después de esto, se emite el DE de la portadora
 * (que sale con N líneas) con el flujo normal /api/facturas/{carrier}/sifen/emitir.
 *
 * Es atómico: toda la operación corre dentro de la función de base de datos
 * `consolidar_cuotas_en_factura(p_empresa_id, p_factura_ids)`.
 *
 * Body: { factura_ids: string[] }  →  { carrier_id: string }
 */
export async function POST(request: NextRequest) {
  try {
    const ctx = await getFacturasSupabaseFromAuth(request);
    if (!ctx) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    const { auth, supabase } = ctx;

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(errorResponse("Cuerpo JSON inválido"), { status: 400 });
    }
    const raw = body != null && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const ids = Array.isArray(raw.factura_ids)
      ? [...new Set(raw.factura_ids.map((x) => String(x).trim()).filter(Boolean))]
      : [];

    if (ids.length < 2) {
      return NextResponse.json(
        errorResponse("Se requieren al menos 2 facturas para consolidar."),
        { status: 400 }
      );
    }

    const { data, error } = await supabase.rpc("consolidar_cuotas_en_factura", {
      p_empresa_id: auth.empresa_id,
      p_factura_ids: ids,
    });

    if (error) {
      return NextResponse.json(errorResponse(error.message), { status: 400 });
    }
    const carrierId = typeof data === "string" ? data : data == null ? "" : String(data);
    if (!carrierId) {
      return NextResponse.json(
        errorResponse("No se pudo consolidar (sin factura portadora)."),
        { status: 400 }
      );
    }

    return NextResponse.json(successResponse({ carrier_id: carrierId }));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
