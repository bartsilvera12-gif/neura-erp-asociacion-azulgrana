"use client";

import { useEffect, useState } from "react";
import { CheckCircle2, MessageCircle, Printer } from "lucide-react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { useFacturaSifenEstados } from "@/hooks/useFacturaSifenEstados";

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

  const sifen = useFacturaSifenEstados(facturaId ? [facturaId] : []);
  const sifenAprobado = !!facturaId && sifen[facturaId]?.estado_sifen === "aprobado";

  const digits = soloDigitosTel(tel);
  const waHref = digits ? `/dashboard/conversaciones?buscar=${encodeURIComponent(digits)}` : null;
  const kudeHref = sifenAprobado && facturaId ? `/api/facturas/${facturaId}/sifen/kude` : null;

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
        {waHref ? (
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
