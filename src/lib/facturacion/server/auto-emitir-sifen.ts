import "server-only";
import type { AppSupabaseClient } from "@/lib/supabase/schema";
import { correrPaso, estadoSifen, pasosPendientes } from "./sifen-pasos";

/**
 * Interruptor de la emisión automática del DE a la SET al registrar un pago.
 * Arranca APAGADA: solo emite si la variable de entorno SIFEN_AUTO_EMITIR === "1".
 * Para apagarla al instante, poner SIFEN_AUTO_EMITIR=0 (o quitarla) y reiniciar.
 */
export function autoEmisionSifenHabilitada(): boolean {
  return (process.env.SIFEN_AUTO_EMITIR || "").trim() === "1";
}

export type AutoEmitirResultado = {
  intentado: boolean;
  emitido: boolean;
  estado: string | null;
  error: string | null;
};

/**
 * Emite el DE de una factura a la SET si corresponde (hay pasos pendientes), corriendo
 * borrador → xml → firmar → enviar con los mismos handlers del módulo Facturas.
 *
 * Es BEST-EFFORT e IDEMPOTENTE: nunca lanza (el pago ya quedó registrado) y, si la
 * factura ya está emitida/aprobada, no hace nada. Si un paso falla, corta y devuelve el
 * error; la emisión se puede reintentar desde el detalle de la factura.
 */
export async function autoEmitirSifenEnPago(args: {
  request: Request;
  supabase: AppSupabaseClient;
  empresaId: string;
  facturaId: string;
}): Promise<AutoEmitirResultado> {
  const { request, supabase, empresaId, facturaId } = args;
  if (!autoEmisionSifenHabilitada() || !facturaId) {
    return { intentado: false, emitido: false, estado: null, error: null };
  }
  try {
    const { estado_sifen } = await estadoSifen(supabase, empresaId, facturaId);
    const pasos = pasosPendientes(estado_sifen);
    if (pasos.length === 0) {
      return { intentado: true, emitido: false, estado: estado_sifen, error: null };
    }
    for (const paso of pasos) {
      const r = await correrPaso(request, facturaId, paso);
      if (!r.ok) {
        console.warn("[auto-emitir-sifen]", facturaId, r.message);
        return { intentado: true, emitido: false, estado: estado_sifen, error: r.message };
      }
    }
    const fin = await estadoSifen(supabase, empresaId, facturaId);
    return { intentado: true, emitido: true, estado: fin.estado_sifen, error: null };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.warn("[auto-emitir-sifen] excepcion", facturaId, msg);
    return { intentado: true, emitido: false, estado: null, error: msg };
  }
}
