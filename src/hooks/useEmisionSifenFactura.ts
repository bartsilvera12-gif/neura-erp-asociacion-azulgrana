"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

/**
 * Emisión de la factura electrónica (SIFEN) de una factura, al estilo de la caja
 * de distribuidora jm: al montarse le pide al servidor que emita el documento
 * (borrador → xml → firma → envío a la SET) con UNA llamada y después pregunta
 * cada pocos segundos hasta que la SET la apruebe. El cobro NO espera a la SET:
 * esto corre aparte, en el cartel de "Pago registrado".
 *
 * Si SIFEN no está activo en la empresa, o la factura no se puede emitir (p. ej.
 * una cuota de un mes pasado), `estado` queda en "inactivo"/"no_disponible" y el
 * cartel simplemente no muestra nada de factura electrónica.
 */

export type EstadoEmisionFactura =
  | "cargando"
  | "inactivo"
  | "no_disponible"
  | "enviando"
  | "esperando"
  | "demorado"
  | "aprobado"
  | "rechazado"
  | "error";

type Respuesta = {
  success?: boolean;
  error?: string;
  data?: {
    sifen_activo?: boolean;
    /** Factura que no se puede emitir (p. ej. sin líneas de detalle): no mostrar nada. */
    no_emitible?: boolean;
    factura_id?: string;
    estado_sifen?: string | null;
    error?: string | null;
    cdc?: string | null;
  };
};

const CADA_MS = 4000;
const INTENTOS = 30; // ≈ 2 minutos

export function useEmisionSifenFactura(facturaId: string | null, habilitado: boolean) {
  const [estado, setEstado] = useState<EstadoEmisionFactura>(
    habilitado && facturaId ? "cargando" : "inactivo"
  );
  const [cdc, setCdc] = useState<string | null>(null);
  const [mensaje, setMensaje] = useState<string | null>(null);
  const intentos = useRef(0);
  const vivo = useRef(true);

  const aplicar = useCallback((j: Respuesta, ok: boolean): "fin" | "seguir" => {
    const d = j.data ?? {};
    if (d.cdc) setCdc(d.cdc);
    if (ok && d.sifen_activo === false) {
      setEstado("inactivo");
      return "fin";
    }
    if (ok && d.no_emitible) {
      // Factura sin líneas (cuota vieja/importada): no es electrónica, no mostrar nada.
      setEstado("no_disponible");
      return "fin";
    }
    const e = d.estado_sifen ?? null;
    if (e === "aprobado") {
      setEstado("aprobado");
      setMensaje(null);
      return "fin";
    }
    if (e === "rechazado") {
      setEstado("rechazado");
      setMensaje(d.error ?? j.error ?? "La SET rechazó la factura.");
      return "fin";
    }
    if (!ok) {
      // La emisión no salió (p. ej. factura de un mes pasado que la SET no
      // acepta). No es un error del cobro: se muestra discreto y se puede
      // reintentar desde el detalle de la factura.
      setEstado("no_disponible");
      setMensaje(d.error ?? j.error ?? null);
      return "fin";
    }
    return "seguir";
  }, []);

  const consultar = useCallback(async () => {
    if (!facturaId || !vivo.current) return;
    try {
      const res = await fetchWithSupabaseSession(`/api/facturas/${facturaId}/sifen/estado`, {
        method: "POST",
      });
      const j = (await res.json().catch(() => ({}))) as Respuesta;
      if (!vivo.current) return;
      if (aplicar(j, res.ok) === "fin") return;
    } catch {
      /* corte de red: se reintenta igual */
    }
    intentos.current += 1;
    if (intentos.current >= INTENTOS) {
      setEstado("demorado");
      return;
    }
    setEstado("esperando");
    setTimeout(() => void consultar(), CADA_MS);
  }, [facturaId, aplicar]);

  const emitir = useCallback(async () => {
    if (!facturaId) return;
    setEstado("enviando");
    setMensaje(null);
    intentos.current = 0;
    try {
      const res = await fetchWithSupabaseSession(`/api/facturas/${facturaId}/sifen/emitir`, {
        method: "POST",
      });
      const j = (await res.json().catch(() => ({}))) as Respuesta;
      if (!vivo.current) return;
      if (aplicar(j, res.ok) === "fin") return;
      setEstado("esperando");
      setTimeout(() => void consultar(), CADA_MS);
    } catch (e) {
      setEstado("error");
      setMensaje(e instanceof Error ? e.message : "No se pudo conectar con el servidor.");
    }
  }, [facturaId, aplicar, consultar]);

  useEffect(() => {
    vivo.current = true;
    if (habilitado && facturaId) void emitir();
    return () => {
      vivo.current = false;
    };
    // Una sola emisión por factura mostrada.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [facturaId, habilitado]);

  return { estado, cdc, mensaje };
}
