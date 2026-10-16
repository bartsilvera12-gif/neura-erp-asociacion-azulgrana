-- =============================================================================
-- FIX: columnas de auditoría de ANULACIÓN faltantes en schemas operativos.
--
-- La migración 20260616120000_facturas_anulacion_auditoria.sql agregó las columnas
--   anulado_at, anulado_por, anulacion_motivo
-- SOLO a `zentra_erp`, `public` y a los tenants dedicados `erp_*`. Las instancias
-- single-client cuyo schema operativo NO coincide con ese patrón (p. ej. `neura`)
-- quedaron SIN esas columnas, por lo que anular una factura fallaba con:
--   "Could not find the 'anulacion_motivo' column of 'facturas' in the schema cache".
--
-- Esta migración reutiliza la MISMA función idempotente ya creada por aquella
-- (zentra_erp.neura_upgrade_facturas_anulacion_auditoria) y la aplica a TODO schema
-- que tenga una tabla `facturas`, cubriendo `neura` y cualquier otro tenant dedicado.
-- Solo agrega columnas (ADD COLUMN IF NOT EXISTS); NO toca datos, pagos, SIFEN ni
-- el CHECK de `estado`.
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
    PERFORM zentra_erp.neura_upgrade_facturas_anulacion_auditoria(r.sch);
    RAISE NOTICE 'facturas anulación auditoría (fix schemas faltantes): schema %', r.sch;
  END LOOP;
END;
$migration$;

-- Refrescar el cache de PostgREST para que vea las columnas nuevas de inmediato.
NOTIFY pgrst, 'reload schema';
