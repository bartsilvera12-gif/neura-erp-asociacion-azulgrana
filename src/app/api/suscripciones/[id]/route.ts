import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/**
 * PATCH /api/suscripciones/:id — edita una suscripción existente.
 *
 * Permite corregir el monto (precio), el plan, la moneda, los días de facturación /
 * vencimiento, la duración y el estado (activa / cancelada) SIN tener que borrar y
 * recrear la suscripción. NO genera facturas: solo actualiza los datos. Los cambios
 * (p. ej. un nuevo precio) rigen para las PRÓXIMAS facturas que genere el sistema; las
 * facturas ya emitidas no se tocan. Scoped por empresa_id.
 *
 * Body (todos opcionales; se actualiza solo lo que venga):
 *   { plan_id?, precio?, moneda?, duracion_meses?, dia_facturacion?, dia_vencimiento?, estado? }
 */
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    const { auth, supabase } = ctx;
    const { id } = await params;
    const suscId = (id ?? "").trim();
    if (!suscId) {
      return NextResponse.json(errorResponse("id es obligatorio"), { status: 400 });
    }

    const body = (await request.json().catch(() => null)) as Record<string, unknown> | null;
    if (!body || typeof body !== "object") {
      return NextResponse.json(errorResponse("Body inválido"), { status: 400 });
    }

    const updates: Record<string, unknown> = {};

    if ("plan_id" in body) {
      const v = body.plan_id;
      updates.plan_id = typeof v === "string" && v.trim() ? v.trim() : null;
    }
    if ("precio" in body) {
      const n = Number(body.precio);
      if (!Number.isFinite(n) || n < 0) {
        return NextResponse.json(errorResponse("precio debe ser >= 0"), { status: 400 });
      }
      updates.precio = n;
    }
    if ("moneda" in body) {
      updates.moneda = body.moneda === "USD" ? "USD" : "GS";
    }
    if ("duracion_meses" in body) {
      const n = Number(body.duracion_meses);
      updates.duracion_meses = Number.isFinite(n) && n > 0 ? Math.floor(n) : 12;
    }
    if ("dia_facturacion" in body) {
      const n = Number(body.dia_facturacion);
      updates.dia_facturacion = Math.min(28, Math.max(1, Number.isFinite(n) ? Math.floor(n) : 1));
    }
    if ("dia_vencimiento" in body) {
      const n = Number(body.dia_vencimiento);
      updates.dia_vencimiento = Math.min(31, Math.max(1, Number.isFinite(n) ? Math.floor(n) : 10));
    }
    if ("estado" in body) {
      const e = String(body.estado ?? "").trim().toLowerCase();
      if (e !== "activa" && e !== "cancelada") {
        return NextResponse.json(
          errorResponse('estado inválido: usá "activa" o "cancelada".'),
          { status: 400 }
        );
      }
      updates.estado = e;
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json(errorResponse("No hay cambios para guardar."), { status: 400 });
    }

    const { data: existing, error: exErr } = await supabase
      .from("suscripciones")
      .select("id")
      .eq("id", suscId)
      .eq("empresa_id", auth.empresa_id)
      .maybeSingle();
    if (exErr) {
      return NextResponse.json(errorResponse(exErr.message), { status: 400 });
    }
    if (!existing) {
      return NextResponse.json(errorResponse("Suscripción no encontrada"), { status: 404 });
    }

    const { data, error: updErr } = await supabase
      .from("suscripciones")
      .update(updates)
      .eq("id", suscId)
      .eq("empresa_id", auth.empresa_id)
      .select("*")
      .single();
    if (updErr) {
      return NextResponse.json(errorResponse(updErr.message), { status: 400 });
    }

    return NextResponse.json(successResponse(data));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}

/**
 * DELETE /api/suscripciones/:id — elimina una suscripción del cliente.
 *
 * Las facturas ya emitidas se CONSERVAN: el FK `facturas_suscripcion_id_fkey` es
 * ON DELETE SET NULL, así que quedan sin vincular a la suscripción pero intactas
 * (no se borra ni se toca ningún pago). Scoped por empresa_id.
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    const { auth, supabase } = ctx;
    const { id } = await params;
    const suscId = (id ?? "").trim();
    if (!suscId) {
      return NextResponse.json(errorResponse("id es obligatorio"), { status: 400 });
    }

    const { data: existing, error: exErr } = await supabase
      .from("suscripciones")
      .select("id")
      .eq("id", suscId)
      .eq("empresa_id", auth.empresa_id)
      .maybeSingle();
    if (exErr) {
      return NextResponse.json(errorResponse(exErr.message), { status: 400 });
    }
    if (!existing) {
      return NextResponse.json(errorResponse("Suscripción no encontrada"), { status: 404 });
    }

    // Cuántas facturas quedarán desvinculadas (informativo para el response).
    const { count: facturasVinculadas } = await supabase
      .from("facturas")
      .select("id", { count: "exact", head: true })
      .eq("empresa_id", auth.empresa_id)
      .eq("suscripcion_id", suscId);

    const { error: delErr } = await supabase
      .from("suscripciones")
      .delete()
      .eq("id", suscId)
      .eq("empresa_id", auth.empresa_id);
    if (delErr) {
      return NextResponse.json(errorResponse(delErr.message), { status: 400 });
    }

    return NextResponse.json(
      successResponse({ id: suscId, deleted: true, facturas_desvinculadas: facturasVinculadas ?? 0 })
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
