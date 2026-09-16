-- =============================================================================
-- 16 · Catch-up de columnas en usuarios y otras tablas (Asociacion Azulgrana)
-- =============================================================================
-- Nuevas columnas de sistemas-propio que no existen en el schema clonado
-- desde instemaq. Idempotente. No pisa datos.
-- =============================================================================

-- USUARIOS: flags de perfil (QA, PM, técnico, notificaciones), datos personales
ALTER TABLE asociacionazulgranaerp.usuarios
  ADD COLUMN IF NOT EXISTS es_qa                 boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS es_project_manager    boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS es_tecnico            boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notificar_entregas    boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS area                  text,
  ADD COLUMN IF NOT EXISTS avatar_path           text,
  ADD COLUMN IF NOT EXISTS fecha_nacimiento      date,
  ADD COLUMN IF NOT EXISTS nombre_chat           text,
  ADD COLUMN IF NOT EXISTS telefono              text,
  ADD COLUMN IF NOT EXISTS estado                text DEFAULT 'activo';

-- FACTURAS: comisionable y periodo_facturado (features de reporting)
ALTER TABLE asociacionazulgranaerp.facturas
  ADD COLUMN IF NOT EXISTS comisionable       boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS periodo_facturado  text;

-- PLANES: plantilla_operativa (metadata del plan)
ALTER TABLE asociacionazulgranaerp.planes
  ADD COLUMN IF NOT EXISTS plantilla_operativa jsonb;

-- PAGOS: campos de vinculo directo con cliente/suscripcion (evita joins en cobranza)
ALTER TABLE asociacionazulgranaerp.pagos
  ADD COLUMN IF NOT EXISTS cliente_id       uuid REFERENCES asociacionazulgranaerp.clientes(id),
  ADD COLUMN IF NOT EXISTS suscripcion_id   uuid REFERENCES asociacionazulgranaerp.suscripciones(id),
  ADD COLUMN IF NOT EXISTS numero_factura   text;

-- Indices utiles
CREATE INDEX IF NOT EXISTS ix_usuarios_es_qa              ON asociacionazulgranaerp.usuarios(empresa_id) WHERE es_qa;
CREATE INDEX IF NOT EXISTS ix_usuarios_es_project_manager ON asociacionazulgranaerp.usuarios(empresa_id) WHERE es_project_manager;
CREATE INDEX IF NOT EXISTS ix_usuarios_es_tecnico         ON asociacionazulgranaerp.usuarios(empresa_id) WHERE es_tecnico;
CREATE INDEX IF NOT EXISTS ix_facturas_comisionable       ON asociacionazulgranaerp.facturas(empresa_id) WHERE comisionable;

NOTIFY pgrst, 'reload schema';

-- Verificacion
SELECT 'usuarios' AS tabla, column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='usuarios'
  AND column_name IN ('es_qa','es_project_manager','es_tecnico','notificar_entregas','area','avatar_path','fecha_nacimiento','nombre_chat')
UNION ALL
SELECT 'facturas', column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='facturas'
  AND column_name IN ('comisionable','periodo_facturado')
UNION ALL
SELECT 'planes', column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='planes'
  AND column_name IN ('plantilla_operativa')
UNION ALL
SELECT 'pagos', column_name FROM information_schema.columns
WHERE table_schema='asociacionazulgranaerp' AND table_name='pagos'
  AND column_name IN ('cliente_id','suscripcion_id','numero_factura')
ORDER BY tabla, column_name;
