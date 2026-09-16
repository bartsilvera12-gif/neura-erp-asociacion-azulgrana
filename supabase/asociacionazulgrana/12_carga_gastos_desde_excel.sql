-- =============================================================================
-- 12 · CARGA DE GASTOS HISTORICOS desde el Excel del cliente
-- =============================================================================
-- Fuente: hoja "GASTOS" del Excel. Inserta 39 gastos historicos en
-- asociacionazulgranaerp.gastos. Todos entran como tipo='variable', no recurrentes.
-- Categoria queda en NULL: se puede clasificar despues desde la UI.
--
-- Idempotente: matchea por (empresa_id, fecha, descripcion, monto); si esa
-- combinacion exacta ya existe, no se pisa.
-- =============================================================================

DO $carga$
DECLARE
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';
  v_n_insertados int := 0;
  v_n_existentes int := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'asociacionazulgranaerp') THEN
    RAISE EXCEPTION 'falta el schema asociacionazulgranaerp — corré antes 01_clonar_schema.sql';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-05' AND descripcion = 'SELLO AUTOMATICO ''''GRAFICA FM''''' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'SELLO AUTOMATICO ''''GRAFICA FM''''', 150000, 'variable', false, '2025-11-05');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-13' AND descripcion = 'IMPRESIÓN FORMULARIO' AND monto = 100000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'IMPRESIÓN FORMULARIO', 100000, 'variable', false, '2025-11-13');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-07' AND descripcion = 'ADELANTO DE CANCHA AQUILES' AND monto = 330000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'ADELANTO DE CANCHA AQUILES', 330000, 'variable', false, '2025-11-07');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-11' AND descripcion = 'ALQUILER QUINTA DESPEDIDA' AND monto = 500000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'ALQUILER QUINTA DESPEDIDA', 500000, 'variable', false, '2025-11-11');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-20' AND descripcion = 'PAGO DISEÑO PROYECTO' AND monto = 500000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO DISEÑO PROYECTO', 500000, 'variable', false, '2025-11-20');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-20' AND descripcion = 'CARNET' AND monto = 300000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CARNET', 300000, 'variable', false, '2025-11-20');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-26' AND descripcion = 'PAGO CONTADORA MES OCTUBRE' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO CONTADORA MES OCTUBRE', 150000, 'variable', false, '2025-11-26');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-27' AND descripcion = 'CANCELACION DISEÑO PROYECTO' AND monto = 500000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CANCELACION DISEÑO PROYECTO', 500000, 'variable', false, '2025-11-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-27' AND descripcion = 'CARNET' AND monto = 300000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CARNET', 300000, 'variable', false, '2025-11-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-28' AND descripcion = 'CUMPLES MES DE NOVIEMBRE' AND monto = 100000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CUMPLES MES DE NOVIEMBRE', 100000, 'variable', false, '2025-11-28');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-28' AND descripcion = 'VASOS PARA EL FESTEJO ADELANTO' AND monto = 175000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'VASOS PARA EL FESTEJO ADELANTO', 175000, 'variable', false, '2025-11-28');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-29' AND descripcion = 'CARNET CANCELACION' AND monto = 300000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CARNET CANCELACION', 300000, 'variable', false, '2025-11-29');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-11-29' AND descripcion = 'VASOS PARA EL FESTEJO' AND monto = 175000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'VASOS PARA EL FESTEJO', 175000, 'variable', false, '2025-11-29');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-13' AND descripcion = 'AUTENTICACION DE DOCUMENTOS' AND monto = 162000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'AUTENTICACION DE DOCUMENTOS', 162000, 'variable', false, '2025-12-13');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-15' AND descripcion = 'PAGO DE CARNET' AND monto = 225000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO DE CARNET', 225000, 'variable', false, '2025-12-15');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-18' AND descripcion = 'IMPRESION DE CARNET' AND monto = 300000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'IMPRESION DE CARNET', 300000, 'variable', false, '2025-12-18');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-26' AND descripcion = 'PAGO CONTADORA MES NOVIEMBRE' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO CONTADORA MES NOVIEMBRE', 150000, 'variable', false, '2025-12-26');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-26' AND descripcion = 'CUMPLES DICIEMBRE' AND monto = 100000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CUMPLES DICIEMBRE', 100000, 'variable', false, '2025-12-26');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-08' AND descripcion = 'VASOS FALTANTES' AND monto = 105000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'VASOS FALTANTES', 105000, 'variable', false, '2025-12-08');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2025-12-14' AND descripcion = 'TINTAS PARA IMPRESIÓN' AND monto = 140000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'TINTAS PARA IMPRESIÓN', 140000, 'variable', false, '2025-12-14');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-01-23' AND descripcion = 'CANCHA' AND monto = 120000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CANCHA', 120000, 'variable', false, '2026-01-23');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-01-27' AND descripcion = 'PAGO CONTADORA MES DICIEMBRE' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO CONTADORA MES DICIEMBRE', 150000, 'variable', false, '2026-01-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-01-27' AND descripcion = 'REFRIGERIO PARA REUNION' AND monto = 210000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'REFRIGERIO PARA REUNION', 210000, 'variable', false, '2026-01-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-01-27' AND descripcion = 'ALQUILER NÁUTICO' AND monto = 100000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'ALQUILER NÁUTICO', 100000, 'variable', false, '2026-01-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-02-17' AND descripcion = 'PAGO CRNET' AND monto = 160000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO CRNET', 160000, 'variable', false, '2026-02-17');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-02-28' AND descripcion = 'PAGO DE CONTADORA ENERO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO DE CONTADORA ENERO', 150000, 'variable', false, '2026-02-28');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-03-26' AND descripcion = 'APERTURA CAJA DE AHORRO' AND monto = 70000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'APERTURA CAJA DE AHORRO', 70000, 'variable', false, '2026-03-26');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-03-26' AND descripcion = 'PAGO CONTADORA FEBRERO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'PAGO CONTADORA FEBRERO', 150000, 'variable', false, '2026-03-26');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-04-15' AND descripcion = 'COMBUSTIBLE PARA PRESI' AND monto = 50000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'COMBUSTIBLE PARA PRESI', 50000, 'variable', false, '2026-04-15');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-04-15' AND descripcion = 'FIRMA DIGITAL' AND monto = 500000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'FIRMA DIGITAL', 500000, 'variable', false, '2026-04-15');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-04-17' AND descripcion = 'ADELANTO TRABAJO CONTADORA' AND monto = 900000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'ADELANTO TRABAJO CONTADORA', 900000, 'variable', false, '2026-04-17');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-04-27' AND descripcion = 'CONTADORA PAGO MARZO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA PAGO MARZO', 150000, 'variable', false, '2026-04-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-05-23' AND descripcion = 'CONTADORA PAGO ABRIL' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA PAGO ABRIL', 150000, 'variable', false, '2026-05-23');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-05-11' AND descripcion = 'CONTADORA PAGO SIARA Y BALANCE' AND monto = 900000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA PAGO SIARA Y BALANCE', 900000, 'variable', false, '2026-05-11');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-06-12' AND descripcion = 'GRAFICA BANNER' AND monto = 500000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'GRAFICA BANNER', 500000, 'variable', false, '2026-06-12');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-06-25' AND descripcion = 'CONTADORA MES MAYO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA MES MAYO', 150000, 'variable', false, '2026-06-25');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-07-17' AND descripcion = 'EVENTOS CE LAGOON BAR' AND monto = 110000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'EVENTOS CE LAGOON BAR', 110000, 'variable', false, '2026-07-17');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-07-28' AND descripcion = 'CONTADORA PAGO JUNIO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA PAGO JUNIO', 150000, 'variable', false, '2026-07-28');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos WHERE empresa_id = v_empresa_id AND fecha = '2026-08-27' AND descripcion = 'CONTADORA PAGO JULIO' AND monto = 150000) THEN
    INSERT INTO asociacionazulgranaerp.gastos (empresa_id, categoria, descripcion, monto, tipo, recurrente, fecha)
    VALUES (v_empresa_id, NULL, 'CONTADORA PAGO JULIO', 150000, 'variable', false, '2026-08-27');
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;

  RAISE NOTICE 'gastos: % insertados, % ya existían', v_n_insertados, v_n_existentes;
  PERFORM pg_notify('pgrst', 'reload schema');
END;
$carga$;

SELECT fecha, descripcion, monto FROM asociacionazulgranaerp.gastos WHERE empresa_id = '498add65-8616-412a-9ee7-d5d60adba136' ORDER BY fecha;
