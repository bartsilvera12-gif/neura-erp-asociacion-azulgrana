import "server-only";

/**
 * Re-precificación ACOTADA de cuotas de aporte IMPAGAS: pasa el monto de las
 * cuotas que todavía se deben de `precioViejo` (25.000) a `precioNuevo` (30.000).
 *
 * Solo toca facturas que:
 *   - tienen monto == precioViejo,
 *   - están TOTALMENTE impagas (saldo == monto; no hay pago parcial aplicado),
 *   - están Pendiente o Vencido (no Pagado / Anulado / Corregida NC),
 *   - son cuota de aporte (tipo 'suscripcion' o 'credito').
 * Las PAGADAS no se tocan (p. ej. promos ya abonadas). Cualquier caso que no
 * encaje (pago parcial, otro tipo) se omite y se reporta como anomalía.
 *
 * Ajusta el monto y el saldo de la factura, y escala los `factura_items` por el
 * mismo factor (precioNuevo/precioViejo) para preservar el desglose de IVA.
 * Audita en cliente_historial. `dryRun: true` devuelve el plan sin tocar nada.
 */

export type ReprecificarAuth = {
  empresa_id: string;
  user?: { id?: string | null; email?: string | null } | null;
};

type FacturaRow = {
  id: string;
  numero_factura: string | null;
  cliente_id: string | null;
  monto: number | string | null;
  saldo: number | string | null;
  estado: string | null;
  tipo: string | null;
  fecha?: string | null;
};

type ItemRow = {
  id: string;
  factura_id: string;
  subtotal: number | string | null;
  iva: number | string | null;
  total: number | string | null;
  precio_unitario: number | string | null;
  cantidad: number | string | null;
};

export type ReprecificarResult = {
  dry_run: boolean;
  desde: string | null;
  precio_viejo: number;
  precio_nuevo: number;
  candidatas: number;
  a_cambiar: number;
  cambiadas: number;
  items_actualizados: number;
  anomalias: Array<{ numero_factura: string; detalle: string }>;
  errores: Array<{ numero_factura: string; error: string }>;
  plan: Array<{ numero_factura: string; cliente_id: string; monto_viejo: number; saldo_nuevo: number }>;
};

const TIPOS_APORTE = new Set(["suscripcion", "credito"]);
const ESTADOS_IMPAGA = new Set(["Pendiente", "Vencido"]);

export async function reprecificarCuotasImpagas(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  auth: ReprecificarAuth,
  opts: { dryRun: boolean; precioViejo?: number; precioNuevo?: number; desdePeriodo?: string }
): Promise<ReprecificarResult> {
  const precioViejo = Number.isFinite(opts.precioViejo) ? Number(opts.precioViejo) : 25000;
  const precioNuevo = Number.isFinite(opts.precioNuevo) ? Number(opts.precioNuevo) : 30000;
  const factor = precioNuevo / precioViejo;
  // Corte opcional: solo cuotas con fecha de emisión >= `${desdePeriodo}-01` (YYYY-MM).
  const desdeFecha = /^\d{4}-\d{2}$/.test(opts.desdePeriodo ?? "") ? `${opts.desdePeriodo}-01` : null;

  const res: ReprecificarResult = {
    dry_run: opts.dryRun,
    desde: desdeFecha,
    precio_viejo: precioViejo,
    precio_nuevo: precioNuevo,
    candidatas: 0,
    a_cambiar: 0,
    cambiadas: 0,
    items_actualizados: 0,
    anomalias: [],
    errores: [],
    plan: [],
  };

  if (!(precioViejo > 0) || !(precioNuevo > 0) || precioNuevo === precioViejo) {
    throw new Error("precios inválidos (precioViejo/precioNuevo deben ser > 0 y distintos).");
  }

  // 1) Facturas con monto == precioViejo y saldo > 0 (impagas o parciales).
  //    Con corte opcional por fecha de emisión (>= desdeFecha).
  let fq = supabase
    .from("facturas")
    .select("id, numero_factura, cliente_id, monto, saldo, estado, tipo, fecha")
    .eq("empresa_id", auth.empresa_id)
    .eq("monto", precioViejo)
    .gt("saldo", 0);
  if (desdeFecha) fq = fq.gte("fecha", desdeFecha);
  const { data: facData, error: errF } = await fq;
  if (errF) throw new Error(`No se pudieron leer facturas: ${errF.message}`);
  const cand = (facData ?? []) as FacturaRow[];
  res.candidatas = cand.length;

  const objetivo: FacturaRow[] = [];
  for (const f of cand) {
    const estado = String(f.estado ?? "");
    const tipo = String(f.tipo ?? "");
    const monto = Number(f.monto);
    const saldo = Number(f.saldo);
    if (!ESTADOS_IMPAGA.has(estado)) {
      res.anomalias.push({ numero_factura: String(f.numero_factura), detalle: `estado ${estado} (se omite)` });
      continue;
    }
    if (!TIPOS_APORTE.has(tipo)) {
      res.anomalias.push({ numero_factura: String(f.numero_factura), detalle: `tipo ${tipo} (no es aporte, se omite)` });
      continue;
    }
    if (saldo !== monto) {
      res.anomalias.push({ numero_factura: String(f.numero_factura), detalle: `pago parcial (saldo ${saldo} != monto ${monto}, se omite)` });
      continue;
    }
    objetivo.push(f);
  }
  res.a_cambiar = objetivo.length;
  res.plan = objetivo.map((f) => ({
    numero_factura: String(f.numero_factura),
    cliente_id: String(f.cliente_id ?? ""),
    monto_viejo: Number(f.monto),
    saldo_nuevo: precioNuevo,
  }));

  if (opts.dryRun) return res;

  // 2) Traer items de las facturas objetivo (lotes de 50).
  const ids = objetivo.map((f) => f.id);
  const itemsPorFac = new Map<string, ItemRow[]>();
  for (let i = 0; i < ids.length; i += 50) {
    const slice = ids.slice(i, i + 50);
    const { data: it, error: errIt } = await supabase
      .from("factura_items")
      .select("id, factura_id, subtotal, iva, total, precio_unitario, cantidad")
      .in("factura_id", slice);
    if (errIt) throw new Error(`No se pudieron leer factura_items: ${errIt.message}`);
    for (const r of (it ?? []) as ItemRow[]) {
      const k = String(r.factura_id);
      if (!itemsPorFac.has(k)) itemsPorFac.set(k, []);
      itemsPorFac.get(k)!.push(r);
    }
  }

  // 3) Aplicar por factura: header + items (escalados) + auditoría.
  const now = new Date().toISOString();
  for (const f of objetivo) {
    try {
      const { data: upd, error: errUpd } = await supabase
        .from("facturas")
        .update({ monto: precioNuevo, saldo: precioNuevo, updated_at: now })
        .eq("id", f.id)
        .eq("empresa_id", auth.empresa_id)
        .eq("monto", precioViejo) // guarda: solo si sigue en el precio viejo (idempotente)
        .select("id")
        .maybeSingle();
      if (errUpd) {
        res.errores.push({ numero_factura: String(f.numero_factura), error: errUpd.message });
        continue;
      }
      if (!upd) continue; // ya cambiada (carrera): idempotente

      // Items: escalar por el factor, manteniendo total = round(viejo*factor) y iva = total - subtotal.
      for (const it of itemsPorFac.get(String(f.id)) ?? []) {
        const total = Math.round((Number(it.total) || 0) * factor);
        const subtotal = Math.round((Number(it.subtotal) || 0) * factor);
        const iva = total - subtotal;
        const precio_unitario = Math.round((Number(it.precio_unitario) || 0) * factor);
        const { error: errItUpd } = await supabase
          .from("factura_items")
          .update({ total, subtotal, iva, precio_unitario })
          .eq("id", it.id);
        if (errItUpd) {
          res.errores.push({ numero_factura: String(f.numero_factura), error: `item: ${errItUpd.message}` });
        } else {
          res.items_actualizados++;
        }
      }

      res.cambiadas++;
      if (f.cliente_id) {
        const { error: errHist } = await supabase.from("cliente_historial").insert({
          empresa_id: auth.empresa_id,
          cliente_id: f.cliente_id,
          tipo: "factura_monto_actualizado",
          accion: `Cuota impaga ${f.numero_factura}: aporte ${precioViejo} → ${precioNuevo}`,
          factura_id: f.id,
          creado_por_auth_user_id: auth.user?.id ?? null,
          creado_por_email: auth.user?.email ?? null,
          detalle: {
            evento: "cuota_impaga_reprecificada",
            factura_id: f.id,
            numero_factura: f.numero_factura,
            monto_viejo: precioViejo,
            monto_nuevo: precioNuevo,
            at_iso: now,
          },
        });
        if (errHist) console.error("[reprecificarCuotasImpagas] cliente_historial:", errHist.message);
      }
    } catch (e) {
      res.errores.push({ numero_factura: String(f.numero_factura), error: e instanceof Error ? e.message : String(e) });
    }
  }

  return res;
}
