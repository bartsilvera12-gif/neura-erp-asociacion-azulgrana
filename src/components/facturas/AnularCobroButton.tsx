"use client";

import { useState } from "react";
import { createPortal } from "react-dom";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

/**
 * Acción "Anular cobro" para una factura con cobros en EFECTIVO (SOLO admin).
 * Abre un modal, lista los cobros en efectivo de la factura y permite anular cada
 * uno con un motivo: POST /api/pagos/[id]/anular devuelve el saldo a la factura.
 *
 * Las transferencias NO aparecen acá (se anulan en Conciliación bancaria).
 */

type Cobro = {
  id: string;
  monto: number;
  fecha_pago: string;
  metodo_pago: string;
};

export function AnularCobroButton({
  facturaId,
  saldo,
  monto,
  estado,
  numeroFactura,
  variant = "full",
  onAnulado,
}: {
  facturaId: string;
  /** Saldo pendiente actual de la factura. */
  saldo: number;
  /** Monto total de la factura. Si saldo >= monto, no hay nada cobrado. */
  monto: number;
  estado: string;
  numeroFactura?: string | null;
  variant?: "full" | "compact";
  onAnulado?: () => void | Promise<void>;
}) {
  const [open, setOpen] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [cobros, setCobros] = useState<Cobro[]>([]);
  const [motivo, setMotivo] = useState("");
  const [anulandoId, setAnulandoId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const est = String(estado ?? "").trim();
  // Solo tiene sentido si algo se cobró (saldo < monto) y la factura no es terminal.
  if (!(Number(saldo) < Number(monto)) || est === "Anulado" || est === "Corregida NC") return null;

  async function cargarCobros() {
    setCargando(true);
    setError(null);
    try {
      const res = await fetchWithSupabaseSession(`/api/pagos?factura_id=${encodeURIComponent(facturaId)}`, { cache: "no-store" });
      const j = (await res.json().catch(() => ({}))) as { data?: Array<Record<string, unknown>> };
      const lista = (Array.isArray(j.data) ? j.data : [])
        .filter((p) => String(p.metodo_pago ?? "") === "efectivo")
        .map((p) => ({
          id: String(p.id),
          monto: Number(p.monto) || 0,
          fecha_pago: String(p.fecha_pago ?? "").slice(0, 10),
          metodo_pago: String(p.metodo_pago ?? ""),
        }));
      setCobros(lista);
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudieron cargar los cobros.");
      setCobros([]);
    } finally {
      setCargando(false);
    }
  }

  function abrir() {
    setMotivo("");
    setError(null);
    setCobros([]);
    setOpen(true);
    void cargarCobros();
  }

  async function anular(cobroId: string) {
    const m = motivo.trim();
    if (m.length < 5) {
      setError("Escribí el motivo (mínimo 5 caracteres) antes de anular.");
      return;
    }
    setAnulandoId(cobroId);
    setError(null);
    try {
      const res = await fetchWithSupabaseSession(`/api/pagos/${cobroId}/anular`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ motivo: m }),
      });
      const j = (await res.json().catch(() => ({}))) as { success?: boolean; error?: string };
      if (!res.ok || !j.success) {
        setError(j.error ?? `Error ${res.status}`);
        return;
      }
      await onAnulado?.();
      await cargarCobros();
      if (cobros.length <= 1) setOpen(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error de red");
    } finally {
      setAnulandoId(null);
    }
  }

  const triggerCls =
    variant === "compact"
      ? "inline-flex items-center justify-center rounded-lg border border-red-200 bg-white px-2 py-1 text-[11px] font-semibold text-red-600 transition-colors hover:border-red-300 hover:bg-red-50"
      : "inline-flex items-center justify-center rounded-lg border border-red-200 bg-white px-3 py-2 text-xs font-semibold text-red-600 transition-colors hover:border-red-300 hover:bg-red-50";

  const fmt = (v: number) => Math.round(Number(v) || 0).toLocaleString("es-PY");

  return (
    <>
      <button
        type="button"
        onClick={abrir}
        className={triggerCls}
        title="Anular un cobro en efectivo y devolver el saldo a la factura"
      >
        Anular cobro
      </button>

      {open && typeof document !== "undefined" && createPortal(
        <div
          className="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 p-4"
          role="dialog"
          aria-modal="true"
          onClick={() => !anulandoId && setOpen(false)}
        >
          <div className="w-full max-w-md space-y-3 rounded-xl border border-slate-200 bg-white p-5 shadow-xl" onClick={(e) => e.stopPropagation()}>
            <h4 className="text-sm font-bold text-slate-900">Anular cobro{numeroFactura ? ` — ${numeroFactura}` : ""}</h4>
            <p className="text-xs leading-relaxed text-slate-600">
              Al anular un cobro, <span className="font-semibold">el saldo vuelve a la factura</span>. Solo se listan cobros en
              efectivo (las transferencias se anulan en Conciliación bancaria). Queda auditado.
            </p>

            <label className="block text-xs font-semibold text-slate-600">
              Motivo (obligatorio)
              <textarea
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                rows={2}
                className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-200"
                placeholder="Ej.: cargado por error / el socio no pagó en efectivo"
              />
            </label>

            <div className="max-h-56 overflow-y-auto rounded-lg border border-slate-200">
              {cargando ? (
                <p className="px-3 py-4 text-center text-sm text-slate-400">Cargando cobros…</p>
              ) : cobros.length === 0 ? (
                <p className="px-3 py-4 text-center text-sm text-slate-500">Esta factura no tiene cobros en efectivo para anular.</p>
              ) : (
                cobros.map((c) => (
                  <div key={c.id} className="flex items-center justify-between gap-2 border-b border-slate-100 px-3 py-2 last:border-0">
                    <div className="min-w-0">
                      <div className="text-sm font-semibold text-slate-800">Gs. {fmt(c.monto)}</div>
                      <div className="text-[11px] text-slate-500">{c.fecha_pago || "—"} · efectivo</div>
                    </div>
                    <button
                      type="button"
                      disabled={!!anulandoId}
                      onClick={() => void anular(c.id)}
                      className="shrink-0 rounded-lg bg-red-600 px-3 py-1.5 text-[11px] font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                    >
                      {anulandoId === c.id ? "Anulando…" : "Anular"}
                    </button>
                  </div>
                ))
              )}
            </div>

            {error && <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-800">{error}</div>}
            <div className="flex justify-end pt-1">
              <button type="button" disabled={!!anulandoId} onClick={() => setOpen(false)} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50">
                Cerrar
              </button>
            </div>
          </div>
        </div>,
        document.body,
      )}
    </>
  );
}
