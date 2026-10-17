import { NextRequest, NextResponse } from "next/server";
import { getFacturasSupabaseFromAuth } from "@/lib/facturacion/facturas-service-client";
import { errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { buildFacturaPdfBuffer } from "@/lib/facturacion/factura-pdf";
import { nombreClienteDisplay } from "@/lib/clientes/display-name";
import { createServiceRoleClient } from "@/lib/supabase/service-admin";

export const runtime = "nodejs";

/**
 * GET /api/facturas/[id]/recibo-pdf
 * PDF simple "RECIBO DE CUOTA" (NO SIFEN) para enviar/imprimir el comprobante de
 * una factura interna (cuota de aporte). No requiere documento electrónico.
 * Query `download=1` → attachment.
 */
export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const fid = (id ?? "").trim();
    if (!fid) return NextResponse.json(errorResponse("id de factura es obligatorio"), { status: 400 });

    const ctx = await getFacturasSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const { auth, supabase } = ctx;

    const { data: factura, error: errF } = await supabase
      .from("facturas")
      .select("id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, moneda, tipo, cliente_id")
      .eq("id", fid)
      .eq("empresa_id", auth.empresa_id)
      .maybeSingle();
    if (errF) return NextResponse.json(errorResponse(errF.message), { status: 400 });
    if (!factura) return NextResponse.json(errorResponse("Factura no encontrada."), { status: 404 });
    const f = factura as Record<string, unknown>;

    const { data: cliente } = await supabase
      .from("clientes")
      .select("*")
      .eq("id", String(f.cliente_id ?? ""))
      .eq("empresa_id", auth.empresa_id)
      .maybeSingle();
    const c = (cliente ?? {}) as Record<string, unknown>;

    // Concepto: descripción del primer ítem si existe (ej. "Aporte Mensual Socio").
    let concepto: string | null = null;
    const { data: items } = await supabase
      .from("factura_items")
      .select("descripcion")
      .eq("factura_id", fid)
      .limit(1);
    const it0 = Array.isArray(items) ? (items[0] as { descripcion?: string | null } | undefined) : undefined;
    if (it0?.descripcion) concepto = String(it0.descripcion);

    // Nombre de la empresa (emisor) desde el catálogo.
    let emisorNombre = "Recibo";
    try {
      const catalog = createServiceRoleClient();
      const { data: emp } = await catalog.from("empresas").select("nombre").eq("id", auth.empresa_id).maybeSingle();
      const n = (emp as { nombre?: string | null } | null)?.nombre;
      if (n && String(n).trim()) emisorNombre = String(n).trim();
    } catch {
      /* sin nombre: usa el fallback */
    }

    const pdf = await buildFacturaPdfBuffer({
      factura: {
        numero_factura: String(f.numero_factura ?? ""),
        fecha: String(f.fecha ?? "").slice(0, 10),
        fecha_vencimiento: String(f.fecha_vencimiento ?? "").slice(0, 10),
        monto: Number(f.monto) || 0,
        saldo: Number(f.saldo) || 0,
        estado: String(f.estado ?? ""),
        moneda: String(f.moneda ?? "GS"),
        tipo: String(f.tipo ?? ""),
        concepto,
      },
      cliente: {
        nombre: nombreClienteDisplay(c, "Socio"),
        documento: (c.documento as string | null) ?? (c.ruc as string | null) ?? null,
        numero_socio: (c.numero_socio as string | null) ?? null,
        telefono: (c.telefono as string | null) ?? null,
      },
      emisor: { nombre: emisorNombre },
    });

    const download = request.nextUrl.searchParams.get("download") === "1";
    const fname = `${String(f.numero_factura ?? "recibo")}.pdf`.replace(/[^\w.-]+/g, "_");
    const disp = download ? `attachment; filename="${fname}"` : `inline; filename="${fname}"`;

    return new NextResponse(new Uint8Array(pdf), {
      status: 200,
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": disp,
        "Cache-Control": "private, no-store",
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
