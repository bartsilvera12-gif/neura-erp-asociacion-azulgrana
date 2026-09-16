-- =============================================================================
-- 15 · Completar columnas faltantes en tablas de negocio (Asociacion Azulgrana)
-- =============================================================================
-- El schema origen `instemaq` no tenia todas las columnas que el codigo espera:
-- muchas migraciones se aplicaron sobre `neura.*` o `public.*` y nunca sobre
-- `instemaq.*`. Al clonar, esas columnas nunca existieron en
-- asociacionazulgranaerp.
--
-- Este script hace catch-up de todas ellas con IF NOT EXISTS. Idempotente.
-- No pisa datos ya cargados por 10, 11, 12 y 13.
--
-- Cubre: suscripciones, planes, facturas, factura_electronica*,
-- empresa_sifen_config, cobranza_promesas, cliente_perfil_tributario,
-- nota_credito_electronica, y crea tablas que probablemente falten.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SUSCRIPCIONES
-- ---------------------------------------------------------------------------
ALTER TABLE asociacionazulgranaerp.suscripciones
  ADD COLUMN IF NOT EXISTS tipo_servicio                text,
  ADD COLUMN IF NOT EXISTS plan_pendiente_id            uuid,
  ADD COLUMN IF NOT EXISTS precio_pendiente             numeric,
  ADD COLUMN IF NOT EXISTS moneda_pendiente             text,
  ADD COLUMN IF NOT EXISTS plan_pendiente_vigente_desde date;

-- ---------------------------------------------------------------------------
-- PLANES
-- ---------------------------------------------------------------------------
ALTER TABLE asociacionazulgranaerp.planes
  ADD COLUMN IF NOT EXISTS tipo_servicio     text,
  ADD COLUMN IF NOT EXISTS es_plan_marketing boolean NOT NULL DEFAULT false;

-- ---------------------------------------------------------------------------
-- FACTURAS
-- ---------------------------------------------------------------------------
ALTER TABLE asociacionazulgranaerp.facturas
  ADD COLUMN IF NOT EXISTS suscripcion_id      uuid,
  ADD COLUMN IF NOT EXISTS vendedor_usuario_id uuid;

-- ---------------------------------------------------------------------------
-- EMPRESA_SIFEN_CONFIG (crear si falta + columnas)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.empresa_sifen_config (
  id                            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id                    uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  activo                        boolean NOT NULL DEFAULT false,
  sifen_plazo_cancelacion_horas integer NOT NULL DEFAULT 48,
  created_at                    timestamptz NOT NULL DEFAULT now(),
  updated_at                    timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE asociacionazulgranaerp.empresa_sifen_config
  ADD COLUMN IF NOT EXISTS activo                        boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sifen_plazo_cancelacion_horas integer NOT NULL DEFAULT 48;

-- ---------------------------------------------------------------------------
-- FACTURA_ELECTRONICA (crear si falta)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.factura_electronica (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id          uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  factura_id          uuid NOT NULL REFERENCES asociacionazulgranaerp.facturas(id) ON DELETE CASCADE,
  estado_sifen        text NOT NULL DEFAULT 'pendiente',
  sifen_aprobado_at   timestamptz,
  sifen_cancelado_at  timestamptz,
  xml_firmado_path    text,
  kuDE_url            text,
  qr_data             text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_factura_electronica_empresa ON asociacionazulgranaerp.factura_electronica(empresa_id);
CREATE INDEX IF NOT EXISTS idx_factura_electronica_factura ON asociacionazulgranaerp.factura_electronica(factura_id);

-- ---------------------------------------------------------------------------
-- COBRANZA_PROMESAS (crear si falta)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.cobranza_promesas (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id       uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  cliente_id       uuid NOT NULL REFERENCES asociacionazulgranaerp.clientes(id) ON DELETE CASCADE,
  fecha_promesa    date NOT NULL,
  estado           text NOT NULL DEFAULT 'pendiente',
  creado_por_email text,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cobranza_promesas_cliente ON asociacionazulgranaerp.cobranza_promesas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cobranza_promesas_empresa ON asociacionazulgranaerp.cobranza_promesas(empresa_id);

-- ---------------------------------------------------------------------------
-- CLIENTE_TIPOS_SERVICIO_CATALOGO (por si la UI aun se refresca)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.cliente_tipos_servicio_catalogo (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id   uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  slug         text NOT NULL,
  nombre       text NOT NULL,
  activo       boolean NOT NULL DEFAULT true,
  orden        integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cliente_tipos_servicio_empresa
  ON asociacionazulgranaerp.cliente_tipos_servicio_catalogo(empresa_id);

-- ---------------------------------------------------------------------------
-- CLIENTE_PERFIL_TRIBUTARIO (por si la ficha de cliente lo consulta)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.cliente_perfil_tributario (
  id                            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id                    uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  cliente_id                    uuid NOT NULL REFERENCES asociacionazulgranaerp.clientes(id) ON DELETE CASCADE,
  perfil_activo                 boolean NOT NULL DEFAULT false,
  dv                            text,
  razon_social_fiscal           text,
  dia_vencimiento_tributario    smallint,
  honorario_mensual             numeric,
  honorario_anual               numeric,
  notas_tributarias             text,
  obligacion_otro_detalle       text,
  clave_tributaria_encriptada   text,
  created_at                    timestamptz NOT NULL DEFAULT now(),
  updated_at                    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cliente_perfil_tributario_empresa
  ON asociacionazulgranaerp.cliente_perfil_tributario(empresa_id);
CREATE INDEX IF NOT EXISTS idx_cliente_perfil_tributario_cliente
  ON asociacionazulgranaerp.cliente_perfil_tributario(cliente_id);

-- ---------------------------------------------------------------------------
-- Habilitar RLS y policies estilo del resto del schema, y grants
-- ---------------------------------------------------------------------------
DO $rls$ DECLARE t text; BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'factura_electronica',
    'cobranza_promesas',
    'empresa_sifen_config',
    'cliente_tipos_servicio_catalogo',
    'cliente_perfil_tributario'
  ]) LOOP
    EXECUTE format('ALTER TABLE asociacionazulgranaerp.%I ENABLE ROW LEVEL SECURITY', t);
    FOR i IN 1..4 LOOP
      DECLARE
        act text := (ARRAY['SELECT','INSERT','UPDATE','DELETE'])[i];
        polname text := format('%s_%s', t, lower((ARRAY['SELECT','INSERT','UPDATE','DELETE'])[i]));
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_policies
          WHERE schemaname = 'asociacionazulgranaerp' AND tablename = t AND policyname = polname
        ) THEN
          IF act = 'INSERT' THEN
            EXECUTE format('CREATE POLICY %I ON asociacionazulgranaerp.%I FOR INSERT WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))', polname, t);
          ELSIF act = 'UPDATE' THEN
            EXECUTE format('CREATE POLICY %I ON asociacionazulgranaerp.%I FOR UPDATE USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id)) WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))', polname, t);
          ELSE
            EXECUTE format('CREATE POLICY %I ON asociacionazulgranaerp.%I FOR %s USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))', polname, t, act);
          END IF;
        END IF;
      END;
    END LOOP;
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.%I TO authenticated', t);
    EXECUTE format('GRANT ALL ON asociacionazulgranaerp.%I TO postgres, service_role', t);
  END LOOP;
END $rls$;

NOTIFY pgrst, 'reload schema';

-- Verificacion
SELECT 'suscripciones' AS tabla, column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='suscripciones' AND column_name IN
  ('tipo_servicio','plan_pendiente_id','precio_pendiente','moneda_pendiente','plan_pendiente_vigente_desde')
UNION ALL
SELECT 'planes', column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='planes' AND column_name IN ('tipo_servicio','es_plan_marketing')
ORDER BY tabla, column_name;
