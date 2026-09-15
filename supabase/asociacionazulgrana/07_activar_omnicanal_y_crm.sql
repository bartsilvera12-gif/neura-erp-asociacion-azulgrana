-- =============================================================================
-- 07 · ACTIVAR familia Omnicanal + CRM Funnel para la empresa
-- =============================================================================
-- Amplía los módulos habilitados de la empresa. NO desactiva los 6 previos
-- (Clientes, Cobranzas, Dashboard, Gestión Clientes, Planes, Reportes): los
-- agrega. Slugs tal como los evalúa el código (Sidebar.tsx + route-slug-map.ts):
--
--   Familia Omnicanal:
--     · conversaciones
--     · conversaciones-finalizadas
--     · monitoreo
--     · historial-omnicanal
--     · campanas
--     · etiquetas
--
--   CRM Funnel:
--     · crm
--
-- Si algún slug falta en `modulos`, este script lo da de alta primero (mismo
-- criterio que 03: el catálogo de instemaq está desactualizado respecto del
-- código). Idempotente.
-- =============================================================================

DO $activar$
DECLARE
  v_tgt        text := 'asociacionazulgranaerp';
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';

  -- Slugs a activar (se SUMAN a los existentes, no reemplazan)
  v_slugs text[] := ARRAY[
    'conversaciones',
    'conversaciones-finalizadas',
    'monitoreo',
    'historial-omnicanal',
    'campanas',
    'etiquetas',
    'crm'
  ];

  -- Slug + nombre por si el catálogo no los tiene
  v_faltantes text[][] := ARRAY[
    ARRAY['conversaciones',             'Conversaciones'],
    ARRAY['conversaciones-finalizadas', 'Conversaciones finalizadas'],
    ARRAY['monitoreo',                  'Monitoreo'],
    ARRAY['historial-omnicanal',        'Historial omnicanal'],
    ARRAY['campanas',                   'Campañas'],
    ARRAY['etiquetas',                  'Etiquetas'],
    ARRAY['crm',                        'CRM Funnel']
  ];

  v_i int;
  v_n int;
  r   RECORD;
BEGIN
  PERFORM set_config('search_path', 'pg_catalog', true);

  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = v_tgt) THEN
    RAISE EXCEPTION 'falta el schema % — corré antes 01_clonar_schema.sql', v_tgt;
  END IF;

  -- 1) Altas en el catálogo modulos que falten
  FOR v_i IN 1 .. array_length(v_faltantes, 1)
  LOOP
    EXECUTE format(
      'INSERT INTO %I.modulos (nombre, slug) SELECT %L, %L '
      || 'WHERE NOT EXISTS (SELECT 1 FROM %I.modulos WHERE lower(btrim(slug)) = %L)',
      v_tgt, v_faltantes[v_i][2], v_faltantes[v_i][1], v_tgt, v_faltantes[v_i][1]
    );
  END LOOP;

  -- 2) empresa_modulos: agregar activo=true (sin tocar los que ya estaban)
  EXECUTE format(
    'INSERT INTO %I.empresa_modulos (empresa_id, modulo_id, activo) '
    || 'SELECT %L::uuid, m.id, true FROM %I.modulos m WHERE lower(btrim(m.slug)) = ANY (%L::text[]) '
    || 'ON CONFLICT DO NOTHING',
    v_tgt, v_empresa_id, v_tgt, v_slugs
  );

  -- Si alguno estaba desactivado, activarlo
  EXECUTE format(
    'UPDATE %I.empresa_modulos em SET activo = true FROM %I.modulos m '
    || 'WHERE em.modulo_id = m.id AND em.empresa_id = %L::uuid AND lower(btrim(m.slug)) = ANY (%L::text[])',
    v_tgt, v_tgt, v_empresa_id, v_slugs
  );

  EXECUTE format('SELECT count(*) FROM %I.empresa_modulos WHERE empresa_id = %L::uuid AND activo',
                 v_tgt, v_empresa_id) INTO v_n;
  RAISE NOTICE 'módulos habilitados totales (incluye los 6 previos): %', v_n;

  -- Slugs pedidos que no existen en el catálogo (no debería quedar ninguno)
  FOR r IN
    EXECUTE format(
      'SELECT s AS slug FROM unnest(%L::text[]) AS s '
      || 'WHERE NOT EXISTS (SELECT 1 FROM %I.modulos m WHERE lower(btrim(m.slug)) = s)',
      v_slugs, v_tgt)
  LOOP
    RAISE NOTICE 'módulo sin entrada en el catálogo (se omite): %', r.slug;
  END LOOP;

  PERFORM pg_notify('pgrst', 'reload schema');
END;
$activar$;

-- Resultado: módulos activos de la empresa
SELECT m.slug, m.nombre, em.activo
FROM asociacionazulgranaerp.empresa_modulos em
JOIN asociacionazulgranaerp.modulos m ON m.id = em.modulo_id
WHERE em.empresa_id = '498add65-8616-412a-9ee7-d5d60adba136'
ORDER BY em.activo DESC, m.slug;
