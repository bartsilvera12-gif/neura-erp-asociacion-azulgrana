import { NextRequest, NextResponse } from "next/server";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { getClientesSupabaseFromAuthWithRol } from "@/lib/clientes/clientes-service-client";
import { calcularNextNumeroSocio } from "@/lib/clientes/next-numero-socio";

/**
 * GET /api/clientes/next-numero-socio
 * Devuelve el siguiente N° de socio libre (MAX + 1) para pre-cargar el input
 * en el form de Nuevo Cliente. El usuario puede editarlo o borrarlo.
 */
export async function GET(request: NextRequest) {
  try {
    const ctx = await getClientesSupabaseFromAuthWithRol(request);
    if (!ctx) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    const next = await calcularNextNumeroSocio(ctx.supabase, ctx.auth.empresa_id);
    return NextResponse.json(successResponse({ next }));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
