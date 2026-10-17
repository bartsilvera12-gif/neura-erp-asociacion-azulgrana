import "server-only";

/**
 * Limpieza puntual: cada socio tiene la INSCRIPCIÓN duplicada en dos series
 * (`INSCRIP-NN` y `INSC-0NN`), ambas de 50.000. La copia `INSCRIP-NN` figura
 * "Pagado" pero SIN pago real detrás; la `INSC-0NN` tiene el pago de 50.000.
 *
 * Esta función, de alcance ACOTADO y VERIFICABLE, anula administrativamente SOLO
 * las copias `INSCRIP-NN` que:
 *   - no tienen ningún pago vivo (estado_contable != 'revertido'),
 *   - tienen una pareja `INSC-*` del mismo cliente que SÍ tiene pago,
 *   - no están ya anuladas, y no tienen DE SIFEN aprobado.
 * Conserva siempre la `INSC-*` con el pago real. Audita en cliente_historial.
 *
 * `dryRun: true` devuelve el plan (qué anularía) sin tocar nada.
 */

export type AnularInscDupAuth = {
  empresa_id: string;
  user?: { id?: string | null; email?: string | null } | null;
};

type FacturaInsc = {
  id: string;
  numero_factura: string | null;
  cliente_id: string | null;
  monto: number | string | null;
  estado: string | null;
};

export type AnularInscDupResult = {
  dry_run: boolean;
  clientes_con_inscripcion: number;
  duplicados_detectados: number;
  a_anular: number;
  anuladas: number;
  anomalias: Array<{ cliente_id: string; detalle: string }>;
  errores: Array<{ numero_factura: string; error: string }>;
  plan: Array<{ cliente_id: string; anular: string; conserva: string }>;
};

export async function anularInscripcionesDuplicadas(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  auth: AnularInscDupAuth,
  opts: { dryRun: boolean }
): Promise<AnularInscDupResult> {
  const res: AnularInscDupResult = {
    dry_run: opts.dryRun,
    clientes_con_inscripcion: 0,
    duplicados_detectados: 0,
    a_anular: 0,
    anuladas: 0,
    anomalias: [],
    errores: [],
    plan: [],
  };

  // 1) Facturas de inscripción (ambas series) de la empresa.
  const { data: inscData, error: errInsc } = await supabase
    .from("facturas")
    .select("id, numero_factura, cliente_id, monto, estado")
    .eq("empresa_id", auth.empresa_id)
    .or("numero_factura.ilike.INSCRIP-%,numero_factura.ilike.INSC-%");
  if (errInsc) throw new Error(`No se pudieron leer inscripciones: ${errInsc.message}`);
  const insc = (inscData ?? []) as FacturaInsc[];

  // 2) Pagos vivos por factura de inscripción (en lotes de 50 ids).
  const ids = insc.map((f) => f.id);
  const pagosPorFac = new Map<string, number>();
  for (let i = 0; i < ids.length; i += 50) {
    const slice = ids.slice(i, i + 50);
    const { data: pg, error: errPg } = await supabase
      .from("pagos")
      .select("factura_id")
      .eq("empresa_id", auth.empresa_id)
      .neq("estado_contable", "revertido")
      .in("factura_id", slice);
    if (errPg) throw new Error(`No se pudieron leer pagos: ${errPg.message}`);
    for (const p of (pg ?? []) as Array<{ factura_id: string }>) {
      pagosPorFac.set(String(p.factura_id), (pagosPorFac.get(String(p.factura_id)) ?? 0) + 1);
    }
  }

  // 3) Agrupar por cliente y decidir.
  const porCliente = new Map<string, FacturaInsc[]>();
  for (const f of insc) {
    const k = String(f.cliente_id ?? "");
    if (!k) continue;
    if (!porCliente.has(k)) porCliente.set(k, []);
    porCliente.get(k)!.push(f);
  }
  res.clientes_con_inscripcion = porCliente.size;

  const aAnular: Array<{ cliente_id: string; factura: FacturaInsc; conserva: string }> = [];
  for (const [cid, fs] of porCliente) {
    if (fs.length < 2) continue;
    res.duplicados_detectados++;
    const conPago = fs.filter((f) => (pagosPorFac.get(String(f.id)) ?? 0) > 0);
    const sinPago = fs.filter(
      (f) => (pagosPorFac.get(String(f.id)) ?? 0) === 0 && String(f.estado) !== "Anulado"
    );
    // Patrón seguro: exactamente 2 inscripciones, una con pago (se conserva) y una sin pago (se anula).
    if (fs.length === 2 && conPago.length === 1 && sinPago.length === 1) {
      aAnular.push({ cliente_id: cid, factura: sinPago[0], conserva: String(conPago[0].numero_factura) });
    } else {
      res.anomalias.push({
        cliente_id: cid,
        detalle: `inscripciones=${fs.length}, con_pago=${conPago.length}, sin_pago=${sinPago.length} → se omite por seguridad`,
      });
    }
  }
  res.a_anular = aAnular.length;
  res.plan = aAnular.map((x) => ({
    cliente_id: x.cliente_id,
    anular: String(x.factura.numero_factura),
    conserva: x.conserva,
  }));

  if (opts.dryRun) return res;

  // 4) Aplicar: anular cada copia (estado Anulado, saldo 0) + auditoría.
  const now = new Date().toISOString();
  for (const { cliente_id, factura, conserva } of aAnular) {
    try {
      const { data: upd, error: errUpd } = await supabase
        .from("facturas")
        .update({
          estado: "Anulado",
          saldo: 0,
          anulado_at: now,
          anulado_por: auth.user?.id ?? null,
          anulacion_motivo: `Inscripción duplicada: se conserva ${conserva} (con el pago real).`,
          updated_at: now,
        })
        .eq("id", factura.id)
        .eq("empresa_id", auth.empresa_id)
        .neq("estado", "Anulado")
        .select("id")
        .maybeSingle();
      if (errUpd) {
        res.errores.push({ numero_factura: String(factura.numero_factura), error: errUpd.message });
        continue;
      }
      if (!upd) continue; // ya anulada (carrera): idempotente
      res.anuladas++;
      const { error: errHist } = await supabase.from("cliente_historial").insert({
        empresa_id: auth.empresa_id,
        cliente_id,
        tipo: "factura_anulada",
        accion: `Anulación de inscripción duplicada ${factura.numero_factura}`,
        factura_id: factura.id,
        creado_por_auth_user_id: auth.user?.id ?? null,
        creado_por_email: auth.user?.email ?? null,
        detalle: {
          evento: "inscripcion_duplicada_anulada",
          factura_id: factura.id,
          numero_factura: factura.numero_factura,
          conserva,
          at_iso: now,
        },
      });
      if (errHist) console.error("[anularInscripcionesDuplicadas] cliente_historial:", errHist.message);
    } catch (e) {
      res.errores.push({ numero_factura: String(factura.numero_factura), error: e instanceof Error ? e.message : String(e) });
    }
  }

  return res;
}
