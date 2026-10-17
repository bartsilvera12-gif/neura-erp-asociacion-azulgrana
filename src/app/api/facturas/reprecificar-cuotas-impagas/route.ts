import { NextRequest, NextResponse } from "next/server";
import { getAuthWithRol, isAdmin } from "@/lib/middleware/auth";
import { getFacturasServiceClientForEmpresa } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { reprecificarCuotasImpagas } from "@/lib/facturacion/reprecificar-cuotas-impagas";

/**
 * POST /api/facturas/reprecificar-cuotas-impagas  (SOLO admin)
 *
 * Pasa las cuotas de aporte IMPAGAS de precio_viejo (25.000) a precio_nuevo
 * (30.000). Solo toca cuotas totalmente impagas (Pendiente/Vencido, tipo aporte);
 * las pagadas no se tocan. Audita en cliente_historial.
 *
 * DRY-RUN por defecto (devuelve el plan). Para aplicar: { "aplicar": true }.
 * Opcional: { "precio_viejo": 25000, "precio_nuevo": 30000 }.
 */
export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthWithRol(request);
    if (!auth?.empresa_id) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    if (!isAdmin(auth)) {
      return NextResponse.json(
        errorResponse("Solo usuarios administradores pueden ejecutar esta operación."),
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
    const aplicar = b.aplicar === true;
    const precioViejo = b.precio_viejo !== undefined ? Number(b.precio_viejo) : undefined;
    const precioNuevo = b.precio_nuevo !== undefined ? Number(b.precio_nuevo) : undefined;
    const desdePeriodo = typeof b.desde_periodo === "string" ? b.desde_periodo.trim() : undefined;

    const supabase = await getFacturasServiceClientForEmpresa(auth.empresa_id);
    const result = await reprecificarCuotasImpagas(supabase, auth, {
      dryRun: !aplicar,
      precioViejo,
      precioNuevo,
      desdePeriodo,
    });
    return NextResponse.json(successResponse(result));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
