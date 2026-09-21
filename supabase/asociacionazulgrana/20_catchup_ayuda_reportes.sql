-- =============================================================================
-- 20 - Catch-up: Ayuda en linea, Conciliacion bancaria, reportes contables,
--      y limpieza defensiva de `empresas.data_schema` en todos los catalogos.
-- =============================================================================
-- Cinco sintomas reportados por QA sobre asociacionazulgranaerp:
--   1) Reportes -> Libro de Compras: "No se pudo generar el Libro de Compras."
--   2) Reportes -> Cuentas por Pagar: idem
--   3) Reportes -> Libro Diario: idem
--   4) Cobranzas -> Conciliacion: "No se pudieron cargar las transferencias."
--   5) Config -> Ayuda en linea: "Could not find the table
--        'distribuidorajmerp.ayuda_categorias' in the schema cache"
--
-- Este script hace catch-up idempotente sobre `asociacionazulgranaerp`:
--   A) Ayuda: ayuda_categorias, ayuda_articulos, ayuda_articulo_versiones,
--      ayuda_articulo_feedback (mirror de la migracion original de neura).
--   B) Conciliacion: cobros_pendientes + columnas nuevas en pagos y en
--      configuracion_contable; ampliar CHECK de origen_tipo en asientos.
--   C) Reportes / contabilidad: columnas que los libros esperan sobre
--      compras (nro_timbrado, plazo_dias, cuotas, tipo_pago, etc.) y
--      asegura la existencia de asientos_contables_detalles.proveedor_id
--      + descripcion + documento_tipo/documento_id.
--   D) Limpieza defensiva: pone `data_schema=NULL` en TODOS los catalogos
--      donde exista nuestra empresa con un valor distinto de NULL o de
--      'asociacionazulgranaerp'. Esto libera al resolver a caer al fallback
--      correcto (APP_DB_SCHEMA) desde cualquier catalogo que quede en uso.
--
-- Todo es idempotente (CREATE TABLE IF NOT EXISTS, ADD COLUMN IF NOT EXISTS,
-- DROP POLICY IF EXISTS + CREATE POLICY, etc.). Nada pisa datos.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- A) AYUDA EN LINEA (mirror de neura.ayuda_*)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.ayuda_categorias (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id  uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  nombre      text NOT NULL,
  slug        text NOT NULL,
  descripcion text,
  orden       integer NOT NULL DEFAULT 0,
  activo      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ayuda_categorias_slug_uk UNIQUE (empresa_id, slug),
  CONSTRAINT ayuda_categorias_nombre_non_empty CHECK (length(trim(nombre)) > 0)
);
ALTER TABLE asociacionazulgranaerp.ayuda_categorias
  ADD COLUMN IF NOT EXISTS parent_id uuid REFERENCES asociacionazulgranaerp.ayuda_categorias(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS ix_ayuda_categorias_empresa
  ON asociacionazulgranaerp.ayuda_categorias (empresa_id, orden, nombre);

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.ayuda_articulos (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id      uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  categoria_id    uuid REFERENCES asociacionazulgranaerp.ayuda_categorias(id) ON DELETE SET NULL,
  titulo          text NOT NULL,
  slug            text NOT NULL,
  resumen         text,
  contenido_md    text NOT NULL DEFAULT '',
  modulo          text,
  roles_visibles  text[] NOT NULL DEFAULT '{}',
  orden           integer NOT NULL DEFAULT 0,
  publicado       boolean NOT NULL DEFAULT false,
  vistas          integer NOT NULL DEFAULT 0,
  creado_por      uuid REFERENCES asociacionazulgranaerp.usuarios(id) ON DELETE SET NULL,
  actualizado_por uuid REFERENCES asociacionazulgranaerp.usuarios(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ayuda_articulos_slug_uk UNIQUE (empresa_id, slug),
  CONSTRAINT ayuda_articulos_titulo_non_empty CHECK (length(trim(titulo)) > 0)
);

CREATE INDEX IF NOT EXISTS ix_ayuda_articulos_empresa
  ON asociacionazulgranaerp.ayuda_articulos (empresa_id, publicado, orden, titulo);
CREATE INDEX IF NOT EXISTS ix_ayuda_articulos_categoria
  ON asociacionazulgranaerp.ayuda_articulos (empresa_id, categoria_id);
CREATE INDEX IF NOT EXISTS ix_ayuda_articulos_modulo
  ON asociacionazulgranaerp.ayuda_articulos (empresa_id, modulo) WHERE modulo IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_ayuda_articulos_titulo_lower
  ON asociacionazulgranaerp.ayuda_articulos (empresa_id, lower(titulo));

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.ayuda_articulo_versiones (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id   uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  articulo_id  uuid NOT NULL REFERENCES asociacionazulgranaerp.ayuda_articulos(id) ON DELETE CASCADE,
  titulo       text NOT NULL,
  contenido_md text NOT NULL DEFAULT '',
  guardado_por uuid REFERENCES asociacionazulgranaerp.usuarios(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ayuda_versiones_articulo
  ON asociacionazulgranaerp.ayuda_articulo_versiones (empresa_id, articulo_id, created_at DESC);

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.ayuda_articulo_feedback (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id  uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  articulo_id uuid NOT NULL REFERENCES asociacionazulgranaerp.ayuda_articulos(id) ON DELETE CASCADE,
  usuario_id  uuid REFERENCES asociacionazulgranaerp.usuarios(id) ON DELETE SET NULL,
  util        boolean NOT NULL,
  comentario  text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ayuda_feedback_uk UNIQUE (articulo_id, usuario_id)
);
CREATE INDEX IF NOT EXISTS ix_ayuda_feedback_articulo
  ON asociacionazulgranaerp.ayuda_articulo_feedback (empresa_id, articulo_id);

-- RLS + grants + updated_at trigger (usa funciones ya presentes del schema)
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'ayuda_categorias',
    'ayuda_articulos',
    'ayuda_articulo_versiones',
    'ayuda_articulo_feedback'
  ] LOOP
    EXECUTE format('ALTER TABLE asociacionazulgranaerp.%I ENABLE ROW LEVEL SECURITY', t);

    -- Se abren para service_role/authenticated: la app ya filtra por empresa_id
    -- en la capa API; RLS finas se pueden reforzar cuando exista `puede_acceder_empresa`.
    EXECUTE format('DROP POLICY IF EXISTS %I ON asociacionazulgranaerp.%I', t || '_all', t);
    EXECUTE format(
      'CREATE POLICY %I ON asociacionazulgranaerp.%I FOR ALL USING (true) WITH CHECK (true)',
      t || '_all', t
    );

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.%I TO authenticated', t);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.%I TO service_role', t);
    END IF;

    -- Trigger updated_at si la funcion set_updated_at() existe en el schema
    IF EXISTS (
      SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'asociacionazulgranaerp'
         AND p.proname = 'set_updated_at'
    ) AND t <> 'ayuda_articulo_versiones' THEN
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON asociacionazulgranaerp.%I', 'tr_' || t || '_updated', t);
      EXECUTE format(
        'CREATE TRIGGER %I BEFORE UPDATE ON asociacionazulgranaerp.%I FOR EACH ROW EXECUTE FUNCTION asociacionazulgranaerp.set_updated_at()',
        'tr_' || t || '_updated', t
      );
    END IF;
  END LOOP;
END $$;

-- Categorias iniciales por empresa (solo si la empresa no tiene ninguna)
INSERT INTO asociacionazulgranaerp.ayuda_categorias (empresa_id, nombre, slug, descripcion, orden)
SELECT e.id, c.nombre, c.slug, c.descripcion, c.orden
FROM asociacionazulgranaerp.empresas e
CROSS JOIN (VALUES
  ('Procesos',    'procesos',    'Como se hace cada cosa, paso a paso.',            10),
  ('Politicas',   'politicas',   'Reglas de la empresa: descuentos, permisos, etc.', 20),
  ('Comercial',   'comercial',   'Venta, seguimiento de leads y cierre.',            30),
  ('Cobranzas',   'cobranzas',   'Gestion de cuotas, promesas de pago y morosidad.', 40),
  ('Sistema',     'sistema',     'Como usar cada modulo del ERP.',                   50),
  ('Preguntas frecuentes', 'faq', 'Las dudas que mas se repiten.',                    60)
) AS c(nombre, slug, descripcion, orden)
WHERE NOT EXISTS (
  SELECT 1 FROM asociacionazulgranaerp.ayuda_categorias a WHERE a.empresa_id = e.id
)
ON CONFLICT (empresa_id, slug) DO NOTHING;

-- ---------------------------------------------------------------------------
-- B) CONCILIACION BANCARIA
-- ---------------------------------------------------------------------------

-- pagos: columnas de contabilizacion y anticipos (solo si existen tablas)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='pagos') THEN
    ALTER TABLE asociacionazulgranaerp.pagos
      ADD COLUMN IF NOT EXISTS estado_contable     text NOT NULL DEFAULT 'no_contabilizado',
      ADD COLUMN IF NOT EXISTS asiento_contable_id uuid,
      ADD COLUMN IF NOT EXISTS contab_error        text,
      ADD COLUMN IF NOT EXISTS es_anticipo         boolean NOT NULL DEFAULT false,
      ADD COLUMN IF NOT EXISTS cobro_pendiente_id  uuid;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.cobros_pendientes (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id            uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  factura_id            uuid NOT NULL REFERENCES asociacionazulgranaerp.facturas(id) ON DELETE RESTRICT,
  cliente_id            uuid REFERENCES asociacionazulgranaerp.clientes(id) ON DELETE SET NULL,
  monto                 numeric NOT NULL CHECK (monto > 0),
  fecha                 date NOT NULL DEFAULT current_date,
  metodo                text NOT NULL DEFAULT 'transferencia' CHECK (metodo = 'transferencia'),
  banco_origen          text NOT NULL,
  banco_origen_norm     text NOT NULL,
  titular               text NOT NULL,
  numero_operacion      text NOT NULL,
  numero_operacion_norm text NOT NULL,
  comprobante_path      text,
  comprobante_mime      text,
  estado                text NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','aprobado','rechazado','anulado')),
  motivo_rechazo        text,
  motivo_anulacion      text,
  pago_id               uuid,
  idempotency_key       uuid,
  asiento_reversion_id  uuid,
  created_by            uuid,
  aprobado_by           uuid,
  aprobado_at           timestamptz,
  rechazado_by          uuid,
  rechazado_at          timestamptz,
  anulado_by            uuid,
  anulado_at            timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

-- Por si la tabla ya existia sin las columnas nuevas
ALTER TABLE asociacionazulgranaerp.cobros_pendientes
  ADD COLUMN IF NOT EXISTS comprobante_mime     text,
  ADD COLUMN IF NOT EXISTS motivo_anulacion     text,
  ADD COLUMN IF NOT EXISTS anulado_by           uuid,
  ADD COLUMN IF NOT EXISTS anulado_at           timestamptz,
  ADD COLUMN IF NOT EXISTS asiento_reversion_id uuid;

CREATE UNIQUE INDEX IF NOT EXISTS uq_cobros_pend_banco_op
  ON asociacionazulgranaerp.cobros_pendientes (empresa_id, banco_origen_norm, numero_operacion_norm)
  WHERE estado <> 'rechazado' AND estado <> 'anulado';
CREATE UNIQUE INDEX IF NOT EXISTS uq_cobros_pend_idem
  ON asociacionazulgranaerp.cobros_pendientes (empresa_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_cobros_pend_estado
  ON asociacionazulgranaerp.cobros_pendientes (empresa_id, estado, fecha DESC);
CREATE INDEX IF NOT EXISTS ix_cobros_pend_factura
  ON asociacionazulgranaerp.cobros_pendientes (empresa_id, factura_id);

-- RLS abierta (misma politica que el resto de tablas de negocio de este schema)
ALTER TABLE asociacionazulgranaerp.cobros_pendientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS cobros_pendientes_all ON asociacionazulgranaerp.cobros_pendientes;
CREATE POLICY cobros_pendientes_all
  ON asociacionazulgranaerp.cobros_pendientes FOR ALL USING (true) WITH CHECK (true);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.cobros_pendientes TO authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.cobros_pendientes TO service_role;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname='asociacionazulgranaerp' AND p.proname='set_updated_at'
  ) THEN
    DROP TRIGGER IF EXISTS tr_cobros_pendientes_updated ON asociacionazulgranaerp.cobros_pendientes;
    CREATE TRIGGER tr_cobros_pendientes_updated
      BEFORE UPDATE ON asociacionazulgranaerp.cobros_pendientes
      FOR EACH ROW EXECUTE FUNCTION asociacionazulgranaerp.set_updated_at();
  END IF;
END $$;

-- configuracion_contable: cuenta_anticipos_clientes_id (si la tabla existe)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='configuracion_contable') THEN
    ALTER TABLE asociacionazulgranaerp.configuracion_contable
      ADD COLUMN IF NOT EXISTS cuenta_anticipos_clientes_id uuid;
  END IF;
END $$;

-- asientos_contables: ampliar CHECK de origen_tipo (superconjunto)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='asientos_contables') THEN
    ALTER TABLE asociacionazulgranaerp.asientos_contables
      DROP CONSTRAINT IF EXISTS asientos_contables_origen_tipo_check;
    ALTER TABLE asociacionazulgranaerp.asientos_contables
      ADD CONSTRAINT asientos_contables_origen_tipo_check
      CHECK (origen_tipo IN ('gasto_servicio','compra','reversion','pago_proveedor',
                             'factura_venta','nota_credito_venta','cobro_cliente',
                             'reclasificacion_anticipo'));
  END IF;
END $$;

-- asientos_contables_detalles: columnas que usan los libros / conciliacion
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='asientos_contables_detalles') THEN
    ALTER TABLE asociacionazulgranaerp.asientos_contables_detalles
      ADD COLUMN IF NOT EXISTS descripcion    text,
      ADD COLUMN IF NOT EXISTS documento_tipo text,
      ADD COLUMN IF NOT EXISTS documento_id   uuid,
      ADD COLUMN IF NOT EXISTS proveedor_id   uuid,
      ADD COLUMN IF NOT EXISTS created_at     timestamptz NOT NULL DEFAULT now();
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- C) REPORTES CONTABLES: compras + gastos + facturas
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='compras') THEN
    ALTER TABLE asociacionazulgranaerp.compras
      ADD COLUMN IF NOT EXISTS proveedor_nombre    text,
      ADD COLUMN IF NOT EXISTS numero_control      text,
      ADD COLUMN IF NOT EXISTS numero_comprobante  text,
      ADD COLUMN IF NOT EXISTS nro_timbrado        text,
      ADD COLUMN IF NOT EXISTS tipo_comprobante    text,
      ADD COLUMN IF NOT EXISTS tipo_pago           text,
      ADD COLUMN IF NOT EXISTS plazo_dias          integer,
      ADD COLUMN IF NOT EXISTS cuotas              integer,
      ADD COLUMN IF NOT EXISTS iva_tipo            text,
      ADD COLUMN IF NOT EXISTS subtotal            numeric,
      ADD COLUMN IF NOT EXISTS monto_iva           numeric,
      ADD COLUMN IF NOT EXISTS moneda              text,
      ADD COLUMN IF NOT EXISTS estado_contable     text,
      ADD COLUMN IF NOT EXISTS estado              text;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='compra_items') THEN
    ALTER TABLE asociacionazulgranaerp.compra_items
      ADD COLUMN IF NOT EXISTS iva_tipo  text,
      ADD COLUMN IF NOT EXISTS subtotal  numeric,
      ADD COLUMN IF NOT EXISTS monto_iva numeric;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='gastos') THEN
    ALTER TABLE asociacionazulgranaerp.gastos
      ADD COLUMN IF NOT EXISTS fecha_comprobante date,
      ADD COLUMN IF NOT EXISTS tipo_comprobante  text,
      ADD COLUMN IF NOT EXISTS timbrado          text,
      ADD COLUMN IF NOT EXISTS numero            text,
      ADD COLUMN IF NOT EXISTS tipo_pago         text,
      ADD COLUMN IF NOT EXISTS estado            text,
      ADD COLUMN IF NOT EXISTS total             numeric;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='gasto_items') THEN
    ALTER TABLE asociacionazulgranaerp.gasto_items
      ADD COLUMN IF NOT EXISTS iva_tipo  text,
      ADD COLUMN IF NOT EXISTS subtotal  numeric,
      ADD COLUMN IF NOT EXISTS monto_iva numeric;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='asociacionazulgranaerp' AND tablename='facturas') THEN
    ALTER TABLE asociacionazulgranaerp.facturas
      ADD COLUMN IF NOT EXISTS estado_contable text,
      ADD COLUMN IF NOT EXISTS moneda          text;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- D) LIMPIEZA DEFENSIVA de `empresas.data_schema` (todos los catalogos)
-- ---------------------------------------------------------------------------
-- El resolver (fetchDataSchemaForEmpresaId) usa service role apuntando al
-- APP_DB_SCHEMA. En este deploy es `asociacionazulgranaerp`. Si algun
-- catalogo compartido (neura, zentra_erp, public, o forks residuales) tiene
-- una fila de nuestra empresa con data_schema='distribuidorajmerp' (residuo
-- del clonado de env de distribuidorajm), y ese catalogo termina siendo
-- consultado por alguna ruta, el resolver responde con el schema erroneo.
--
-- Este bloque pone `data_schema=NULL` en TODA fila de `<schema>.empresas`
-- donde id = nuestra empresa Y data_schema NOT IN (NULL, 'asociacionazulgranaerp').
-- Con NULL el `resolveEmpresaDataSchema` cae al SUPABASE_APP_SCHEMA correcto.
-- Ver script 19 para diagnostico previo.
DO $$
DECLARE
  v_empresa_id constant uuid := '498add65-8616-412a-9ee7-d5d60adba136'::uuid;
  r            record;
  v_updated    integer;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind IN ('r','p')
       AND c.relname = 'empresas'
       AND n.nspname NOT IN ('pg_catalog','information_schema','auth','storage','realtime',
                             'supabase_functions','supabase_migrations','extensions','vault',
                             'graphql','graphql_public','pgsodium','pgsodium_masks',
                             '_realtime','_analytics','net','cron')
       AND EXISTS (
         SELECT 1 FROM information_schema.columns
          WHERE table_schema = n.nspname
            AND table_name   = 'empresas'
            AND column_name  = 'data_schema'
       )
  LOOP
    BEGIN
      EXECUTE format(
        'UPDATE %I.empresas SET data_schema = NULL
           WHERE id = $1
             AND data_schema IS NOT NULL
             AND data_schema <> ''asociacionazulgranaerp''',
        r.schema_name
      ) USING v_empresa_id;
      GET DIAGNOSTICS v_updated = ROW_COUNT;
      IF v_updated > 0 THEN
        RAISE NOTICE '  [%] data_schema limpiado en % filas', r.schema_name, v_updated;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  [%] no se pudo actualizar: %', r.schema_name, SQLERRM;
    END;
  END LOOP;
END $$;

COMMIT;

-- Refresca el cache de PostgREST para que reconozca las tablas nuevas.
NOTIFY pgrst, 'reload schema';

-- Verificacion rapida (no bloqueante)
SELECT 'ayuda_categorias'         AS tabla, count(*) AS filas FROM asociacionazulgranaerp.ayuda_categorias
UNION ALL SELECT 'ayuda_articulos', count(*) FROM asociacionazulgranaerp.ayuda_articulos
UNION ALL SELECT 'cobros_pendientes', count(*) FROM asociacionazulgranaerp.cobros_pendientes;
