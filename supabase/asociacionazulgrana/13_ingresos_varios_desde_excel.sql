-- =============================================================================
-- 13 · TABLA ingresos_varios + CARGA DE OTRAS ENTRADAS desde el Excel
-- =============================================================================
-- ingresos_varios: para movimientos de caja que NO son aportes de socios ni
-- cobros de facturas (canchas, caja anterior, donaciones, eventos, etc.).
--
-- Crea la tabla + policies RLS + indice. Carga los 4 registros
-- de la hoja "OTRAS ENTRADAS" del Excel del cliente.
--
-- Todo idempotente. La UI para gestionar ingresos varios se puede agregar
-- despues; por ahora la data queda disponible en la base para reportes.
-- =============================================================================

CREATE TABLE IF NOT EXISTS asociacionazulgranaerp.ingresos_varios (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id   uuid NOT NULL REFERENCES asociacionazulgranaerp.empresas(id) ON DELETE CASCADE,
  categoria    text,
  descripcion  text NOT NULL,
  monto        numeric(14,2) NOT NULL,
  fecha        date NOT NULL,
  metodo       text DEFAULT 'efectivo',
  referencia   text,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ingresos_varios_empresa_fecha_idx ON asociacionazulgranaerp.ingresos_varios (empresa_id, fecha);

ALTER TABLE asociacionazulgranaerp.ingresos_varios ENABLE ROW LEVEL SECURITY;

-- Politicas RLS analogas a las de gastos: acceso por empresa
DO $rls$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'asociacionazulgranaerp' AND tablename = 'ingresos_varios' AND policyname = 'ingresos_varios_select') THEN
    EXECUTE 'CREATE POLICY "ingresos_varios_select" ON asociacionazulgranaerp.ingresos_varios FOR SELECT USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'asociacionazulgranaerp' AND tablename = 'ingresos_varios' AND policyname = 'ingresos_varios_insert') THEN
    EXECUTE 'CREATE POLICY "ingresos_varios_insert" ON asociacionazulgranaerp.ingresos_varios FOR INSERT WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'asociacionazulgranaerp' AND tablename = 'ingresos_varios' AND policyname = 'ingresos_varios_update') THEN
    EXECUTE 'CREATE POLICY "ingresos_varios_update" ON asociacionazulgranaerp.ingresos_varios FOR UPDATE USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id)) WITH CHECK (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'asociacionazulgranaerp' AND tablename = 'ingresos_varios' AND policyname = 'ingresos_varios_delete') THEN
    EXECUTE 'CREATE POLICY "ingresos_varios_delete" ON asociacionazulgranaerp.ingresos_varios FOR DELETE USING (asociacionazulgranaerp.puede_acceder_empresa(empresa_id))';
  END IF;
END $rls$;

GRANT SELECT, INSERT, UPDATE, DELETE ON asociacionazulgranaerp.ingresos_varios TO authenticated;
GRANT ALL ON asociacionazulgranaerp.ingresos_varios TO postgres, service_role;

DO $carga$
DECLARE
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';
  v_n_insertados int := 0;
  v_n_existentes int := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.ingresos_varios WHERE empresa_id = v_empresa_id AND fecha = '2025-11-15' AND descripcion = 'APORRTE DE CANCHA VIERNES' AND monto = 120000) THEN
    INSERT INTO asociacionazulgranaerp.ingresos_varios (empresa_id, descripcion, monto, fecha, metodo, referencia)
    VALUES (v_empresa_id, 'APORRTE DE CANCHA VIERNES', 120000, '2025-11-15', 'efectivo', 'Historico Excel');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.ingresos_varios WHERE empresa_id = v_empresa_id AND fecha = '2025-11-15' AND descripcion = 'CAJA ANTERIOR JUEVES 20' AND monto = 2529000) THEN
    INSERT INTO asociacionazulgranaerp.ingresos_varios (empresa_id, descripcion, monto, fecha, metodo, referencia)
    VALUES (v_empresa_id, 'CAJA ANTERIOR JUEVES 20', 2529000, '2025-11-15', 'efectivo', 'Historico Excel');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.ingresos_varios WHERE empresa_id = v_empresa_id AND fecha = '2025-11-15' AND descripcion = 'APORTE CANCHA' AND monto = 120000) THEN
    INSERT INTO asociacionazulgranaerp.ingresos_varios (empresa_id, descripcion, monto, fecha, metodo, referencia)
    VALUES (v_empresa_id, 'APORTE CANCHA', 120000, '2025-11-15', 'efectivo', 'Historico Excel');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.ingresos_varios WHERE empresa_id = v_empresa_id AND fecha = '2025-11-15' AND descripcion = 'APORTE CANCHA' AND monto = 120000) THEN
    INSERT INTO asociacionazulgranaerp.ingresos_varios (empresa_id, descripcion, monto, fecha, metodo, referencia)
    VALUES (v_empresa_id, 'APORTE CANCHA', 120000, '2025-11-15', 'efectivo', 'Historico Excel');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;

  RAISE NOTICE 'ingresos_varios: % insertados, % ya existían', v_n_insertados, v_n_existentes;
  PERFORM pg_notify('pgrst', 'reload schema');
END;
$carga$;

SELECT fecha, descripcion, monto FROM asociacionazulgranaerp.ingresos_varios WHERE empresa_id = '498add65-8616-412a-9ee7-d5d60adba136' ORDER BY fecha;
