import { NextRequest, NextResponse } from "next/server";
import { getChatPostgresPool } from "@/lib/supabase/chat-pg-pool";
import { toWaDigitsPy } from "@/lib/chat/wa-phone";
import { sendTextViaBaileysBridge } from "@/lib/chat/outbound-send-dispatch";

/**
 * Cron de SALUDO DE CUMPLEAÑOS a socios. Protegido por `CRON_SECRET`.
 *
 * Todos los días busca los socios (clientes activos, no eliminados, con teléfono)
 * cuyo `fecha_nacimiento` cae HOY (mismo mes y día) y a los que todavía no se les
 * mandó el saludo ESTE año, y les envía un WhatsApp por el puente Baileys. Registra
 * el envío en `cumpleanos_enviados` para no repetir (idempotente por empresa+socio+año).
 *
 * Programar (Coolify Scheduled Task / cron externo): 12:00 UTC ≈ 09:00 PYT →
 * cron `0 12 * * *`. Seguridad: `Authorization: Bearer <CRON_SECRET>` → sin él, 401.
 *
 * Query params:
 *  - `dryRun=1` → no envía ni registra, solo lista a quién saludaría hoy.
 */

function isAuthorized(request: NextRequest): boolean {
  const expected = process.env.CRON_SECRET?.trim();
  if (!expected) return false;
  const auth = request.headers.get("authorization") ?? "";
  return auth === `Bearer ${expected}`;
}

function parseBool(v: string | null): boolean {
  const s = (v ?? "").trim().toLowerCase();
  return s === "1" || s === "true" || s === "yes";
}

/** Primer nombre con mayúscula inicial (los nombres se guardan en MAYÚSCULAS). */
function primerNombre(nombre: string | null | undefined): string {
  const first = String(nombre ?? "").trim().split(/\s+/)[0] ?? "";
  if (!first) return "";
  return first.charAt(0).toUpperCase() + first.slice(1).toLowerCase();
}

function mensajeCumple(nombre: string): string {
  const quien = nombre ? `, ${nombre}` : "";
  return `¡Feliz cumpleaños${quien}! 🎉🎂 La Asociación Hernandarias Azulgrana te desea un día espectacular. ¡Gracias por ser parte! 💙`;
}

function schemaSeguro(): string {
  const raw = (process.env.APP_DB_SCHEMA ?? "neura").trim().replace(/^'|'$/g, "");
  return /^[a-z0-9_]+$/.test(raw) ? raw : "neura";
}

type SocioCumple = { id: string; nombre: string | null; telefono: string | null };

async function handle(request: NextRequest) {
  if (!isAuthorized(request)) {
    return NextResponse.json({ ok: false, error: "no autorizado" }, { status: 401 });
  }

  const dryRun = parseBool(new URL(request.url).searchParams.get("dryRun"));
  const schema = schemaSeguro();
  const pool = getChatPostgresPool();
  if (!pool) {
    return NextResponse.json({ ok: false, error: "Pool de base no disponible." }, { status: 500 });
  }

  const resumen = {
    schema,
    dry_run: dryRun,
    empresas: 0,
    cumpleaneros: 0,
    enviados: 0,
    errores: 0,
    sin_puente: 0,
    detalle: [] as Array<{ empresa: string; cliente: string; nombre: string | null; resultado: string; error?: string }>,
  };

  const empresasRes = await pool.query<{ id: string }>(`SELECT id::text AS id FROM "${schema}".empresas`);
  resumen.empresas = empresasRes.rows.length;

  for (const emp of empresasRes.rows) {
    const empresaId = emp.id;

    // Canal WhatsApp por QR (Baileys) activo + su bridge url.
    const chRes = await pool.query<{ config: unknown }>(
      `SELECT config FROM "${schema}".chat_channels
        WHERE empresa_id = $1 AND type = 'whatsapp' AND lower(coalesce(provider,'')) = 'baileys'
          AND coalesce(activo, true) = true
        LIMIT 1`,
      [empresaId]
    );
    const cfg =
      chRes.rows[0]?.config && typeof chRes.rows[0].config === "object"
        ? (chRes.rows[0].config as Record<string, unknown>)
        : {};
    const bridgeUrl = typeof cfg.baileys_bridge_url === "string" ? cfg.baileys_bridge_url.trim() : "";

    // Socios que cumplen HOY (mismo mes y día), activos, con teléfono, no saludados este año.
    const sociosRes = await pool.query<SocioCumple>(
      `SELECT c.id::text AS id, c.nombre, c.telefono
         FROM "${schema}".clientes c
        WHERE c.empresa_id = $1
          AND c.deleted_at IS NULL
          AND coalesce(c.estado, 'activo') = 'activo'
          AND c.fecha_nacimiento IS NOT NULL
          AND to_char(c.fecha_nacimiento, 'MM-DD') = to_char(now(), 'MM-DD')
          AND coalesce(btrim(c.telefono), '') <> ''
          AND NOT EXISTS (
            SELECT 1 FROM "${schema}".cumpleanos_enviados e
             WHERE e.empresa_id = c.empresa_id AND e.cliente_id = c.id
               AND e.anio = EXTRACT(YEAR FROM now())::int
          )`,
      [empresaId]
    );

    resumen.cumpleaneros += sociosRes.rows.length;

    for (const s of sociosRes.rows) {
      const nombre = primerNombre(s.nombre);
      if (dryRun) {
        resumen.detalle.push({ empresa: empresaId.slice(0, 8), cliente: s.id.slice(0, 8), nombre, resultado: "dry_run" });
        continue;
      }
      if (!bridgeUrl) {
        resumen.sin_puente++;
        resumen.detalle.push({ empresa: empresaId.slice(0, 8), cliente: s.id.slice(0, 8), nombre, resultado: "sin_puente" });
        continue;
      }
      const toDigits = toWaDigitsPy(s.telefono ?? "");
      if (!toDigits || toDigits.length < 7) {
        resumen.errores++;
        resumen.detalle.push({ empresa: empresaId.slice(0, 8), cliente: s.id.slice(0, 8), nombre, resultado: "telefono_invalido" });
        continue;
      }
      let r: { ok: boolean; waMessageId?: string | null; error?: string };
      try {
        r = await sendTextViaBaileysBridge(bridgeUrl, toDigits, mensajeCumple(nombre));
      } catch (e) {
        r = { ok: false, error: e instanceof Error ? e.message : String(e) };
      }
      // Registrar SIEMPRE (ok o error) para no reintentar en loop el mismo día; un fallo
      // queda con ok=false y se puede revisar. ON CONFLICT: ya registrado (carrera), se ignora.
      try {
        await pool.query(
          `INSERT INTO "${schema}".cumpleanos_enviados (empresa_id, cliente_id, anio, ok, wa_message_id, error)
           VALUES ($1, $2, EXTRACT(YEAR FROM now())::int, $3, $4, $5)
           ON CONFLICT (empresa_id, cliente_id, anio) DO NOTHING`,
          [empresaId, s.id, r.ok, r.ok ? (r.waMessageId ?? null) : null, r.ok ? null : (r.error ?? "error")]
        );
      } catch {
        /* best-effort: el envío ya salió; si falla el registro, se loguea abajo */
      }
      if (r.ok) {
        resumen.enviados++;
        resumen.detalle.push({ empresa: empresaId.slice(0, 8), cliente: s.id.slice(0, 8), nombre, resultado: "enviado" });
      } else {
        resumen.errores++;
        resumen.detalle.push({ empresa: empresaId.slice(0, 8), cliente: s.id.slice(0, 8), nombre, resultado: "error", error: r.error });
      }
    }
  }

  console.info("[cron][cumpleanos-socios]", {
    schema,
    dry_run: dryRun,
    empresas: resumen.empresas,
    cumpleaneros: resumen.cumpleaneros,
    enviados: resumen.enviados,
    errores: resumen.errores,
  });

  return NextResponse.json({ ok: true, ...resumen });
}

export async function GET(request: NextRequest) {
  return handle(request);
}

export async function POST(request: NextRequest) {
  return handle(request);
}
