import { NextRequest, NextResponse } from "next/server";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { correrPaso, estadoSifen, pasosPendientes } from "@/lib/facturacion/server/sifen-pasos";

/**
 * POST /api/facturas/[id]/sifen/emitir
 *
 * Emite el documento electrónico de una factura en una sola llamada: corre
 * borrador → xml → firmar → enviar con los MISMOS handlers del módulo Facturas.
 * No espera la aprobación de la SET: eso se consulta aparte con /sifen/estado
 * (igual que la caja de distribuidora jm). Así el cobro nunca queda esperando a
 * la SET; cuando se registra el pago, el front llama a este endpoint y después
 * pregunta el estado hasta que la SET responda.
 *
 * Si SIFEN no está activo para la empresa devuelve `sifen_activo: false` y el
 * front simplemente no muestra nada de factura electrónica.
 *
 * Es idempotente: si la factura ya está aprobada/enviada/cancelada no reemite.
 * Es best-effort desde el punto de vista del cobro: cualquier error se devuelve
 * en la respuesta (el pago ya quedó registrado) y la emisión se puede reintentar
 * desde el detalle de la factura.
 */
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const ctx = await getFacturasSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const { auth, supabase } = ctx;

    const { id } = await params;
    const facturaId = id?.trim();
    if (!facturaId) return NextResponse.json(errorResponse("Falta la factura."), { status: 400 });

    const { data: cfg } = await supabase
      .from("empresa_sifen_config")
      .select("activo, ambiente")
      .eq("empresa_id", auth.empresa_id)
      .maybeSingle();
    const c = (cfg ?? {}) as { activo?: boolean; ambiente?: string | null };
    if (!c.activo) {
      return NextResponse.json(successResponse({ sifen_activo: false }));
    }

    const antes = await estadoSifen(supabase, auth.empresa_id, facturaId);
    for (const paso of pasosPendientes(antes.estado_sifen)) {
      const r = await correrPaso(request, facturaId, paso);
      if (!r.ok) {
        const ahora = await estadoSifen(supabase, auth.empresa_id, facturaId);
        return NextResponse.json(
          { ...errorResponse(r.message), data: { sifen_activo: true, factura_id: facturaId, ...ahora } },
          { status: 400 }
        );
      }
    }

    const despues = await estadoSifen(supabase, auth.empresa_id, facturaId);
    return NextResponse.json(
      successResponse({
        sifen_activo: true,
        ambiente: c.ambiente ?? null,
        factura_id: facturaId,
        ...despues,
      })
    );
  } catch (err) {
    console.error("[/api/facturas/[id]/sifen/emitir]", err instanceof Error ? err.message : err);
    return NextResponse.json(
      errorResponse(err instanceof Error ? err.message : "No se pudo emitir la factura electrónica."),
      { status: 500 }
    );
  }
}
