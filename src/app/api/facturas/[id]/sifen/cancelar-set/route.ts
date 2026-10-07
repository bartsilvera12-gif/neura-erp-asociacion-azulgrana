import { NextRequest } from "next/server";
import { handleCancelarSetPost } from "@/lib/sifen/handle-sifen-cancelar-set-post";

export const runtime = "nodejs";

/**
 * POST /api/facturas/[id]/sifen/cancelar-set
 * Body: { motivo: string (5-500 chars) }
 *
 * Envia el Evento de Cancelacion a SET. A diferencia de /cancelar (que solo
 * cambia el estado en el ERP), este endpoint construye el XML del evento, lo
 * firma y lo despacha al endpoint de eventos SIFEN. Si SET aprueba (0601),
 * la factura queda cancelada tambien a nivel fiscal.
 *
 * Plazo oficial SIFEN: 48 hs desde dEmisionDE. Fuera de plazo, SET rechaza
 * y hay que ir por Nota de Credito.
 */
export async function POST(request: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  return handleCancelarSetPost(request, ctx.params);
}
