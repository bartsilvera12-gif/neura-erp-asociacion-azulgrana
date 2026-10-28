-- =============================================================================
-- Socios: fecha de nacimiento y fecha de asociación.
--
-- `fecha_nacimiento`: para saludos de cumpleaños (fase 2) y datos del socio.
-- `fecha_asociacion`: fecha real en que el socio ingresó a la asociación. Se usa
-- como "socio desde" (en vez de created_at, que para los importados quedó todo en
-- la fecha de carga). Si está vacía, se sigue mostrando created_at.
--
-- Agrega ambas columnas a `clientes` en TODOS los schemas operativos (loop sobre
-- cualquier schema con tabla `clientes`). Solo ADD COLUMN IF NOT EXISTS; no toca
-- datos existentes.
-- =============================================================================

DO $migration$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT n.nspname AS sch
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'clientes'
      AND c.relkind = 'r'
      AND n.nspname NOT LIKE 'pg_%'
      AND n.nspname NOT IN ('information_schema')
  LOOP
    EXECUTE format('ALTER TABLE %I.clientes ADD COLUMN IF NOT EXISTS fecha_nacimiento date', r.sch);
    EXECUTE format('ALTER TABLE %I.clientes ADD COLUMN IF NOT EXISTS fecha_asociacion date', r.sch);
  END LOOP;
END
$migration$;
