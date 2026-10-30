-- =============================================================================
-- 27 · IVA por PLAN  (planes.iva_tipo)
-- =============================================================================
-- CONTEXTO: las facturas de aporte mensual se generan solas desde la suscripción
-- del socio, y hasta ahora el IVA de la línea salía SIEMPRE 10% (fijo en el
-- código). Para una asociación civil sin fines de lucro, la cuota social (aporte)
-- es EXENTA de IVA. Esta columna permite definir el tratamiento de IVA a nivel de
-- PLAN, de modo que cada factura de ese plan herede la tasa correcta.
--
-- Valores: 'exenta' | 'iva_5' | 'iva_10'.
--
-- ADITIVA Y SEGURA: el DEFAULT es 'iva_10', así que no cambia el comportamiento
-- de ningún plan existente al aplicarse. Para dejar los aportes EXENTOS se cambia
-- el plan correspondiente a 'exenta' (desde la pantalla de Planes o con un UPDATE
-- puntual). Idempotente: se puede reejecutar sin efectos.
--
-- CÓMO APLICAR:
--   npm run db:apply-sql-file supabase/asociacionazulgrana/27_planes_iva_tipo.sql
-- =============================================================================

BEGIN;

ALTER TABLE asociacionazulgranaerp.planes
  ADD COLUMN IF NOT EXISTS iva_tipo text NOT NULL DEFAULT 'iva_10'
  CHECK (iva_tipo IN ('exenta', 'iva_5', 'iva_10'));

COMMENT ON COLUMN asociacionazulgranaerp.planes.iva_tipo IS
  'Tratamiento de IVA de las facturas de este plan: exenta | iva_5 | iva_10. '
  'La cuota social (aporte mensual) de la asociación va exenta. Default iva_10 por compatibilidad.';

COMMIT;

-- PostgREST cachea el schema: sin esto, los writes/lectura de la columna nueva
-- fallan con "Could not find ... in the schema cache".
NOTIFY pgrst, 'reload schema';
