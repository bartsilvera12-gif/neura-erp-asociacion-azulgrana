-- =============================================================================
-- 08 · VISTAS DE DASHBOARD HABILITADAS para la empresa
-- =============================================================================
-- Deja SOLO las pestañas del dashboard que aplican a la Asociación Hernandarias
-- Azulgrana:
--
--   · comercial   → leads, CRM, clientes ganados
--   · financiero  → cobranzas, pagos, saldos
--
-- Quedan FUERA:
--   · inventario, ventas         (no usan estos módulos)
--   · proyectos, sla_proyectos   (no usan proyectos)
--   · dashboard_ejecutivo, dashboard_pm (perfil ejecutivo/PM sin uso)
--
-- Sin filas en `empresa_dashboard_views`, el resolver cae a "todas las activas
-- del catálogo" y muestra Inventario/Ventas también
-- (src/lib/dashboard/resolve-effective-dashboard-views.ts, línea 119).
-- Con estas filas, el resolver toma SOLO las que activamos acá.
--
-- Requiere el 06 corrido antes (siembra el catálogo dashboard_views).
-- Idempotente.
-- =============================================================================

DO $vistas$
DECLARE
  v_tgt        text := 'asociacionazulgranaerp';
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';

  v_slugs text[] := ARRAY['comercial', 'financiero'];

  v_n int;
  r   RECORD;
BEGIN
  PERFORM set_config('search_path', 'pg_catalog', true);

  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = v_tgt) THEN
    RAISE EXCEPTION 'falta el schema % — corré antes 01_clonar_schema.sql', v_tgt;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_tgt AND c.relname = 'dashboard_views' AND c.relkind = 'r'
  ) THEN
    RAISE EXCEPTION 'falta %.dashboard_views — corré el 01', v_tgt;
  END IF;

  -- Si el catálogo está vacío, la asignación no tiene efecto: avisar
  EXECUTE format('SELECT count(*) FROM %I.dashboard_views WHERE activo', v_tgt) INTO v_n;
  IF v_n = 0 THEN
    RAISE WARNING 'catálogo %.dashboard_views vacío — corré antes 06_catalogo_dashboard_views.sql', v_tgt;
  END IF;

  -- Insertar (o reactivar) solo las vistas pedidas
  EXECUTE format(
    'INSERT INTO %I.empresa_dashboard_views (empresa_id, dashboard_view_id, activo) '
    || 'SELECT %L::uuid, v.id, true FROM %I.dashboard_views v '
    || 'WHERE lower(btrim(v.slug)) = ANY (%L::text[]) '
    || 'ON CONFLICT DO NOTHING',
    v_tgt, v_empresa_id, v_tgt, v_slugs
  );

  EXECUTE format(
    'UPDATE %I.empresa_dashboard_views ed SET activo = true FROM %I.dashboard_views v '
    || 'WHERE ed.dashboard_view_id = v.id AND ed.empresa_id = %L::uuid '
    || '  AND lower(btrim(v.slug)) = ANY (%L::text[])',
    v_tgt, v_tgt, v_empresa_id, v_slugs
  );

  -- Desactivar cualquier otra vista para esta empresa (por si quedó activa antes)
  EXECUTE format(
    'UPDATE %I.empresa_dashboard_views ed SET activo = false FROM %I.dashboard_views v '
    || 'WHERE ed.dashboard_view_id = v.id AND ed.empresa_id = %L::uuid '
    || '  AND NOT (lower(btrim(v.slug)) = ANY (%L::text[]))',
    v_tgt, v_tgt, v_empresa_id, v_slugs
  );

  EXECUTE format(
    'SELECT count(*) FROM %I.empresa_dashboard_views WHERE empresa_id = %L::uuid AND activo',
    v_tgt, v_empresa_id) INTO v_n;
  RAISE NOTICE 'vistas de dashboard activas para la empresa: %', v_n;

  -- Slugs pedidos que no aparecen en el catálogo
  FOR r IN
    EXECUTE format(
      'SELECT s AS slug FROM unnest(%L::text[]) AS s '
      || 'WHERE NOT EXISTS (SELECT 1 FROM %I.dashboard_views v WHERE lower(btrim(v.slug)) = s)',
      v_slugs, v_tgt)
  LOOP
    RAISE NOTICE 'vista sin entrada en el catálogo (se omite): %', r.slug;
  END LOOP;

  PERFORM pg_notify('pgrst', 'reload schema');
END;
$vistas$;

-- Resultado: vistas activas para la empresa
SELECT v.slug, v.nombre, v.orden, ed.activo
FROM asociacionazulgranaerp.empresa_dashboard_views ed
JOIN asociacionazulgranaerp.dashboard_views v ON v.id = ed.dashboard_view_id
WHERE ed.empresa_id = '498add65-8616-412a-9ee7-d5d60adba136'
ORDER BY ed.activo DESC, v.orden, v.slug;
