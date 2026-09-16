-- =============================================================================
-- 14 · Completar columnas faltantes en clientes (Asociacion Azulgrana)
-- =============================================================================
-- El error "column clientes.razon_social does not exist" aparece porque el
-- schema `instemaq` (origen del clon) no tenia varias columnas que el codigo
-- de sistemas-propio sí consulta (razon_social, ruc_factura, project_manager_*,
-- baja_operativa_*, deleted_at, perfil_tributario_activo, etc.).
--
-- Este script agrega TODAS las columnas que el ERP espera, con IF NOT EXISTS,
-- para que las consultas y el PATCH de clientes funcionen sin romper nada.
--
-- Ninguna columna es NOT NULL (o si lo es, tiene default) — no rompe datos ya
-- cargados por los scripts 10 y 11.
-- =============================================================================

ALTER TABLE asociacionazulgranaerp.clientes
  ADD COLUMN IF NOT EXISTS razon_social                text,
  ADD COLUMN IF NOT EXISTS ruc_factura                 text,
  ADD COLUMN IF NOT EXISTS ruc                         text,
  ADD COLUMN IF NOT EXISTS empresa                     text,
  ADD COLUMN IF NOT EXISTS documento                   text,
  ADD COLUMN IF NOT EXISTS telefono_secundario         text,
  ADD COLUMN IF NOT EXISTS email_secundario            text,
  ADD COLUMN IF NOT EXISTS ciudad                      text,
  ADD COLUMN IF NOT EXISTS pais                        text,
  ADD COLUMN IF NOT EXISTS sitio_web                   text,
  ADD COLUMN IF NOT EXISTS instagram                   text,
  ADD COLUMN IF NOT EXISTS linkedin                    text,
  ADD COLUMN IF NOT EXISTS valor_cliente               numeric,
  ADD COLUMN IF NOT EXISTS condicion_pago              text,
  ADD COLUMN IF NOT EXISTS moneda_preferida            text DEFAULT 'GS',
  ADD COLUMN IF NOT EXISTS vendedor_asignado           text,
  ADD COLUMN IF NOT EXISTS vendedor_usuario_id         uuid,
  ADD COLUMN IF NOT EXISTS project_manager_id          uuid,
  ADD COLUMN IF NOT EXISTS prospecto_id                integer,
  ADD COLUMN IF NOT EXISTS notas                       jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS tipo_servicio_cliente       text,

  -- SIFEN (facturacion electronica): el ERP siempre las consulta aunque no
  -- se emitan facturas todavia.
  ADD COLUMN IF NOT EXISTS sifen_receptor_extranjero   boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sifen_codigo_pais           text,
  ADD COLUMN IF NOT EXISTS sifen_tipo_doc_receptor     smallint,
  ADD COLUMN IF NOT EXISTS sifen_receptor_manual       boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sifen_receptor_naturaleza   text,
  ADD COLUMN IF NOT EXISTS sifen_ti_ope                smallint,
  ADD COLUMN IF NOT EXISTS sifen_num_id_de             text,
  ADD COLUMN IF NOT EXISTS sifen_direccion_de          text,
  ADD COLUMN IF NOT EXISTS sifen_num_casa_de           integer,
  ADD COLUMN IF NOT EXISTS sifen_descripcion_tipo_doc  text,

  -- Trazabilidad, baja operativa y eliminacion lógica
  ADD COLUMN IF NOT EXISTS created_by_user_id          uuid,
  ADD COLUMN IF NOT EXISTS created_by_nombre           text,
  ADD COLUMN IF NOT EXISTS deleted_at                  timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_by_user_id          uuid,
  ADD COLUMN IF NOT EXISTS deletion_reason             text,
  ADD COLUMN IF NOT EXISTS baja_operativa_at           timestamptz,
  ADD COLUMN IF NOT EXISTS baja_operativa_by_user_id   uuid,
  ADD COLUMN IF NOT EXISTS baja_operativa_by_nombre    text,
  ADD COLUMN IF NOT EXISTS baja_operativa_motivo       text,
  ADD COLUMN IF NOT EXISTS baja_operativa_anulo_factura boolean;

-- Indices utiles para queries frecuentes (idempotentes)
CREATE INDEX IF NOT EXISTS idx_clientes_deleted_at        ON asociacionazulgranaerp.clientes(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_clientes_baja_operativa_at ON asociacionazulgranaerp.clientes(baja_operativa_at) WHERE baja_operativa_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_clientes_vendedor          ON asociacionazulgranaerp.clientes(empresa_id, vendedor_usuario_id);
CREATE INDEX IF NOT EXISTS idx_clientes_project_manager   ON asociacionazulgranaerp.clientes(project_manager_id);

NOTIFY pgrst, 'reload schema';

-- Verificacion: columnas presentes ahora en clientes
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'asociacionazulgranaerp' AND table_name = 'clientes'
ORDER BY ordinal_position;
