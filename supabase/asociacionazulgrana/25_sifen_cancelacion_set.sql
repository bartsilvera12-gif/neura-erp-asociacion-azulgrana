-- =============================================================================
-- 25 · SIFEN - soporte para cancelación real contra SET (Evento rGesEve)
-- =============================================================================
-- Agrega:
--  - empresa_sifen_config.sifen_evento_seq: contador por empresa para dSecMsg
--    del evento SIFEN. Se incrementa atomicamente con UPDATE..RETURNING.
--  - factura_electronica.set_cancelacion_* : traza del envio a SET (estado,
--    codigo, mensaje, protocolo, fecha).
--
-- Idempotente.
-- =============================================================================

BEGIN;

ALTER TABLE asociacionazulgranaerp.empresa_sifen_config
  ADD COLUMN IF NOT EXISTS sifen_evento_seq bigint NOT NULL DEFAULT 0;

ALTER TABLE asociacionazulgranaerp.factura_electronica
  ADD COLUMN IF NOT EXISTS set_cancelacion_estado    text,  -- null | enviado | aprobado | rechazado
  ADD COLUMN IF NOT EXISTS set_cancelacion_cod_res   text,
  ADD COLUMN IF NOT EXISTS set_cancelacion_msg_res   text,
  ADD COLUMN IF NOT EXISTS set_cancelacion_d_prot_aut text,
  ADD COLUMN IF NOT EXISTS set_cancelacion_at        timestamptz,
  ADD COLUMN IF NOT EXISTS set_cancelacion_motivo    text,
  ADD COLUMN IF NOT EXISTS set_cancelacion_d_sec_msg text;

-- Check del estado (idempotente)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fe_set_cancelacion_estado_chk'
      AND conrelid='asociacionazulgranaerp.factura_electronica'::regclass
  ) THEN
    ALTER TABLE asociacionazulgranaerp.factura_electronica
      ADD CONSTRAINT fe_set_cancelacion_estado_chk
      CHECK (set_cancelacion_estado IS NULL OR set_cancelacion_estado IN ('enviado','aprobado','rechazado'));
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

COMMIT;
