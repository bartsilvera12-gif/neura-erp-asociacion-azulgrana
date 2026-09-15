-- =============================================================================
-- 06 · CATÁLOGO DE VISTAS DE DASHBOARD  instemaq.dashboard_views
--                                     → asociacionazulgranaerp.dashboard_views
-- =============================================================================
-- `dashboard_views` es catálogo DE PRODUCTO (la lista de vistas que existen en
-- el dashboard: Comercial, Financiero, Inventario, etc.), no datos de negocio.
--
-- Sin estas filas, al primer login el ERP no encuentra ninguna vista y muestra
-- "Sin vistas asignadas". Con el catálogo cargado, para el rol `admin` el
-- resolver cae a "todas las activas" (ver
-- src/lib/dashboard/resolve-effective-dashboard-views.ts).
--
-- Copia SOLO esta tabla (mismo criterio que 02 con `modulos`).
-- Es idempotente: se puede volver a correr (ON CONFLICT DO NOTHING).
-- =============================================================================

DO $seed$
DECLARE
  v_src text := 'instemaq';
  v_tgt text := 'asociacionazulgranaerp';
  v_cols text;
  v_n int;
BEGIN
  PERFORM set_config('search_path', 'pg_catalog', true);

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_src AND c.relname = 'dashboard_views' AND c.relkind = 'r'
  ) THEN
    RAISE EXCEPTION 'no existe %.dashboard_views en el origen', v_src;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_tgt AND c.relname = 'dashboard_views' AND c.relkind = 'r'
  ) THEN
    RAISE EXCEPTION 'no existe %.dashboard_views — corré antes 01_clonar_schema.sql', v_tgt;
  END IF;

  SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum)
  INTO v_cols
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = v_tgt AND c.relname = 'dashboard_views' AND a.attnum > 0 AND NOT a.attisdropped
    AND EXISTS (
      SELECT 1 FROM pg_attribute a2
      JOIN pg_class c2 ON c2.oid = a2.attrelid
      JOIN pg_namespace n2 ON n2.oid = c2.relnamespace
      WHERE n2.nspname = v_src AND c2.relname = 'dashboard_views'
        AND a2.attname = a.attname AND a2.attnum > 0 AND NOT a2.attisdropped
    );

  IF v_cols IS NULL THEN
    RAISE EXCEPTION 'no se pudieron resolver columnas comunes entre %.dashboard_views y %.dashboard_views', v_src, v_tgt;
  END IF;

  EXECUTE format(
    'INSERT INTO %I.dashboard_views (%s) SELECT %s FROM %I.dashboard_views ON CONFLICT DO NOTHING',
    v_tgt, v_cols, v_cols, v_src
  );

  EXECUTE format('SELECT count(*) FROM %I.dashboard_views WHERE activo', v_tgt) INTO v_n;
  RAISE NOTICE 'catálogo dashboard_views: % vistas activas en %', v_n, v_tgt;

  PERFORM pg_notify('pgrst', 'reload schema');
END;
$seed$;

-- Listado resultante:
SELECT slug, nombre, orden, activo
FROM asociacionazulgranaerp.dashboard_views
ORDER BY orden, slug;
