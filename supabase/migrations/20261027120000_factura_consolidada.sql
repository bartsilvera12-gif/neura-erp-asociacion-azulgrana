-- =============================================================================
-- Factura consolidada: una sola factura electrónica (DE) para varias cuotas
-- cobradas juntas (una línea por mes).
--
-- Agrega `consolidada_en_factura_id` a `facturas` en TODOS los schemas operativos
-- (loop sobre cualquier schema con tabla `facturas`, igual patrón que
-- 20261016120000_...). Marca una cuota "miembro" que fue absorbida/consolidada en
-- la factura "portadora" (carrier) cuyo id guarda esta columna. La miembro queda
-- Anulada (motivo "Consolidada en …"), sin DE propio, para no duplicar montos en
-- reportería (libro de ventas, cobranzas, dashboards ya excluyen 'Anulado').
--
-- Solo agrega columna (ADD COLUMN IF NOT EXISTS). No toca datos, pagos ni SIFEN.
-- =============================================================================

DO $migration$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT n.nspname AS sch
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'facturas'
      AND c.relkind = 'r'
      AND n.nspname NOT LIKE 'pg_%'
      AND n.nspname NOT IN ('information_schema')
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.facturas ADD COLUMN IF NOT EXISTS consolidada_en_factura_id uuid',
      r.sch
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS idx_facturas_consolidada_en ON %I.facturas (consolidada_en_factura_id) WHERE consolidada_en_factura_id IS NOT NULL',
      r.sch
    );

    -- Función atómica de consolidación: la cuota más vieja queda de portadora con
    -- una línea por mes; las demás se anulan marcadas con consolidada_en_factura_id.
    -- Mensajes de error sin '%' a propósito (evita escapes en format()).
    EXECUTE format($fmt$
      create or replace function %I.consolidar_cuotas_en_factura(
        p_empresa_id uuid, p_factura_ids uuid[]
      ) returns uuid
      language plpgsql
      set search_path = %I, pg_temp
      as $body$
      declare
        v_carrier uuid; v_carrier_num text; v_total numeric;
        v_n int; v_distinct_cli int; v_bad int; v_pagado numeric;
      begin
        select count(*), count(distinct cliente_id) into v_n, v_distinct_cli
          from facturas where id = any(p_factura_ids) and empresa_id = p_empresa_id;
        if v_n < 2 then raise exception 'Se requieren al menos 2 facturas para consolidar.'; end if;
        if v_distinct_cli <> 1 then raise exception 'Todas las facturas deben ser del mismo cliente.'; end if;

        select count(*) into v_bad from facturas
          where id = any(p_factura_ids) and empresa_id=p_empresa_id
            and (coalesce(estado,'')='Anulado' or anulado_at is not null or consolidada_en_factura_id is not null);
        if v_bad > 0 then raise exception 'Hay facturas anuladas o ya consolidadas en la seleccion.'; end if;

        select count(*) into v_bad
          from factura_electronica fe
          where fe.factura_id = any(p_factura_ids) and fe.empresa_id=p_empresa_id
            and fe.estado_sifen in ('aprobado','enviado','en_proceso','cancelado');
        if v_bad > 0 then raise exception 'Hay facturas con factura electronica ya emitida; no se pueden consolidar.'; end if;

        select id, numero_factura into v_carrier, v_carrier_num
          from facturas where id = any(p_factura_ids) and empresa_id=p_empresa_id
          order by fecha asc, numero_factura asc limit 1;

        update factura_items set factura_id = v_carrier
          where empresa_id=p_empresa_id and factura_id = any(p_factura_ids) and factura_id <> v_carrier;

        update pagos set factura_id = v_carrier, numero_factura = v_carrier_num
          where empresa_id=p_empresa_id and factura_id = any(p_factura_ids) and factura_id <> v_carrier;

        select coalesce(sum(total),0) into v_total
          from factura_items where empresa_id=p_empresa_id and factura_id=v_carrier;
        select coalesce(sum(monto),0) into v_pagado
          from pagos where empresa_id=p_empresa_id and factura_id=v_carrier
            and coalesce(estado_contable,'')<>'revertido';

        update facturas
          set monto = v_total, saldo = greatest(0, v_total - v_pagado),
              estado = case when v_pagado >= v_total then 'Pagado' else estado end,
              updated_at = now()
          where id=v_carrier and empresa_id=p_empresa_id;

        update facturas
          set estado='Anulado', saldo=0, anulado_at=now(),
              anulacion_motivo='Consolidada en '||coalesce(v_carrier_num,'factura'),
              consolidada_en_factura_id=v_carrier, updated_at=now()
          where id = any(p_factura_ids) and id<>v_carrier and empresa_id=p_empresa_id;

        return v_carrier;
      end;
      $body$;
    $fmt$, r.sch, r.sch);
  END LOOP;
END
$migration$;
