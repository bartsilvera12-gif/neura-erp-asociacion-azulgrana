"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

/**
 * Iniciar una conversación de WhatsApp con un socio que NO escribió primero.
 * Pensado para mensajes INDIVIDUALES (no masivos): WhatsApp por QR banea el número
 * ante envíos masivos no solicitados.
 *
 * Crea/reusa la conversación (POST /api/chat/start-conversation), opcionalmente manda
 * el primer mensaje (POST /api/chat/send) y abre el inbox en esa conversación (?c=).
 */
export default function NuevaConversacionPage() {
  const router = useRouter();
  const [numero, setNumero] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const to = numero.replace(/[^\d]/g, "");
    if (to.length < 7) {
      setError("Ingresá un número válido con código de país (ej: 595981234567).");
      return;
    }
    setEnviando(true);
    try {
      const resConv = await fetchWithSupabaseSession("/api/chat/start-conversation", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "same-origin",
        body: JSON.stringify({ to }),
      });
      const jConv = (await resConv.json().catch(() => ({}))) as {
        ok?: boolean;
        conversation_id?: string;
        error?: string;
      };
      if (!resConv.ok || !jConv.ok || !jConv.conversation_id) {
        setError(jConv.error ?? "No se pudo iniciar la conversación.");
        return;
      }
      const conversationId = jConv.conversation_id;

      const texto = mensaje.trim();
      if (texto) {
        const resSend = await fetchWithSupabaseSession("/api/chat/send", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "same-origin",
          body: JSON.stringify({ conversation_id: conversationId, message: texto }),
        });
        const jSend = (await resSend.json().catch(() => ({}))) as { ok?: boolean; error?: string };
        if (!resSend.ok || !jSend.ok) {
          // La conversación quedó creada; avisamos del fallo de envío pero igual la abrimos.
          setError(
            (jSend.error ?? "No se pudo enviar el mensaje.") +
              " (La conversación quedó creada; podés reintentar desde el chat.)"
          );
          router.push(`/dashboard/conversaciones?c=${encodeURIComponent(conversationId)}`);
          return;
        }
      }

      router.push(`/dashboard/conversaciones?c=${encodeURIComponent(conversationId)}`);
    } catch {
      setError("Error de red. Probá de nuevo.");
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-8">
      <div className="mb-6 flex items-center gap-2 text-sm text-slate-500">
        <Link href="/dashboard/conversaciones" className="hover:text-[#4FAEB2]">
          Conversaciones
        </Link>
        <span>/</span>
        <span className="font-medium text-slate-700">Nueva conversación</span>
      </div>

      <h1 className="text-2xl font-bold tracking-tight text-slate-900">Nueva conversación</h1>
      <p className="mt-1 text-sm text-slate-500">
        Escribile a un socio por WhatsApp aunque no haya escrito primero.
      </p>

      <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs text-amber-900">
        ⚠️ Solo para mensajes <strong>individuales</strong>. No lo uses para mandar el mismo mensaje a
        muchos socios de una vez: WhatsApp (por QR) puede <strong>banear el número</strong>.
      </div>

      {error && (
        <div className="mt-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-2 text-sm text-rose-800">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Número (con código de país)</span>
          <input
            value={numero}
            onChange={(e) => setNumero(e.target.value)}
            inputMode="numeric"
            placeholder="595981234567"
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 font-mono text-sm outline-none focus:border-[#4FAEB2]"
          />
          <span className="mt-1 block text-xs text-slate-500">
            Ej: Paraguay sin el 0 → 595 + número (595981234567).
          </span>
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Primer mensaje (opcional)</span>
          <textarea
            value={mensaje}
            onChange={(e) => setMensaje(e.target.value)}
            rows={3}
            placeholder="Hola, te escribimos de la Asociación…"
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-[#4FAEB2]"
          />
          <span className="mt-1 block text-xs text-slate-500">
            Si lo dejás vacío, se abre el chat y escribís ahí.
          </span>
        </label>

        <div className="flex items-center gap-3 pt-2">
          <button
            type="submit"
            disabled={enviando}
            className="rounded-lg bg-[#4FAEB2] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-[#3F8E91] disabled:cursor-not-allowed disabled:opacity-50"
          >
            {enviando ? "Iniciando…" : "Iniciar conversación"}
          </button>
          <Link
            href="/dashboard/conversaciones"
            className="text-sm font-semibold text-slate-500 hover:text-slate-800"
          >
            Cancelar
          </Link>
        </div>
      </form>
    </div>
  );
}
