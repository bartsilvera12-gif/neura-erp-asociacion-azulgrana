-- =============================================================================
-- 09 · AJUSTE DE MÓDULOS: sacar Campañas/Etiquetas, agregar Configuración
-- =============================================================================
-- Cambios sobre lo que dejó el 03 y el 07:
--
--   · desactivar `campanas`      (dentro de Omnicanal)
--   · desactivar `etiquetas`     (dentro de Omnicanal)
--   · activar    `configuracion` (para poder tocar ajustes desde la UI)
--
-- No toca los demás módulos activos (los 6 originales + los 5 que quedan de
-- Omnicanal + crm). Idempotente.
-- =============================================================================

DO $ajuste$
DECLARE
  v_tgt        text := 'asociacionazulgranaerp';
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';

  v_activar   text[] := ARRAY['configuracion'];
  v_desactivar text[] := ARRAY['campanas', 'etiquetas'];

  -- Slug + nombre por si el catálogo no los tiene
  v_faltantes text[][] := ARRAY[
    ARRAY['configuracion', 'Configuración']
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

  -- 2) Activar (o insertar activo=true) los que hay que activar
  EXECUTE format(
    'INSERT INTO %I.empresa_modulos (empresa_id, modulo_id, activo) '
    || 'SELECT %L::uuid, m.id, true FROM %I.modulos m '
    || 'WHERE lower(btrim(m.slug)) = ANY (%L::text[]) '
    || 'ON CONFLICT DO NOTHING',
    v_tgt, v_empresa_id, v_tgt, v_activar
  );
  EXECUTE format(
    'UPDATE %I.empresa_modulos em SET activo = true FROM %I.modulos m '
    || 'WHERE em.modulo_id = m.id AND em.empresa_id = %L::uuid '
    || '  AND lower(btrim(m.slug)) = ANY (%L::text[])',
    v_tgt, v_tgt, v_empresa_id, v_activar
  );

  -- 3) Desactivar los que hay que sacar
  EXECUTE format(
    'UPDATE %I.empresa_modulos em SET activo = false FROM %I.modulos m '
    || 'WHERE em.modulo_id = m.id AND em.empresa_id = %L::uuid '
    || '  AND lower(btrim(m.slug)) = ANY (%L::text[])',
    v_tgt, v_tgt, v_empresa_id, v_desactivar
  );

  EXECUTE format('SELECT count(*) FROM %I.empresa_modulos WHERE empresa_id = %L::uuid AND activo',
                 v_tgt, v_empresa_id) INTO v_n;
  RAISE NOTICE 'módulos activos para la empresa: %', v_n;

  FOR r IN
    EXECUTE format(
      'SELECT s AS slug FROM unnest(%L::text[]) AS s '
      || 'WHERE NOT EXISTS (SELECT 1 FROM %I.modulos m WHERE lower(btrim(m.slug)) = s)',
      v_activar, v_tgt)
  LOOP
    RAISE NOTICE 'módulo a activar sin entrada en el catálogo (se omite): %', r.slug;
  END LOOP;

  PERFORM pg_notify('pgrst', 'reload schema');
END;
$ajuste$;

-- Resultado: módulos de la empresa (activo primero)
SELECT m.slug, m.nombre, em.activo
FROM asociacionazulgranaerp.empresa_modulos em
JOIN asociacionazulgranaerp.modulos m ON m.id = em.modulo_id
WHERE em.empresa_id = '498add65-8616-412a-9ee7-d5d60adba136'
ORDER BY em.activo DESC, m.slug;
