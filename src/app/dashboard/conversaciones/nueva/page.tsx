"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { toWaDigitsPy } from "@/lib/chat/wa-phone";
import { formatTelefonoDisplay, telefonoSignificativo } from "@/lib/telefono";
import { nombreClienteDisplay, nombreClienteContacto } from "@/lib/clientes/display-name";

/**
 * Iniciar una conversación de WhatsApp con un socio que NO escribió primero.
 * Pensado para mensajes INDIVIDUALES (no masivos): WhatsApp por QR banea el número
 * ante envíos masivos no solicitados.
 *
 * Trae los datos de los socios (clientes) para poder buscarlos por nombre, N° de socio
 * o teléfono y completar el número solo (en el formato correcto para WhatsApp). Así se
 * evita el error típico de tipear mal el número y que el mensaje no llegue.
 *
 * Crea/reusa la conversación (POST /api/chat/start-conversation), opcionalmente manda
 * el primer mensaje (POST /api/chat/send) y abre el inbox en esa conversación (?c=).
 */

type SocioRow = {
  id: string;
  nombre?: string | null;
  nombre_contacto?: string | null;
  empresa?: string | null;
  razon_social?: string | null;
  tipo_cliente?: string | null;
  telefono?: string | null;
  telefono_secundario?: string | null;
  numero_socio?: number | null;
};

type Socio = {
  id: string;
  display: string;
  contacto: string | null;
  numeroSocio: number | null;
  /** Dígitos listos para WhatsApp (595…), o "" si el socio no tiene teléfono. */
  waDigits: string;
  /** Texto para buscar (nombre + contacto + N° socio + teléfono), en minúsculas. */
  haystack: string;
};

function toSocio(r: SocioRow): Socio {
  const display = nombreClienteDisplay(r, "Socio sin nombre");
  const contacto = nombreClienteContacto(r);
  const telRaw = (r.telefono ?? "").trim() || (r.telefono_secundario ?? "").trim();
  const waDigits = telRaw ? toWaDigitsPy(telRaw) : "";
  const numeroSocio =
    typeof r.numero_socio === "number" && Number.isFinite(r.numero_socio) ? r.numero_socio : null;
  const haystack = [
    display,
    contacto ?? "",
    numeroSocio != null ? String(numeroSocio) : "",
    telefonoSignificativo(telRaw),
  ]
    .join(" ")
    .toLowerCase();
  return { id: r.id, display, contacto, numeroSocio, waDigits, haystack };
}

export default function NuevaConversacionPage() {
  const router = useRouter();
  const [numero, setNumero] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Socios (clientes) para buscar y completar el número.
  const [socios, setSocios] = useState<Socio[]>([]);
  const [cargandoSocios, setCargandoSocios] = useState(true);
  const [busqueda, setBusqueda] = useState("");
  const [abierto, setAbierto] = useState(false);
  const [socioElegido, setSocioElegido] = useState<Socio | null>(null);
  const buscadorRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancel = false;
    (async () => {
      try {
        const res = await fetchWithSupabaseSession("/api/clientes", { cache: "no-store" });
        const j = (await res.json().catch(() => ({}))) as { success?: boolean; data?: SocioRow[] };
        if (cancel) return;
        const rows = Array.isArray(j.data) ? j.data : [];
        setSocios(rows.map(toSocio));
      } catch {
        // Si falla, igual se puede escribir el número a mano.
      } finally {
        if (!cancel) setCargandoSocios(false);
      }
    })();
    return () => {
      cancel = true;
    };
  }, []);

  // Cerrar el desplegable al hacer clic afuera.
  useEffect(() => {
    function onClickFuera(e: MouseEvent) {
      if (buscadorRef.current && !buscadorRef.current.contains(e.target as Node)) {
        setAbierto(false);
      }
    }
    document.addEventListener("mousedown", onClickFuera);
    return () => document.removeEventListener("mousedown", onClickFuera);
  }, []);

  const resultados = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    if (!q) return socios.slice(0, 8);
    const qDigits = q.replace(/\D/g, "");
    return socios
      .filter((s) => {
        if (s.haystack.includes(q)) return true;
        if (qDigits && s.waDigits.includes(qDigits)) return true;
        return false;
      })
      .slice(0, 8);
  }, [busqueda, socios]);

  function elegirSocio(s: Socio) {
    setSocioElegido(s);
    setAbierto(false);
    setBusqueda("");
    if (s.waDigits) {
      setNumero(s.waDigits);
      setError(null);
    } else {
      setNumero("");
      setError(`${s.display} no tiene teléfono cargado en su ficha. Agregalo o escribí el número a mano.`);
    }
  }

  function limpiarSocio() {
    setSocioElegido(null);
    setNumero("");
  }

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
        {/* Buscador de socios: completa el número solo, en el formato correcto. */}
        <div className="block" ref={buscadorRef}>
          <span className="text-sm font-semibold text-slate-700">Buscar socio</span>
          {socioElegido ? (
            <div className="mt-1 flex items-center justify-between rounded-lg border border-[#4FAEB2]/40 bg-[#4FAEB2]/5 px-3 py-2">
              <div className="min-w-0">
                <div className="truncate text-sm font-semibold text-slate-800">
                  {socioElegido.display}
                  {socioElegido.numeroSocio != null && (
                    <span className="ml-2 text-xs font-normal text-slate-500">
                      N° {socioElegido.numeroSocio}
                    </span>
                  )}
                </div>
                <div className="truncate text-xs text-slate-500">
                  {socioElegido.waDigits
                    ? formatTelefonoDisplay(socioElegido.waDigits)
                    : "Sin teléfono cargado"}
                  {socioElegido.contacto ? ` · ${socioElegido.contacto}` : ""}
                </div>
              </div>
              <button
                type="button"
                onClick={limpiarSocio}
                className="ml-3 shrink-0 text-xs font-semibold text-slate-500 hover:text-slate-800"
              >
                Cambiar
              </button>
            </div>
          ) : (
            <div className="relative mt-1">
              <input
                value={busqueda}
                onChange={(e) => {
                  setBusqueda(e.target.value);
                  setAbierto(true);
                }}
                onFocus={() => setAbierto(true)}
                placeholder={cargandoSocios ? "Cargando socios…" : "Nombre, N° de socio o teléfono"}
                disabled={cargandoSocios}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-[#4FAEB2] disabled:bg-slate-50"
              />
              {abierto && !cargandoSocios && (
                <div className="absolute z-10 mt-1 max-h-72 w-full overflow-auto rounded-lg border border-slate-200 bg-white shadow-lg">
                  {resultados.length === 0 ? (
                    <div className="px-3 py-3 text-sm text-slate-500">
                      No se encontró ningún socio. Podés escribir el número a mano abajo.
                    </div>
                  ) : (
                    resultados.map((s) => (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => elegirSocio(s)}
                        className="flex w-full items-center justify-between gap-2 px-3 py-2 text-left hover:bg-[#4FAEB2]/10"
                      >
                        <div className="min-w-0">
                          <div className="truncate text-sm font-medium text-slate-800">
                            {s.display}
                            {s.numeroSocio != null && (
                              <span className="ml-2 text-xs font-normal text-slate-400">
                                N° {s.numeroSocio}
                              </span>
                            )}
                          </div>
                          {s.contacto && (
                            <div className="truncate text-xs text-slate-400">{s.contacto}</div>
                          )}
                        </div>
                        <span className="shrink-0 font-mono text-xs text-slate-500">
                          {s.waDigits ? formatTelefonoDisplay(s.waDigits) : "sin tel."}
                        </span>
                      </button>
                    ))
                  )}
                </div>
              )}
            </div>
          )}
          <span className="mt-1 block text-xs text-slate-500">
            Elegí un socio y se completa su número solo. O dejalo vacío y escribí el número abajo.
          </span>
        </div>

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
