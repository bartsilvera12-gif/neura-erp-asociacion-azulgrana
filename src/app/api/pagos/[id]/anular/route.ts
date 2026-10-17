import { NextRequest, NextResponse } from "next/server";
import { getAuthWithRol, isAdmin } from "@/lib/middleware/auth";
import { getFacturasServiceClientForEmpresa } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { anularPagoEfectivo } from "@/lib/pagos/anular-pago-efectivo";

/**
 * POST /api/pagos/[id]/anular
 *
 * Anulación ADMINISTRATIVA de un cobro en EFECTIVO mal cargado: marca el pago
 * como 'revertido' (sale de Cobrados y deja de contar) y devuelve el saldo a la
 * factura. Solo admins. Las transferencias se anulan en Conciliación bancaria.
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await getAuthWithRol(request);
    if (!auth?.empresa_id) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    if (!isAdmin(auth)) {
      return NextResponse.json(
        errorResponse("Solo usuarios administradores pueden anular cobros."),
        { status: 403 }
      );
    }

    const { id } = await params;
    const pagoId = id?.trim();
    if (!pagoId) {
      return NextResponse.json(errorResponse("id del cobro es obligatorio"), { status: 400 });
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      body = {};
    }
    const b = body != null && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const motivo = typeof b.motivo === "string" ? b.motivo.trim() : "";
    if (motivo.length < 5) {
      return NextResponse.json(
        errorResponse("El motivo es obligatorio (mínimo 5 caracteres) para registrar la anulación."),
        { status: 400 }
      );
    }
    if (motivo.length > 2000) {
      return NextResponse.json(errorResponse("El motivo no puede superar 2000 caracteres."), { status: 400 });
    }

    const supabase = await getFacturasServiceClientForEmpresa(auth.empresa_id);
    const result = await anularPagoEfectivo(supabase, auth, pagoId, motivo);
    if (!result.ok) {
      return NextResponse.json(errorResponse(result.message), { status: result.status });
    }
    return NextResponse.json(successResponse(result));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
