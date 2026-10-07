/**
 * GET /api/facturas/[id]/enviar-whatsapp
 *
 * Devuelve los datos para que la UI abra wa.me/{phone}?text=... en una pestana
 * nueva. No manda nada por el bridge — la asociacion prefirio adjuntar la
 * factura manualmente en el chat (wa.me no permite adjuntos).
 *
 * Response:
 *   200 { success: true, data: { phone_e164, wa_me_url, caption, pdf_url, filename } }
 *   400/404 { success: false, error }
 */

import { NextRequest, NextResponse } from "next/server";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { normalizeWaPhone } from "@/lib/chat/wa-phone";

export const runtime = "nodejs";

/** Devuelve digitos listos para wa.me (sin + ni espacios). Si no empieza con
 *  codigo de pais, antepone 595 (Paraguay) y saca el 0 inicial local. */
function toWaMeDigits(raw: string): string {
  const d = normalizeWaPhone(raw);
  if (!d) return "";
  if (d.startsWith("595")) return d;
  if (d.startsWith("0")) return "595" + d.slice(1);
  return d;
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!id) return NextResponse.json(errorResponse("Falta id de la factura."), { status: 400 });

  const ctx = await getFacturasSupabaseFromAuth(request);
  if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
  const { auth, supabase } = ctx;

  const { data: factura, error: fErr } = await supabase
    .from("facturas")
    .select("id, numero_factura, monto, moneda, cliente_id")
    .eq("id", id)
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (fErr) return NextResponse.json(errorResponse(fErr.message), { status: 400 });
  if (!factura) return NextResponse.json(errorResponse("Factura no encontrada."), { status: 404 });
  const f = factura as { numero_factura: string; monto: number; moneda: string; cliente_id: string };

  const { data: cliente, error: cErr } = await supabase
    .from("clientes")
    .select("id, nombre_contacto, empresa, tipo_cliente, telefono, telefono_secundario")
    .eq("id", f.cliente_id)
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (cErr) return NextResponse.json(errorResponse(cErr.message), { status: 400 });
  if (!cliente) return NextResponse.json(errorResponse("Cliente no encontrado."), { status: 404 });
  const c = cliente as {
    nombre_contacto?: string | null;
    empresa?: string | null;
    tipo_cliente?: string | null;
    telefono?: string | null;
    telefono_secundario?: string | null;
  };

  const nombreCliente =
    (c.tipo_cliente === "empresa" ? c.empresa : c.nombre_contacto) ??
    c.nombre_contacto ??
    c.empresa ??
    "";
  const telRaw = (c.telefono ?? c.telefono_secundario ?? "").toString();
  const toDigits = toWaMeDigits(telRaw);
  if (!toDigits) {
    return NextResponse.json(
      errorResponse("El cliente no tiene teléfono cargado. Agregalo en la ficha y volvé a intentar."),
      { status: 400 }
    );
  }

  const primerNombre = (nombreCliente.split(" ")[0] || "").trim();
  const saludo = primerNombre ? `Hola ${primerNombre}, ` : "Hola, ";
  const monedaLabel = f.moneda === "USD" ? "USD" : "Gs.";
  const montoStr = Number(f.monto).toLocaleString(f.moneda === "USD" ? "en-US" : "es-PY");
  const caption =
    `${saludo}te comparto tu factura ${f.numero_factura} por ${monedaLabel} ${montoStr}. ` +
    `Cualquier duda, respondé por acá.`;

  const waMeUrl = `https://wa.me/${toDigits}?text=${encodeURIComponent(caption)}`;
  const pdfUrl = `/api/facturas/${id}/sifen/kude?download=1`;
  const filename = `${f.numero_factura || "factura"}.pdf`.replace(/[^\w.-]+/g, "_");

  return NextResponse.json(
    successResponse({
      phone_e164: toDigits,
      wa_me_url: waMeUrl,
      caption,
      pdf_url: pdfUrl,
      filename,
    })
  );
}
