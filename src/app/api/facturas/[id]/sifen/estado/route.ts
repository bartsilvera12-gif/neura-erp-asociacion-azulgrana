import { NextRequest, NextResponse } from "next/server";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { errorResponse, successResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { correrPaso, estadoSifen } from "@/lib/facturacion/server/sifen-pasos";

/**
 * POST /api/facturas/[id]/sifen/estado
 *
 * Pregunta a la SET cómo quedó la factura electrónica (consulta del lote) y
 * devuelve el estado: enviado (todavía procesando), aprobado o rechazado. Es
 * POST porque la consulta puede actualizar la factura. Lo usa el cartel de
 * "Pago registrado" para esperar la aprobación sin trabar el cobro — mismo
 * patrón que la caja de distribuidora jm (emitir + consultar estado en bucle).
 */
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const ctx = await getFacturasSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const { auth, supabase } = ctx;
    const { id } = await params;
    const facturaId = id?.trim();
    if (!facturaId) return NextResponse.json(errorResponse("Falta la factura."), { status: 400 });

    const antes = await estadoSifen(supabase, auth.empresa_id, facturaId);
    let aviso: string | null = null;
    if (antes.estado_sifen === "enviado" || antes.estado_sifen === "en_proceso") {
      const r = await correrPaso(request, facturaId, "consulta-lote");
      // La SET todavía procesando no es un error: se vuelve a preguntar.
      if (!r.ok) aviso = r.message;
    }
    const ahora = await estadoSifen(supabase, auth.empresa_id, facturaId);
    return NextResponse.json(successResponse({ factura_id: facturaId, aviso, ...ahora }));
  } catch (err) {
    console.error("[/api/facturas/[id]/sifen/estado]", err instanceof Error ? err.message : err);
    return NextResponse.json(
      errorResponse(err instanceof Error ? err.message : "No se pudo consultar a la SET."),
      { status: 500 }
    );
  }
}
