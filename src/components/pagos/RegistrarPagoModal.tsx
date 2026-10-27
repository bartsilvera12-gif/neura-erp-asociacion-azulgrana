"use client";

import { useCallback, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api/fetch-with-supabase-session";
import { hoyYmdLocal } from "@/lib/fechas/calendario";
import { PagoRegistradoExito } from "@/components/pagos/PagoRegistradoExito";

const inputClass =
  "w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-800 shadow-sm focus:border-[#4FAEB2] focus:outline-none focus:ring-2 focus:ring-[#4FAEB2]/30";
const labelClass = "block text-xs font-medium text-slate-500 mb-1";

/**
 * Ref de la factura desde la que se abre el cobro. `cliente_id` es obligatorio:
 * el modal muestra TODAS las facturas pendientes de ese cliente para permitir
 * cobrar varias en una sola operación (cobro múltiple en efectivo).
 */
export type RegistrarPagoFacturaRef = {
  id: string;
  numero_factura: string;
  saldo: number;
  moneda: "GS" | "USD";
  cliente_id: string;
  cliente_label?: string;
};

type FacturaCliente = {
  id: string;
  numero_factura: string;
  saldo: number;
  estado: string;
  fecha: string | null;
  fecha_vencimiento: string | null;
};

type Fila = { fac: FacturaCliente; checked: boolean; montoStr: string };

const soloDigitos = (s: string) => Number(String(s).replace(/[^\d]/g, "")) || 0;
const fmtGs = (n: number) => `Gs. ${Math.round(n).toLocaleString("es-PY")}`;

export function RegistrarPagoModal({
  open,
  factura,
  onClose,
  onExito,
}: {
  open: boolean;
  factura: RegistrarPagoFacturaRef | null;
  onClose: () => void;
  onExito: () => void | Promise<void>;
}) {
  const [fechaPago, setFechaPago] = useState("");
  const [filas, setFilas] = useState<Fila[]>([]);
  const [cargando, setCargando] = useState(false);
  const [guardando, setGuardando] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [doneMsg, setDoneMsg] = useState<string | null>(null);
  /** Si se cobraron 2+ cuotas y se consolidaron, es la factura "portadora" (una sola factura electrónica). */
  const [consolidadoCarrierId, setConsolidadoCarrierId] = useState<string | null>(null);

  const cargarFacturas = useCallback(async (clienteId: string) => {
    setCargando(true);
    try {
      const r = await apiFetch(`/api/facturas?cliente_id=${encodeURIComponent(clienteId)}`, { cache: "no-store" });
      const j = (await r.json().catch(() => ({}))) as { data?: FacturaCliente[] };
      const lista = (Array.isArray(j.data) ? j.data : [])
        .filter((f) => Number(f.saldo) > 0 && !["Anulado", "Corregida NC"].includes(String(f.estado)))
        .sort((a, b) => {
          const va = a.fecha_vencimiento ?? a.fecha ?? "";
          const vb = b.fecha_vencimiento ?? b.fecha ?? "";
          return va < vb ? -1 : va > vb ? 1 : 0;
        });
      setFilas(lista.map((f) => ({ fac: f, checked: true, montoStr: fmtGs(Number(f.saldo)).replace("Gs. ", "") })));
    } catch {
      setFilas([]);
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    if (!open || !factura) return;
    setFechaPago(hoyYmdLocal());
    setErrorMsg(null);
    setDoneMsg(null);
    setConsolidadoCarrierId(null);
    void cargarFacturas(factura.cliente_id);
  }, [open, factura?.cliente_id, cargarFacturas]);

  if (!open || !factura) return null;

  const seleccionadas = filas.filter((r) => r.checked);
  const total = seleccionadas.reduce((s, r) => s + soloDigitos(r.montoStr), 0);
  const todasTildadas = filas.length > 0 && filas.every((r) => r.checked);

  function setFila(id: string, patch: Partial<Fila>) {
    setFilas((prev) => prev.map((r) => (r.fac.id === id ? { ...r, ...patch } : r)));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (seleccionadas.length === 0) return setErrorMsg("Tildá al menos una factura.");
    for (const r of seleccionadas) {
      const m = soloDigitos(r.montoStr);
      if (m <= 0) return setErrorMsg(`Ingresá un monto válido para ${r.fac.numero_factura}.`);
      if (m > Number(r.fac.saldo)) return setErrorMsg(`El monto de ${r.fac.numero_factura} supera su saldo.`);
    }
    if (!fechaPago) return setErrorMsg("Indicá la fecha del cobro.");

    setGuardando(true);
    setErrorMsg(null);
    // Efectivo = pago directo (aplica el saldo al instante). Se registran en orden (la más
    // vieja primero) porque la regla oldest-first exige saldar antes la cuota anterior.
    let okCount = 0;
    for (const r of seleccionadas) {
      try {
        const res = await apiFetch("/api/pagos", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            factura_id: r.fac.id,
            monto: soloDigitos(r.montoStr),
            fecha_pago: fechaPago,
            metodo_pago: "efectivo",
          }),
        });
        const j = (await res.json().catch(() => ({}))) as { success?: boolean; error?: string };
        if (!res.ok || !j?.success) {
          setGuardando(false);
          await Promise.resolve(onExito());
          setErrorMsg(
            `${r.fac.numero_factura}: ${j?.error || "no se pudo registrar el cobro."}` +
              (okCount > 0 ? ` (${okCount} ya registradas antes).` : "")
          );
          return;
        }
        okCount += 1;
      } catch (err) {
        setGuardando(false);
        await Promise.resolve(onExito());
        setErrorMsg(err instanceof Error ? err.message : "Error de red. Volvé a intentar.");
        return;
      }
    }
    // Cobro de 2+ cuotas juntas → consolidar en UNA sola factura electrónica
    // (una línea por mes). Si falla, se cae al modo anterior (una factura por mes).
    let carrier: string | null = null;
    if (seleccionadas.length >= 2) {
      try {
        const resC = await apiFetch("/api/facturas/consolidar", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ factura_ids: seleccionadas.map((r) => r.fac.id) }),
        });
        const jC = (await resC.json().catch(() => ({}))) as {
          success?: boolean;
          data?: { carrier_id?: string };
          error?: string;
        };
        if (resC.ok && jC?.success && jC.data?.carrier_id) carrier = jC.data.carrier_id;
      } catch {
        /* best-effort: sin consolidar, cada mes emite su propia factura */
      }
    }
    setConsolidadoCarrierId(carrier);
    setGuardando(false);
    await Promise.resolve(onExito());
    setDoneMsg(
      carrier
        ? `${okCount} cuotas cobradas y unificadas en una sola factura electrónica. El saldo ya se actualizó.`
        : `${okCount} ${okCount === 1 ? "factura cobrada" : "facturas cobradas"} en efectivo. El saldo ya se actualizó.`
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose} role="presentation">
      <div
        className="w-full max-w-lg rounded-xl bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <h3 className="mb-1 text-lg font-bold text-gray-800">Registrar cobro</h3>
        <p className="mb-4 text-xs text-slate-500">
          {factura.cliente_label ? <>Cliente: <b>{factura.cliente_label}</b> · </> : null}
          Cobro en <b>efectivo</b>. El saldo se actualiza al instante.
        </p>

        {doneMsg ? (
          <PagoRegistradoExito
            clienteId={factura.cliente_id}
            clienteNombre={factura.cliente_label ?? null}
            facturaId={consolidadoCarrierId ?? factura.id}
            facturaIds={consolidadoCarrierId ? [consolidadoCarrierId] : seleccionadas.map((r) => r.fac.id)}
            mensaje={doneMsg}
            onListo={onClose}
          />
        ) : (
          <>
            {errorMsg && (
              <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">{errorMsg}</div>
            )}
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <div className="mb-1 flex items-center justify-between">
                  <span className={labelClass}>Facturas pendientes</span>
                  {filas.length > 0 && (
                    <label className="flex cursor-pointer items-center gap-1.5 text-xs text-[#3F8E91]">
                      <input
                        type="checkbox"
                        checked={todasTildadas}
                        onChange={(e) => setFilas((prev) => prev.map((r) => ({ ...r, checked: e.target.checked })))}
                      />
                      Seleccionar todas
                    </label>
                  )}
                </div>
                <div className="max-h-56 overflow-y-auto rounded-lg border border-slate-200">
                  {cargando ? (
                    <p className="px-3 py-4 text-center text-sm text-slate-400">Cargando facturas…</p>
                  ) : filas.length === 0 ? (
                    <p className="px-3 py-4 text-center text-sm text-slate-500">Este cliente no tiene facturas pendientes.</p>
                  ) : (
                    filas.map((r) => (
                      <div key={r.fac.id} className="flex items-center gap-2.5 border-b border-slate-100 px-3 py-2 last:border-0">
                        <input type="checkbox" checked={r.checked} onChange={(e) => setFila(r.fac.id, { checked: e.target.checked })} />
                        <div className="min-w-0 flex-1">
                          <div className="text-sm text-slate-800">
                            {r.fac.numero_factura}
                            {r.fac.fecha_vencimiento ? (
                              <span className="text-slate-400"> · vence {String(r.fac.fecha_vencimiento).slice(0, 10)}</span>
                            ) : null}
                          </div>
                          <div className="text-[11px] text-slate-500">Saldo {fmtGs(Number(r.fac.saldo))}</div>
                        </div>
                        <input
                          value={r.montoStr}
                          onChange={(e) => setFila(r.fac.id, { montoStr: e.target.value })}
                          disabled={!r.checked}
                          inputMode="numeric"
                          className={`w-28 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-right text-sm text-slate-800 focus:border-[#4FAEB2] focus:outline-none focus:ring-2 focus:ring-[#4FAEB2]/30 disabled:opacity-40`}
                        />
                      </div>
                    ))
                  )}
                </div>
                <div className="mt-2 flex items-center justify-between rounded-lg bg-slate-50 px-3 py-2">
                  <span className="text-sm text-slate-500">Total a cobrar</span>
                  <span className="text-base font-semibold text-slate-800">{fmtGs(total)}</span>
                </div>
              </div>

              <div>
                <label className={labelClass} htmlFor="rp-fecha">Fecha del cobro</label>
                <input id="rp-fecha" type="date" value={fechaPago} onChange={(e) => setFechaPago(e.target.value)} className={inputClass} required />
              </div>

              <div className="flex gap-3 pt-1">
                <button type="submit" disabled={guardando || cargando} className="rounded-lg bg-[#3F8E91] px-4 py-2 text-sm font-medium text-white hover:bg-[#357a7d] disabled:opacity-50">
                  {guardando ? "Registrando…" : "Cobrar en efectivo"}
                </button>
                <button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-4 py-2 text-sm hover:bg-slate-50">
                  Cancelar
                </button>
              </div>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
