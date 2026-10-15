"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  saveBaileysWhatsappChannel,
  getBaileysChannelStatus,
  type BaileysChannelStatus,
  type ChatChannelRow,
} from "@/lib/chat/actions";

/**
 * Editor para canales "WhatsApp por QR" (provider = baileys).
 *
 * Los canales por QR NO usan credenciales de Meta (Phone Number ID, token, WABA…):
 * se conectan por un "puente" externo y se vinculan escaneando un QR. Por eso tienen
 * su propia pantalla, en vez del formulario de Meta (`WhatsAppChannelForm`), que
 * exige Phone Number ID y al guardar forzaría `provider = meta`, rompiendo el canal.
 *
 * Guarda con `saveBaileysWhatsappChannel` (ruta segura: mantiene provider=baileys y
 * preserva `config.baileys_bridge_url`).
 */
export function WhatsAppBaileysChannelForm({
  channelId,
  initialRow,
  cancelHref,
  onSaved,
}: {
  channelId: string;
  initialRow: ChatChannelRow;
  cancelHref: string;
  onSaved: () => void;
}) {
  const cfg = initialRow.config ?? {};
  const initialBridge =
    typeof cfg.baileys_bridge_url === "string" ? cfg.baileys_bridge_url : "";

  const [nombre, setNombre] = useState(initialRow.nombre ?? "WhatsApp por QR");
  const [bridgeUrl, setBridgeUrl] = useState(initialBridge);
  const [activo, setActivo] = useState(Boolean(initialRow.activo));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [status, setStatus] = useState<BaileysChannelStatus | null>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Estado en vivo del puente: el ERP consulta {bridge_url}/status (server-side).
  useEffect(() => {
    if (!channelId) return;
    let cancelled = false;
    const tick = async () => {
      try {
        const s = await getBaileysChannelStatus(channelId);
        if (!cancelled) setStatus(s);
      } catch {
        /* el próximo tick reintenta */
      }
    };
    void tick();
    pollRef.current = setInterval(tick, 3000);
    return () => {
      cancelled = true;
      if (pollRef.current) clearInterval(pollRef.current);
      pollRef.current = null;
    };
  }, [channelId]);

  // Dejar de consultar cuando ya está conectado.
  useEffect(() => {
    if (status?.connection === "open" && pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  }, [status?.connection]);

  const submit = useCallback(async () => {
    setError(null);
    setSuccess(null);
    const url = bridgeUrl.trim();
    if (url && !/^https?:\/\//i.test(url)) {
      setError("La URL del puente debe empezar con http:// o https://");
      return;
    }
    setSaving(true);
    try {
      await saveBaileysWhatsappChannel({ id: channelId, nombre, bridge_url: url, activo });
      setSuccess("Cambios guardados.");
      onSaved();
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudieron guardar los cambios.");
    } finally {
      setSaving(false);
    }
  }, [channelId, nombre, bridgeUrl, activo, onSaved]);

  const copy = useCallback(async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
    } catch {
      /* noop */
    }
  }, []);

  const connection = status?.connection ?? "starting";
  const connected = connection === "open";

  return (
    <div className="space-y-6">
      <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3">
        <p className="text-xs font-bold uppercase tracking-wide text-emerald-700">WhatsApp por QR</p>
        <p className="mt-1 text-sm text-emerald-950">
          Este canal se conecta por un <strong>puente externo</strong> (Baileys) y se vincula
          escaneando un QR, como WhatsApp Web.
        </p>
        <p className="mt-1 text-xs text-emerald-900/80">
          No usa credenciales de Meta (Phone Number ID, token, WABA): esos campos no aplican acá.
          Para enviar a muchos a la vez, usá campañas, no este canal.
        </p>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-2 text-sm text-rose-800">
          {error}
        </div>
      )}
      {success && (
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm text-emerald-800">
          {success}
        </div>
      )}

      {/* Datos del canal */}
      <div className="space-y-4">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Nombre del canal</span>
          <input
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-emerald-400"
            placeholder="WhatsApp por QR"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">URL del puente</span>
          <input
            value={bridgeUrl}
            onChange={(e) => setBridgeUrl(e.target.value)}
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 font-mono text-sm outline-none focus:border-emerald-400"
            placeholder="https://wa-bridge.tudominio.com"
          />
          <span className="mt-1 block text-xs text-slate-500">
            La dirección del contenedor del puente (Coolify). El ERP la usa para mostrar el QR y enviar.
          </span>
        </label>

        <label className="flex items-center gap-3">
          <input
            type="checkbox"
            checked={activo}
            onChange={(e) => setActivo(e.target.checked)}
            className="h-4 w-4 rounded border-slate-300"
          />
          <span className="text-sm font-semibold text-slate-700">Canal activo</span>
        </label>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => void submit()}
            disabled={saving}
            className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-60"
          >
            {saving ? "Guardando…" : "Guardar cambios"}
          </button>
          <a href={cancelHref} className="text-sm font-semibold text-slate-500 hover:text-slate-800">
            Volver
          </a>
        </div>
      </div>

      {/* Conexión / QR en vivo */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6">
        <div className="mb-4 grid gap-2 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => void copy(channelId)}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-left hover:bg-slate-50"
          >
            <span className="block text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              ERP_CHANNEL_ID (clic para copiar)
            </span>
            <span className="block truncate font-mono text-xs text-slate-800">{channelId}</span>
          </button>
          <button
            type="button"
            onClick={() => void copy(status?.empresaId ?? "")}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-left hover:bg-slate-50"
          >
            <span className="block text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              ERP_EMPRESA_ID (clic para copiar)
            </span>
            <span className="block truncate font-mono text-xs text-slate-800">
              {status?.empresaId ?? "—"}
            </span>
          </button>
        </div>

        {connected ? (
          <div className="text-center">
            <p className="text-3xl">✅</p>
            <p className="mt-2 text-lg font-bold text-slate-900">¡Conectado!</p>
            {status?.meNumber && (
              <p className="mt-1 font-mono text-xs text-slate-500">{status.meNumber}</p>
            )}
            <p className="mt-2 text-sm text-slate-600">
              Este número recibe y envía desde el inbox de Conversaciones.
            </p>
          </div>
        ) : status?.qrDataUrl ? (
          <div className="text-center">
            <p className="text-sm font-semibold text-slate-700">
              Escaneá este QR desde el celular del número
            </p>
            <p className="text-xs text-slate-500">
              WhatsApp → Dispositivos vinculados → Vincular un dispositivo
            </p>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={status.qrDataUrl}
              alt="Código QR para vincular WhatsApp"
              className="mx-auto mt-4 h-56 w-56 rounded-lg border border-slate-200"
            />
            <p className="mt-3 text-xs text-slate-400">El QR se refresca solo. Esta pantalla detecta la conexión.</p>
          </div>
        ) : (
          <div className="text-center">
            <div className="mx-auto h-56 w-56 animate-pulse rounded-lg bg-slate-100" />
            <p className="mt-4 text-sm font-semibold text-slate-700">Esperando al puente…</p>
            <p className="mt-1 text-xs text-slate-500">
              {status?.error
                ? status.error
                : "Cuando el contenedor esté encendido y configurado, acá va a aparecer el QR o el estado."}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
