-- =============================================================================
-- 18 · Catch-up de columnas en crm_prospectos (Asociacion Azulgrana)
-- =============================================================================
-- Al crear un prospecto sale:
--   "Could not find the 'responsable_usuario_id' column of 'crm_prospectos'"
--
-- Es el mismo patron de los SQL 14, 15 y 16: el schema instemaq (origen del
-- clon) no tenia estas columnas porque las migraciones que las agregan solo
-- corrieron sobre neura / public y no sobre instemaq.
--
-- Agrega con IF NOT EXISTS. Idempotente. No pisa datos.
-- =============================================================================

ALTER TABLE asociacionazulgranaerp.crm_prospectos
  ADD COLUMN IF NOT EXISTS responsable_usuario_id uuid,
  ADD COLUMN IF NOT EXISTS observaciones          text,
  ADD COLUMN IF NOT EXISTS origen_creacion        text NOT NULL DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS origen_detalle         text;

-- Indices utiles (idempotentes)
CREATE INDEX IF NOT EXISTS idx_crm_prospectos_responsable_usuario
  ON asociacionazulgranaerp.crm_prospectos(empresa_id, responsable_usuario_id);

CREATE INDEX IF NOT EXISTS idx_crm_prospectos_origen_creacion
  ON asociacionazulgranaerp.crm_prospectos(empresa_id, origen_creacion);

-- Constraint del check para origen_creacion (permite 'manual' y 'whatsapp' + otros
-- valores libres en el futuro). Solo se agrega si no existe.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'crm_prospectos_origen_creacion_check'
      AND connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'asociacionazulgranaerp')
  ) THEN
    ALTER TABLE asociacionazulgranaerp.crm_prospectos
      ADD CONSTRAINT crm_prospectos_origen_creacion_check
      CHECK (origen_creacion IN ('manual','whatsapp','webhook','api','import'));
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

-- Verificacion: columnas ahora presentes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'asociacionazulgranaerp'
  AND table_name   = 'crm_prospectos'
  AND column_name IN ('responsable_usuario_id','observaciones','origen_creacion','origen_detalle')
ORDER BY column_name;
