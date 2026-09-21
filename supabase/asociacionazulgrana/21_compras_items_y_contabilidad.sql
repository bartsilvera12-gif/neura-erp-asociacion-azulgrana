-- =============================================================================
-- 21 · Tablas faltantes: items de Compras/Gastos + Motor Contable
-- =============================================================================
-- Errores reportados por QA:
--   • /reportes/libro-compras       → relation "compra_items" does not exist
--   • /reportes/libro-diario        → relation "asientos_contables" does not exist
--   • /reportes/libro-mayor         → relation "asientos_contables" does not exist
--   • /reportes/cuentas-por-pagar   → probablemente compra_items o proveedores
--
-- Estas tablas fueron creadas por las migraciones 20260714 (plan_cuentas),
-- 20260715 (gastos_servicios) y 20260716 (motor contable + items) SOLO en
-- el schema `neura`. Al clonar tenant desde instemaq nos quedamos sin ellas.
--
-- Crea todas en asociacionazulgranaerp, con RLS + grants. Sin las FKs a
-- productos/recepcion_items (esas tablas pueden no estar), y sin datos
-- sembrados (queda en 0 filas).
--
-- Idempotente. No pisa datos.
-- =============================================================================

-- ────────────────────────────── 1) plan_cuentas ──────────────────────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.plan_cuentas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id      uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  cuenta          text NOT NULL,
  denominacion    text NOT NULL,
  nivel           integer NOT NULL,
  naturaleza      text NOT NULL CHECK (naturaleza IN ('D','A')),
  asentable       boolean NOT NULL DEFAULT false,
  centro_costo    boolean NOT NULL DEFAULT false,
  moneda          text,
  tipo_cambio     text,
  cuenta_sset     text,
  cuenta_padre_id uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  activo          boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT plan_cuentas_cuenta_empresa_uk UNIQUE (empresa_id, cuenta),
  CONSTRAINT plan_cuentas_no_self_parent CHECK (cuenta_padre_id IS NULL OR cuenta_padre_id <> id)
);
CREATE INDEX IF NOT EXISTS ix_plan_cuentas_empresa ON asociacionazulgranaerp.plan_cuentas (empresa_id);
CREATE INDEX IF NOT EXISTS ix_plan_cuentas_padre   ON asociacionazulgranaerp.plan_cuentas (empresa_id, cuenta_padre_id);
CREATE INDEX IF NOT EXISTS ix_plan_cuentas_nivel   ON asociacionazulgranaerp.plan_cuentas (empresa_id, nivel);

-- ────────────────────────────── 2) asientos_contables ────────────────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.asientos_contables (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id            uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  numero_asiento        text NOT NULL,
  fecha_contable        date NOT NULL,
  glosa                 text,
  estado                text NOT NULL DEFAULT 'contabilizado' CHECK (estado IN ('contabilizado','revertido')),
  origen_tipo           text NOT NULL,
  origen_id             uuid,
  evento_origen         text NOT NULL,
  moneda                text NOT NULL DEFAULT 'PYG',
  tipo_cambio           numeric NOT NULL DEFAULT 1,
  asiento_original_id   uuid REFERENCES asociacionazulgranaerp.asientos_contables(id) ON DELETE SET NULL,
  asiento_reversion_id  uuid REFERENCES asociacionazulgranaerp.asientos_contables(id) ON DELETE SET NULL,
  created_by            uuid,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asientos_numero_uk UNIQUE (empresa_id, numero_asiento)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_asientos_origen
  ON asociacionazulgranaerp.asientos_contables (empresa_id, origen_tipo, origen_id, evento_origen)
  WHERE origen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_asientos_fecha ON asociacionazulgranaerp.asientos_contables (empresa_id, fecha_contable);
CREATE INDEX IF NOT EXISTS ix_asientos_doc   ON asociacionazulgranaerp.asientos_contables (empresa_id, origen_tipo, origen_id);

-- ────────────────────────────── 3) asientos_contables_detalles ───────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.asientos_contables_detalles (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id         uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  asiento_id         uuid NOT NULL REFERENCES asociacionazulgranaerp.asientos_contables(id) ON DELETE CASCADE,
  cuenta_contable_id uuid NOT NULL REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE RESTRICT,
  proveedor_id       uuid,
  descripcion        text,
  debe               numeric NOT NULL DEFAULT 0 CHECK (debe >= 0),
  haber              numeric NOT NULL DEFAULT 0 CHECK (haber >= 0),
  documento_tipo     text,
  documento_id       uuid,
  created_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT det_debe_xor_haber CHECK ((debe > 0 AND haber = 0) OR (haber > 0 AND debe = 0))
);
CREATE INDEX IF NOT EXISTS ix_asdet_asiento ON asociacionazulgranaerp.asientos_contables_detalles (asiento_id);
CREATE INDEX IF NOT EXISTS ix_asdet_cuenta  ON asociacionazulgranaerp.asientos_contables_detalles (empresa_id, cuenta_contable_id);
CREATE INDEX IF NOT EXISTS ix_asdet_doc     ON asociacionazulgranaerp.asientos_contables_detalles (empresa_id, documento_tipo, documento_id);

-- ────────────────────────────── 4) configuracion_contable ────────────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.configuracion_contable (
  empresa_id                uuid PRIMARY KEY REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  cuenta_iva_credito_5_id   uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  cuenta_iva_credito_10_id  uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  cuenta_proveedores_id     uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  cuenta_caja_id            uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  cuenta_banco_id           uuid REFERENCES asociacionazulgranaerp.plan_cuentas(id) ON DELETE SET NULL,
  updated_by                uuid,
  updated_at                timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────── 5) compra_items ──────────────────────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.compra_items (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id               uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  compra_id                uuid NOT NULL REFERENCES asociacionazulgranaerp.compras(id) ON DELETE CASCADE,
  producto_id              uuid,
  producto_nombre          text,
  descripcion              text,
  cantidad                 numeric NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  costo_unitario           numeric NOT NULL DEFAULT 0 CHECK (costo_unitario >= 0),
  iva_tipo                 text NOT NULL DEFAULT '10' CHECK (iva_tipo IN ('exenta','5','10')),
  subtotal                 numeric NOT NULL DEFAULT 0,
  monto_iva                numeric NOT NULL DEFAULT 0,
  total_linea              numeric NOT NULL DEFAULT 0,
  cuenta_contable_id       uuid,
  recepcion_item_id        uuid,
  afecta_inventario        boolean NOT NULL DEFAULT false,
  costo_unitario_ordenado  numeric,
  costo_unitario_recibido  numeric,
  orden_linea              integer NOT NULL DEFAULT 1,
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ci_compra  ON asociacionazulgranaerp.compra_items (compra_id);
CREATE INDEX IF NOT EXISTS ix_ci_empresa ON asociacionazulgranaerp.compra_items (empresa_id);

-- ────────────────────────────── 6) gasto_items ───────────────────────────────
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.gasto_items (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id         uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  gasto_id           uuid NOT NULL REFERENCES asociacionazulgranaerp.gastos(id) ON DELETE CASCADE,
  descripcion        text NOT NULL,
  cuenta_contable_id uuid,
  subtotal           numeric NOT NULL DEFAULT 0,
  iva_tipo           text NOT NULL DEFAULT 'exenta' CHECK (iva_tipo IN ('exenta','5','10')),
  monto_iva          numeric NOT NULL DEFAULT 0,
  total_linea        numeric NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_gi_gasto   ON asociacionazulgranaerp.gasto_items (gasto_id);
CREATE INDEX IF NOT EXISTS ix_gi_empresa ON asociacionazulgranaerp.gasto_items (empresa_id);

-- ────────────────────────────── 7) RLS + grants a todas las nuevas ───────────
DO $rls$ DECLARE t text; act text; BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'plan_cuentas',
    'asientos_contables',
    'asientos_contables_detalles',
    'configuracion_contable',
    'compra_items',
    'gasto_items'
  ]) LOOP
    EXECUTE format('ALTER TABLE asociacionazulgranaerp.%I ENABLE ROW LEVEL SECURITY', t);
    FOR act IN SELECT unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE']) LOOP
      IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'asociacionazulgranaerp'
          AND tablename  = t
          AND policyname = t || '_' || lower(act)
      ) THEN
        IF act = 'INSERT' THEN
          EXECUTE format(
            'CREATE POLICY %I ON asociacionazulgranaerp.%I FOR INSERT WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))',
            t || '_' || lower(act), t);
        ELSIF act = 'UPDATE' THEN
          EXECUTE format(
            'CREATE POLICY %I ON asociacionazulgranaerp.%I FOR UPDATE USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id)) WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))',
            t || '_' || lower(act), t);
        ELSE
          EXECUTE format(
            'CREATE POLICY %I ON asociacionazulgranaerp.%I FOR %s USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))',
            t || '_' || lower(act), t, act);
        END IF;
      END IF;
    END LOOP;
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.%I TO authenticated', t);
    EXECUTE format('GRANT ALL ON asociacionazulgranaerp.%I TO postgres, service_role', t);
  END LOOP;
END $rls$;

NOTIFY pgrst, 'reload schema';

-- Verificacion: todas las tablas creadas, cero filas
SELECT tabla, count FROM (
  SELECT 'plan_cuentas'                AS tabla, count(*) FROM asociacionazulgranaerp.plan_cuentas                UNION ALL
  SELECT 'asientos_contables',                    count(*) FROM asociacionazulgranaerp.asientos_contables         UNION ALL
  SELECT 'asientos_contables_detalles',           count(*) FROM asociacionazulgranaerp.asientos_contables_detalles UNION ALL
  SELECT 'configuracion_contable',                count(*) FROM asociacionazulgranaerp.configuracion_contable     UNION ALL
  SELECT 'compra_items',                          count(*) FROM asociacionazulgranaerp.compra_items               UNION ALL
  SELECT 'gasto_items',                           count(*) FROM asociacionazulgranaerp.gasto_items
) t;
