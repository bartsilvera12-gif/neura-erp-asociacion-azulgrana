import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

/**
 * Envía la factura (PDF: KuDE si hay SIFEN aprobado, si no el recibo) al socio por
 * el WhatsApp por QR (baileys) DESDE el ERP, sin abrir WhatsApp de afuera.
 *
 * Pasos: datos de envío (`/api/facturas/[id]/enviar-whatsapp`) → iniciar/reusar la
 * conversación (`/api/chat/start-conversation`) → bajar el PDF y mandarlo por el
 * chat (`/api/chat/send-media`, que ya rutea por el puente). Devuelve el
 * `conversationId` para que el caller abra el chat (`/dashboard/conversaciones?c=`).
 *
 * Lo usan el botón WhatsApp del detalle de factura y el cartel "¡Pago registrado!".
 */
export type EnviarFacturaResult = { ok: true; conversationId: string } | { ok: false; error: string };

export async function enviarFacturaPorWhatsapp(facturaId: string): Promise<EnviarFacturaResult> {
  if (!facturaId) return { ok: false, error: "Falta la factura." };

  // 1. Datos de envío: teléfono del socio, caption y URL del PDF.
  const res = await fetchWithSupabaseSession(`/api/facturas/${facturaId}/enviar-whatsapp`, { method: "GET" });
  const j = (await res.json().catch(() => ({}))) as {
    success?: boolean;
    error?: string;
    data?: { pdf_url?: string; filename?: string; phone_e164?: string; caption?: string };
  };
  if (!res.ok || !j.success) return { ok: false, error: j.error ?? `Error ${res.status}` };
  const data = j.data ?? {};
  const digits = (data.phone_e164 ?? "").replace(/\D/g, "");
  if (!digits) return { ok: false, error: "El socio no tiene teléfono cargado." };
  if (!data.pdf_url) return { ok: false, error: "No se pudo generar el PDF de la factura." };

  // 2. Iniciar/reusar la conversación del socio (WhatsApp por QR).
  const cr = await fetchWithSupabaseSession("/api/chat/start-conversation", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ to: digits }),
  });
  const cj = (await cr.json().catch(() => ({}))) as { ok?: boolean; conversation_id?: string; error?: string };
  if (!cr.ok || !cj.ok || !cj.conversation_id) {
    return { ok: false, error: cj.error ?? "No se pudo iniciar la conversación." };
  }
  const conversationId = cj.conversation_id;

  // 3. Bajar el PDF y enviarlo al socio por el chat.
  const pdfRes = await fetchWithSupabaseSession(data.pdf_url, { method: "GET" });
  if (!pdfRes.ok) return { ok: false, error: "No se pudo descargar el PDF de la factura." };
  const blob = await pdfRes.blob();
  const file = new File([blob], data.filename ?? "factura.pdf", { type: blob.type || "application/pdf" });
  const fd = new FormData();
  fd.append("conversation_id", conversationId);
  fd.append("file", file);
  if (data.caption) fd.append("caption", data.caption);
  const sm = await fetchWithSupabaseSession("/api/chat/send-media", { method: "POST", body: fd });
  const sj = (await sm.json().catch(() => ({}))) as { ok?: boolean; error?: string };
  if (!sm.ok || !sj.ok) return { ok: false, error: sj.error ?? "No se pudo enviar la factura." };

  return { ok: true, conversationId };
}
