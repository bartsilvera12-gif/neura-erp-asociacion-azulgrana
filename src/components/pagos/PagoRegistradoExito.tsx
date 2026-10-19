"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, Loader2, MessageCircle, Printer } from "lucide-react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { enviarFacturaPorWhatsapp } from "@/lib/facturacion/enviar-factura-por-whatsapp";
import { useEmisionSifenFactura } from "@/hooks/useEmisionSifenFactura";

/**
 * Pantalla de éxito "¡Pago registrado!" (inspirada en el comprobante de venta de
 * distribuidora jm). Se muestra DENTRO del modal del caller cuando el cobro se
 * registró bien.
 *
 * Botones:
 *  - WhatsApp: lleva al módulo Conversaciones filtrando por el teléfono del socio
 *    (deep-link `?buscar=` — mismo patrón que el CRM). El teléfono se "estira" del
 *    propio cliente: si no viene por prop, se busca por `clienteId`.
 *  - Imprimir: abre el KuDE (factura electrónica) en una pestaña nueva, solo si la
 *    SET ya la aprobó.
 *  - Listo: cierra.
 *
 * No incluye "Compartir" a propósito.
 */

/** Teléfono guardado (`+595 9xx-xxx-xxx`) → solo dígitos para el buscador de Conversaciones. */
function soloDigitosTel(tel: string | null | undefined): string {
  return (tel ?? "").replace(/\D/g, "");
}

export function PagoRegistradoExito({
  clienteId,
  clienteTelefono,
  clienteNombre,
  facturaId,
  mensaje,
  onListo,
}: {
  /** Cliente/socio del cobro. Se usa para buscar el teléfono si no viene por prop. */
  clienteId: string;
  /** Teléfono del socio, si el caller ya lo tiene. Si falta, se busca por `clienteId`. */
  clienteTelefono?: string | null;
  clienteNombre?: string | null;
  /** Factura desde la que se cobró, para el botón Imprimir (KuDE). */
  facturaId?: string | null;
  /** Texto informativo opcional (p. ej. "queda pendiente de aprobación…"). */
  mensaje?: string | null;
  onListo: () => void;
}) {
  const router = useRouter();
  // El teléfono que nos pasó el caller manda; si no vino, lo "estiramos" del cliente.
  const telProp = clienteTelefono ?? "";
  const [telBuscado, setTelBuscado] = useState<string>("");
  const tel = telProp || telBuscado;

  useEffect(() => {
    if (telProp || !clienteId) return;
    let cancelado = false;
    (async () => {
      try {
        const res = await fetchWithSupabaseSession(`/api/clientes/${clienteId}`, { cache: "no-store" });
        const j = (await res.json().catch(() => ({}))) as { data?: { telefono?: string | null } };
        if (!cancelado) setTelBuscado(j.data?.telefono ?? "");
      } catch {
        /* sin teléfono: el botón de WhatsApp queda deshabilitado */
      }
    })();
    return () => {
      cancelado = true;
    };
  }, [clienteId, telProp]);

  // Emisión automática de la factura electrónica (estilo caja distribuidora jm):
  // al mostrarse el cartel se emite el DE y se consulta la SET hasta que aprueba.
  // El cobro ya quedó registrado; esto corre aparte, sin trabarlo.
  const emision = useEmisionSifenFactura(facturaId ?? null, Boolean(facturaId));
  const sifenAprobado = emision.estado === "aprobado";

  const digits = soloDigitosTel(tel);
  const waHref = digits ? `/dashboard/conversaciones?buscar=${encodeURIComponent(digits)}` : null;
  const kudeHref = sifenAprobado && facturaId ? `/api/facturas/${facturaId}/sifen/kude` : null;

  // Enviar la factura por WhatsApp DESDE el ERP (no abre WhatsApp de afuera):
  // manda el PDF al socio por el puente y abre el chat de la conversación.
  const [waBusy, setWaBusy] = useState(false);
  const [waMsg, setWaMsg] = useState<string | null>(null);
  async function enviarFacturaWhatsapp() {
    if (!facturaId) return;
    setWaBusy(true);
    setWaMsg(null);
    try {
      const r = await enviarFacturaPorWhatsapp(facturaId);
      if (!r.ok) {
        setWaMsg(r.error);
        return;
      }
      setWaMsg("Factura enviada por WhatsApp. Abriendo el chat…");
      router.push(`/dashboard/conversaciones?c=${encodeURIComponent(r.conversationId)}`);
    } catch (e) {
      setWaMsg(e instanceof Error ? e.message : "Error de red. Volvé a intentar.");
    } finally {
      setWaBusy(false);
    }
  }

  return (
    <div className="space-y-4 text-center">
      <div className="flex flex-col items-center gap-2">
        <CheckCircle2 className="h-12 w-12 text-emerald-500" strokeWidth={1.75} />
        <h3 className="text-lg font-bold text-gray-800">¡Pago registrado!</h3>
        {clienteNombre ? <p className="text-sm text-slate-500">{clienteNombre}</p> : null}
      </div>

      {mensaje ? (
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2.5 text-left text-sm text-emerald-800">
          {mensaje}
        </div>
      ) : null}

      <div className="space-y-2">
        {facturaId ? (
          <button
            type="button"
            onClick={enviarFacturaWhatsapp}
            disabled={waBusy}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-emerald-600 py-3 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-60"
          >
            <MessageCircle className="h-4 w-4" />
            {waBusy ? "Preparando…" : "Enviar factura por WhatsApp"}
          </button>
        ) : waHref ? (
          <a
            href={waHref}
            target="_blank"
            rel="noopener noreferrer"
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-emerald-600 py-3 text-sm font-semibold text-white hover:bg-emerald-700"
          >
            <MessageCircle className="h-4 w-4" />
            Escribirle por WhatsApp
          </a>
        ) : (
          <p className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs text-slate-500">
            El socio no tiene teléfono cargado para WhatsApp.
          </p>
        )}
        {waMsg ? (
          <p className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2.5 text-left text-xs text-slate-600">{waMsg}</p>
        ) : null}

        {/* Estado de la emisión de la factura electrónica (SIFEN), en vivo. */}
        {emision.estado === "enviando" || emision.estado === "esperando" ? (
          <div className="flex items-center gap-2 rounded-lg border border-sky-200 bg-sky-50 px-3 py-2.5 text-left">
            <Loader2 className="h-4 w-4 shrink-0 animate-spin text-sky-600" />
            <p className="text-xs text-sky-900">
              {emision.estado === "enviando"
                ? "Emitiendo la factura electrónica a la SET…"
                : "Esperando la aprobación de la SET…"}
            </p>
          </div>
        ) : emision.estado === "aprobado" ? (
          <p className="flex items-center justify-center gap-1.5 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2.5 text-xs font-semibold text-emerald-800">
            <CheckCircle2 className="h-4 w-4" />
            Factura electrónica aprobada por la SET
          </p>
        ) : emision.estado === "demorado" ? (
          <p className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2.5 text-left text-xs text-slate-600">
            La SET está demorando. La factura quedó pendiente de aprobación; podés seguir y revisarla
            más tarde desde el detalle de la factura.
          </p>
        ) : emision.estado === "rechazado" ? (
          <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2.5 text-left text-xs text-amber-800">
            La SET no aprobó la factura electrónica{emision.mensaje ? `: ${emision.mensaje}` : "."} Podés
            regenerarla desde el detalle de la factura.
          </p>
        ) : null}

        {/* Imprimir: solo si hay factura electrónica aprobada por la SET (KuDE). Las cuotas
            internas (Sin SIFEN) no tienen KuDE, así que no se muestra nada. */}
        {kudeHref ? (
          <a
            href={kudeHref}
            target="_blank"
            rel="noopener noreferrer"
            className="flex w-full items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white py-3 text-sm font-semibold text-slate-800 hover:bg-slate-50"
          >
            <Printer className="h-4 w-4" />
            Imprimir factura (KuDE)
          </a>
        ) : null}

        <button
          type="button"
          onClick={onListo}
          className="w-full rounded-xl border border-slate-200 bg-white py-2.5 text-sm font-medium text-slate-600 hover:bg-slate-50"
        >
          Listo
        </button>
      </div>
    </div>
  );
}
