import { NextRequest, NextResponse } from "next/server";
import { getAuthWithRol } from "@/lib/middleware/auth";
import { getChatServiceClientForEmpresa } from "@/app/api/chat/_chat-service-client";
import { normalizeWaPhone } from "@/lib/chat/wa-phone";

/**
 * Le pide al puente Baileys el nombre que WhatsApp conoce del número (agenda del
 * teléfono vinculado / pushName). Devuelve "" si no lo conoce (número no guardado que
 * aún no escribió); en ese caso el nombre se completa solo cuando la persona responde.
 */
async function nombreWhatsAppDesdePuente(bridgeUrl: string, toDigits: string): Promise<string> {
  const url = (bridgeUrl || "").trim().replace(/\/+$/, "");
  const secret = (process.env.BAILEYS_BRIDGE_SECRET || "").trim();
  if (!url || !secret) return "";
  try {
    const res = await fetch(`${url}/contact-name?to=${encodeURIComponent(toDigits)}`, {
      headers: { "x-bridge-secret": secret },
    });
    if (!res.ok) return "";
    const j = (await res.json().catch(() => ({}))) as { name?: string | null };
    return typeof j.name === "string" ? j.name.trim() : "";
  } catch {
    return "";
  }
}

/**
 * POST /api/chat/start-conversation
 * Inicia (o reusa) una conversación de WhatsApp por QR con un número, SIN que la
 * persona haya escrito primero. Crea el contacto y la conversación en modo humano y
 * devuelve el `conversation_id`; el primer mensaje se envía por el flujo normal del
 * inbox (/api/chat/send), que ya rutea por el puente Baileys.
 *
 * Uso previsto: mensajes INDIVIDUALES a socios. No es un envío masivo (WhatsApp por QR
 * no oficial banea el número ante envíos masivos no solicitados).
 *
 * Body: { to: string }  ->  { ok, conversation_id }
 */
export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthWithRol(request);
    if (!auth?.empresa_id) {
      return NextResponse.json({ ok: false, error: "No autenticado" }, { status: 401 });
    }

    const body = (await request.json().catch(() => null)) as { to?: unknown } | null;
    const toDigits = normalizeWaPhone(typeof body?.to === "string" ? body.to : "");
    if (!toDigits || toDigits.length < 7) {
      return NextResponse.json({ ok: false, error: "Número inválido." }, { status: 400 });
    }

    const empresaId = auth.empresa_id;
    const supabase = await getChatServiceClientForEmpresa(empresaId);

    // Canal WhatsApp por QR (Baileys) activo del tenant.
    const { data: channels, error: chErr } = await supabase
      .from("chat_channels")
      .select("id, provider, activo, config")
      .eq("empresa_id", empresaId)
      .eq("type", "whatsapp");
    if (chErr) {
      return NextResponse.json({ ok: false, error: chErr.message }, { status: 500 });
    }
    const channel = (channels ?? []).find(
      (c: { provider?: string | null; activo?: boolean | null }) =>
        String(c.provider ?? "").trim().toLowerCase() === "baileys" && c.activo !== false
    ) as { id?: string; config?: unknown } | undefined;
    if (!channel?.id) {
      return NextResponse.json(
        { ok: false, error: "No hay un canal de WhatsApp por QR activo." },
        { status: 400 }
      );
    }
    const channelId = channel.id;

    // Nombre que WhatsApp conoce del número (vía el puente). Si no lo conoce, el contacto
    // queda sin nombre y se completa solo cuando la persona responde (pushName).
    const cfg =
      channel.config && typeof channel.config === "object" && !Array.isArray(channel.config)
        ? (channel.config as Record<string, unknown>)
        : {};
    const bridgeUrl = typeof cfg.baileys_bridge_url === "string" ? cfg.baileys_bridge_url : "";
    const nombreSocio = await nombreWhatsAppDesdePuente(bridgeUrl, toDigits);

    // Contacto (idempotente por empresa + teléfono).
    const contactPayload: Record<string, unknown> = {
      empresa_id: empresaId,
      phone_number: toDigits,
      phone_normalized: toDigits,
    };
    if (nombreSocio) contactPayload.name = nombreSocio;
    const { data: contact, error: cErr } = await supabase
      .from("chat_contacts")
      .upsert(contactPayload, { onConflict: "empresa_id,phone_number" })
      .select("id")
      .single();
    if (cErr || !contact?.id) {
      return NextResponse.json(
        { ok: false, error: `No se pudo crear el contacto: ${cErr?.message ?? "error"}` },
        { status: 500 }
      );
    }
    const contactId = contact.id as string;

    // ¿Ya existe conversación en este canal? La reusamos.
    const { data: existing } = await supabase
      .from("chat_conversations")
      .select("id")
      .eq("empresa_id", empresaId)
      .eq("contact_id", contactId)
      .eq("channel_id", channelId)
      .maybeSingle();
    if (existing?.id) {
      return NextResponse.json({ ok: true, conversation_id: existing.id as string });
    }

    // Nueva conversación en modo humano (sin bot), igual que una conversación tomada por un agente.
    const { data: conv, error: convErr } = await supabase
      .from("chat_conversations")
      .insert({
        empresa_id: empresaId,
        channel_id: channelId,
        contact_id: contactId,
        status: "open",
        flow_code: null,
        flow_current_node: null,
        flow_status: "human",
        human_taken_over: true,
        last_message_at: null,
        last_message_preview: null,
        unread_count: 0,
      })
      .select("id")
      .single();

    if (convErr?.code === "23505") {
      // carrera: otra request la creó; la releemos.
      const { data: again } = await supabase
        .from("chat_conversations")
        .select("id")
        .eq("empresa_id", empresaId)
        .eq("contact_id", contactId)
        .eq("channel_id", channelId)
        .maybeSingle();
      if (again?.id) return NextResponse.json({ ok: true, conversation_id: again.id as string });
    }
    if (convErr || !conv?.id) {
      return NextResponse.json(
        { ok: false, error: `No se pudo crear la conversación: ${convErr?.message ?? "error"}` },
        { status: 500 }
      );
    }

    return NextResponse.json({ ok: true, conversation_id: conv.id as string });
  } catch (e) {
    console.error("[api/chat/start-conversation]", e);
    return NextResponse.json({ ok: false, error: "Error interno" }, { status: 500 });
  }
}
