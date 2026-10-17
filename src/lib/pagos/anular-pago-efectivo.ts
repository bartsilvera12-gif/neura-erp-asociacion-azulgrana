import "server-only";

/**
 * Anula un cobro en EFECTIVO: marca el pago como 'revertido' (sale de la lista
 * de Cobrados y deja de contar como cobrado) y le devuelve el saldo a la factura.
 *
 * Solo aplica a cobros en efectivo. Las transferencias se anulan en Conciliación
 * bancaria (api/cobranzas/conciliacion/[id]/anular), que además hace la reversión
 * contable. Un cobro en efectivo no genera asiento (registrarPago solo emite un
 * webhook), así que acá no hay nada contable que revertir.
 */

export type AnularPagoEfectivoAuth = {
  empresa_id: string;
  user?: { id?: string | null; email?: string | null } | null;
};

export type AnularPagoEfectivoResult =
  | { ok: true; ya_anulado: boolean; factura_id?: string; nuevo_saldo?: number; nuevo_estado?: string }
  | { ok: false; status: number; message: string };

type PagoRow = {
  id: string;
  factura_id: string | null;
  monto: number | string | null;
  metodo_pago: string | null;
  estado_contable: string | null;
  cliente_id: string | null;
};

type FacturaRow = {
  id: string;
  monto: number | string | null;
  saldo: number | string | null;
  estado: string | null;
  numero_factura: string | null;
};

export async function anularPagoEfectivo(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  auth: AnularPagoEfectivoAuth,
  pagoId: string,
  motivo: string
): Promise<AnularPagoEfectivoResult> {
  const id = (pagoId ?? "").trim();
  if (!id) return { ok: false, status: 400, message: "id del cobro es obligatorio" };

  const { data: pagoData, error: errP } = await supabase
    .from("pagos")
    .select("id, factura_id, monto, metodo_pago, estado_contable, cliente_id")
    .eq("id", id)
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (errP) return { ok: false, status: 400, message: errP.message };
  const pago = pagoData as PagoRow | null;
  if (!pago) return { ok: false, status: 404, message: "Cobro no encontrado" };

  if (String(pago.metodo_pago ?? "") !== "efectivo") {
    return {
      ok: false,
      status: 409,
      message: "Solo se pueden anular cobros en efectivo acá. Una transferencia se anula en Conciliación bancaria.",
    };
  }
  // Idempotente: si ya estaba revertido, no hacemos nada (y no devolvemos el saldo dos veces).
  if (String(pago.estado_contable ?? "") === "revertido") {
    return { ok: true, ya_anulado: true, factura_id: pago.factura_id ?? undefined };
  }
  if (!pago.factura_id) {
    return { ok: false, status: 409, message: "El cobro no tiene factura asociada." };
  }

  const { data: facData, error: errF } = await supabase
    .from("facturas")
    .select("id, monto, saldo, estado, numero_factura")
    .eq("id", pago.factura_id)
    .eq("empresa_id", auth.empresa_id)
    .maybeSingle();
  if (errF) return { ok: false, status: 400, message: errF.message };
  const factura = facData as FacturaRow | null;
  if (!factura) return { ok: false, status: 404, message: "Factura no encontrada" };

  const montoPago = Number(pago.monto) || 0;
  const montoFactura = Number(factura.monto) || 0;
  const nuevoSaldo = Math.min(montoFactura, (Number(factura.saldo) || 0) + montoPago);
  const nuevoEstado = nuevoSaldo <= 0 ? "Pagado" : String(factura.estado) === "Vencido" ? "Vencido" : "Pendiente";

  // 1) Marcar el pago como revertido.
  const estadoPrevio = pago.estado_contable ?? null;
  const { error: errUpdPago } = await supabase
    .from("pagos")
    .update({ estado_contable: "revertido" })
    .eq("id", id)
    .eq("empresa_id", auth.empresa_id);
  if (errUpdPago) return { ok: false, status: 400, message: errUpdPago.message };

  // 2) Devolver el saldo a la factura. Si falla, deshacemos la marca del pago.
  const { error: errUpdFac } = await supabase
    .from("facturas")
    .update({ saldo: nuevoSaldo, estado: nuevoEstado, updated_at: new Date().toISOString() })
    .eq("id", factura.id)
    .eq("empresa_id", auth.empresa_id);
  if (errUpdFac) {
    await supabase.from("pagos").update({ estado_contable: estadoPrevio }).eq("id", id).eq("empresa_id", auth.empresa_id);
    return { ok: false, status: 500, message: `No se pudo devolver el saldo a la factura (${errUpdFac.message}).` };
  }

  // 3) Auditoría best-effort (no revierte la anulación si falla).
  if (pago.cliente_id) {
    const { error: errHist } = await supabase.from("cliente_historial").insert({
      empresa_id: auth.empresa_id,
      cliente_id: pago.cliente_id,
      tipo: "cobro_anulado",
      accion: `Anulación de cobro en efectivo de la factura ${factura.numero_factura ?? factura.id}`,
      factura_id: factura.id,
      creado_por_auth_user_id: auth.user?.id ?? null,
      creado_por_email: auth.user?.email ?? null,
      detalle: {
        evento: "cobro_efectivo_anulado",
        pago_id: id,
        factura_id: factura.id,
        numero_factura: factura.numero_factura ?? null,
        motivo,
        monto_revertido: montoPago,
        saldo_resultante: nuevoSaldo,
        estado_resultante: nuevoEstado,
        at_iso: new Date().toISOString(),
      },
    });
    if (errHist) console.error("[anularPagoEfectivo] cliente_historial:", errHist.message);
  }

  return { ok: true, ya_anulado: false, factura_id: factura.id, nuevo_saldo: nuevoSaldo, nuevo_estado: nuevoEstado };
}
