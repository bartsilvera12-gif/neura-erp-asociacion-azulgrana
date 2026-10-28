-- =============================================================================
-- Saludo de cumpleaños a socios: tabla de control de envíos (idempotencia).
--
-- `cumpleanos_enviados` registra que a un socio ya se le mandó el saludo en un año
-- dado, para no mandar dos veces. Un envío por (empresa, cliente, año).
--
-- Se crea en TODOS los schemas operativos con tabla `clientes`. Solo CREATE TABLE
-- IF NOT EXISTS; no toca datos.
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
    EXECUTE format($t$
      CREATE TABLE IF NOT EXISTS %I.cumpleanos_enviados (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        empresa_id uuid NOT NULL,
        cliente_id uuid NOT NULL,
        anio int NOT NULL,
        enviado_at timestamptz NOT NULL DEFAULT now(),
        ok boolean NOT NULL DEFAULT true,
        wa_message_id text,
        error text,
        CONSTRAINT uq_cumple_%s UNIQUE (empresa_id, cliente_id, anio)
      )
    $t$, r.sch, md5(r.sch));
  END LOOP;
END
$migration$;
