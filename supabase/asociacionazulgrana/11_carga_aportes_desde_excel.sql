-- =============================================================================
-- 11 · CARGA DE APORTES HISTORICOS desde el Excel del cliente
-- =============================================================================
-- Fuente: hoja "TESORERIA". Por cada socio con datos:
--   · Se asegura el plan "Aporte Mensual Socio" (APORTE-MENSUAL) en la empresa
--   · Se crea/actualiza una suscripcion (activa) con ese plan
--   · Se emiten facturas historicas (una por mes con aporte) marcadas Pagado
--   · Cada factura lleva su factura_item y su pago correspondiente
--   · Si hubo INSCRIPCION, se registra como factura + pago aparte
--
-- Numero de factura codificado como HIST-{numero_socio}-{YYYY-MM} para aportes y
-- INSC-{numero_socio} para inscripcion. Idempotente: si el numero_factura ya
-- existe para la empresa, no se pisa.
-- =============================================================================

DO $carga$
DECLARE
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';
  v_plan_id    uuid;
  v_cliente_id uuid;
  v_susc_id    uuid;
  v_factura_id uuid;
  v_numf       text;
  v_fecha_emision date;
  v_fecha_pago    date;
  v_n_facturas int := 0;
  v_n_pagos    int := 0;
  v_n_susc     int := 0;
  v_existente  int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'asociacionazulgranaerp') THEN
    RAISE EXCEPTION 'falta el schema asociacionazulgranaerp — corré antes 01_clonar_schema.sql';
  END IF;

  -- 1. Plan "Aporte Mensual Socio" (idempotente)
  SELECT id INTO v_plan_id FROM asociacionazulgranaerp.planes
  WHERE empresa_id = v_empresa_id AND codigo_plan = 'APORTE-MENSUAL';
  IF v_plan_id IS NULL THEN
    v_plan_id := gen_random_uuid();
    INSERT INTO asociacionazulgranaerp.planes (id, empresa_id, codigo_plan, nombre, descripcion, precio, moneda, periodicidad, estado)
    VALUES (v_plan_id, v_empresa_id, 'APORTE-MENSUAL', 'Aporte Mensual Socio',
            'Aporte mensual regular del socio', 25000, 'GS', 'mensual', 'activo');
    RAISE NOTICE 'plan creado: %', v_plan_id;
  END IF;

  -- ==== Socio N° 1 — RUBEN ANTONIO FRANCO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 1;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 1;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-001';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-10-30', '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-10-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-001-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 2 — ANDRES ROA FARIÑA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 2;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 2;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-002';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-10-30', '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-10-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-002-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-002-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 3 — DOMINGO DAMIAN GONZALEZ BENTIEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 3;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 3;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-003-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-003-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-003-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-003-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-003-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-003-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 4 — FERNANDO JAVIER CHAMORRO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 4;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 4;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-004-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-004-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 5 — JOSE HORACIO LOPEZ NUARTE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 5;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 5;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-005-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-005-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 6 — ANDRES DAVID GONZALEZ DIAZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 6;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 6;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-006';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-10-30', '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-10-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-006-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 7 — REINERIO RODRIGO AGÜERO BENITEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 7;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 7;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-10-31', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-007';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-10-31', '2025-10-31', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-007-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 8 — ALCIDES BARRIOS ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 8;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 8;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-008';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-008-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 9 — JAVIER WALDEMAR ROTELA ROCHEMBACH ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 9;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 9;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-009';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-009-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 10 — RICHARD ROLON ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 10;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 10;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-010-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-010-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 11 — ELVIS GABRIEL MARCIANO CAÑIZA ARZAMENDIA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 11;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 11;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-011';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-011-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-011-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-011-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 12 — DIEGO ARMANDO GARCIA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 12;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 12;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-012-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-012-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 13 — PABLO CESAR FERNANDEZ DUARTE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 13;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 13;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-013';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-20', '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-013-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 14 — DERLIS GABRIEL TORALES PANIAGUA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 14;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 14;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-014';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-20', '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-014-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 15 — FREDDY RICARDO MORAL DUARTE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 15;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 15;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-14', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-015';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-14', '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-14', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-015-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 16 — ISAAC ROA FARIÑA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 16;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 16;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-21', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-016';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-21', '2025-11-21', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-21', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-016-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 17 — JUAN MARCELO ARCE LOPEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 17;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 17;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-017';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-20', '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-017-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 18 — PEDRO ALCIDES ROLON ALONZO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 18;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 18;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-24', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-018';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-24', '2025-11-24', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-24', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-018-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 19 — MILNER GUSTAVO BRIZUELA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 19;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 19;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-25', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-019';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-25', '2025-11-25', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-25', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-019-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 20 — WILSON MEDINA GAVILAN ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 20;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 20;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-020';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-020-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-020-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-020-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-020-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 21 — MILCIADES SOSA MARTINEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 21;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 21;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-021';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-021-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 22 — JORGE MERCEDES PEREZ CABRAL ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 22;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 22;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-022';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-022-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-022-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 23 — RAFAEL ANDERSON WIRSCHKE MONGES ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 23;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 23;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-02', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-023';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-02', '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-02', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-023-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 29 — RUBEN EDUARDO FRANCO MARTINEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 29;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 29;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-029';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-029-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 30 — FERNANDO JAVIER CUMBAI BOGARIN ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 30;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 30;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'HIST-030-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-030-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 31 — RONALD ADOLFO HOBECKER GOMEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 31;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 31;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-031';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-031-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 32 — VICTOR DANIEL FRANCO VERON ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 32;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 32;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-032';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-01', '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-032-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 33 — WILMAR LORENZO TORALES PANIAGUA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 33;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 33;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-14', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-033';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-14', '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-14', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-033-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 34 — CESAR DAVID PALMA CHAMORRO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 34;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 34;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-11', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-034';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-11', '2025-11-11', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-11', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-034-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-034-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 35 — OMAR ARIEL BURGOS PASTER ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 35;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 35;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-14', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-035';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-14', '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-14', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-035-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-035-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 36 — JESUS MANUEL ARGUELLO ALARCON ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 36;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 36;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-14', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-036';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-14', '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-14', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-036-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 37 — FELIPE CARBALLO DUARTE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 37;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 37;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-19', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-037';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-19', '2025-11-19', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-19', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-037-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 38 — FERNANDO EFIGENIO CACERES SERVIAN ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 38;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 38;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-038';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-20', '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-038-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 39 — DIEGO DANIEL ROTELA ROCHEMBACH ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 39;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 39;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-039';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-20', '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-039-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 40 — CRISTHIAN OSMAR GERDING ESPINOLA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 40;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 40;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-21', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-040';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-21', '2025-11-21', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-21', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-040-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 41 — ROLANDO JAVIER CACERES SANABRIA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 41;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 41;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-14', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-041';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-14', '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-14', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-041-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 42 — VICTOR ANTONIO VELAZQUEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 42;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 42;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-26', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-042';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-26', '2025-11-26', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-26', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-042-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 43 — JOSE MARIA ROLON LOPEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 43;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 43;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-043';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-043-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 44 — PEDRO GUZMAN ROTELA ROCHEMBACH ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 44;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 44;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-044';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-044-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 45 — LAURA ANTONELA FRANCO MARTINEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 45;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 45;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-045';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-045-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 46 — FERNANDO FRANCO ARZAMENDIA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 46;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 46;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-046';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-046-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 47 — JONATHAN CESAR FRANCO ARZAMENDIA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 47;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 47;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-047';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-047-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 48 — DENIS IRAN ORTIZ DE OLIVEIRA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 48;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 48;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-048';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-048-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 49 — RAMON DARIO ACOSTA GARCETE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 49;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 49;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-049';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-049-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 50 — ALFREDO RAMON LOMAQUIZ ESCALANTE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 50;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 50;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-28', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-050';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-28', '2025-11-28', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-050-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-050-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-050-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-050-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-050-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 51 — OVIDIO RAMON ANTONIO REYES ASCONA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 51;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 51;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-28', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-051';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-28', '2025-11-28', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-051-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 52 — VANNIA MARIA MARTINEZ VILLAR ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 52;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 52;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-29', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-052';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-29', '2025-11-29', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-29', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-052-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 53 — JUAN LORENZO VELOTTO GONZALEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 53;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 53;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-01', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-053';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-01', '2025-12-01', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-01', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-053-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 54 — RICHARD SEBASTIAN CHAMORRO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 54;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 54;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-054';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-054-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-054-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 55 — ADALIZ MAKHARENA SACHELARIDI ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 55;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 55;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-02', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-055';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-02', '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-02', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-055-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 56 — DENIS MARCELO VILLALBA LEGUIZAMÓN ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 56;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 56;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-02', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-056';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-02', '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-02', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-056-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 57 — RONALD ARSENIO PENAYO ULDERA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 57;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 57;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-11-27', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-057';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-11-27', '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-11-27', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-057-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 58 — CRISTHIAN GONZÁLEZ CARDOZO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 58;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 58;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-03', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-058';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-03', '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-03', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-058-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 59 — HUGO FRANCISCO CENTURION ESQUIVEL ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 59;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 59;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-03', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-059';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-03', '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-03', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-059-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 60 — JUAN ANGEL GOMEZ ORREGO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 60;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 60;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-03', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-060';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-03', '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-03', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-060-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 61 — DERLIS ARMANDO SAMUDIO VALDEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 61;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 61;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-05', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-061';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-05', '2025-12-05', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-05', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-061-2025-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-11-01', '2025-11-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-11', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 62 — RAUL ANTONIO WEIMBERG ESCURRA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 62;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 62;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-09', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-062';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-09', '2025-12-09', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-09', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-062-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 63 — CARLOS DAVID BALMACEDA LAGRAVE ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 63;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 63;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-15', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-063';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-15', '2025-12-15', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-15', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-063-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 64 — CHRISTIAN ESTEBAN LUGO SAMANIEGO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 64;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 64;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-18', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-064';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-18', '2025-12-18', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-18', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-064-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 65 — JAVIER CRIPIN VILLALBA LEGUIZAMON ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 65;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 65;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-065';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-20', '2025-12-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-065-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 66 — BERNARDO BRITEZ PAREDES ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 66;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 66;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2025-12-24', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-066';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2025-12-24', '2025-12-24', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2025-12-24', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-066-2025-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2025-12-01', '2025-12-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2025-12', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2025-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 67 — FEDERICO KENNEDY GIMENEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 67;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 67;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-01-21', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-067';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-01-21', '2026-01-21', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-01-21', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-067-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 68 — ALEJANDRO MEZA BENITEZ ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 68;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 68;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-01-28', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-068';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-01-28', '2026-01-28', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-01-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-068-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 69 — RENEE HERMINIO ARANDA CANTERO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 69;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 69;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-01-30', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-069';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-01-30', '2026-01-30', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-01-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-01';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-01-01', '2026-01-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-01', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-01-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-02';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-02-01', '2026-02-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-02', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-02-28', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-03';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-03-01', '2026-03-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-03', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-03-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-04';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-04-01', '2026-04-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-04', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-04-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-05';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-05-01', '2026-05-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-05', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-05-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-06';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-06-01', '2026-06-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-06', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-06-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-069-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 70 — HUGO CESAR FRANCO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 70;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 70;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-07-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-070';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-07-20', '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-07-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-070-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 71 — VICTOR ANTONIO ALVAREZ ULLON ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 71;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 71;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-07-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-071';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-07-20', '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-07-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-10';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-10-01', '2026-10-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-10', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-10-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-11';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-11-01', '2026-11-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-11', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-11-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-071-2026-12';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-12-01', '2026-12-10', 25000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-12', 1, 25000, 25000, 0, 25000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 25000, '2026-12-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 72 — CARLOS ELIAS BENITEZ CABELLO ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 72;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 72;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-07-20', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-072';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-07-20', '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-07-20', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-072-2026-07';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-07-01', '2026-07-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-07', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-07-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-072-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-072-2026-09';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-09-01', '2026-09-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-09', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-09-30', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  -- ==== Socio N° 73 — JUAN MANUEL AZUAGA ====
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes
  WHERE empresa_id = v_empresa_id AND numero_socio = 73;
  IF v_cliente_id IS NULL THEN
    RAISE NOTICE 'socio % no encontrado en clientes — se saltea', 73;
  ELSE
    SELECT id INTO v_susc_id FROM asociacionazulgranaerp.suscripciones
    WHERE empresa_id = v_empresa_id AND cliente_id = v_cliente_id AND plan_id = v_plan_id
    LIMIT 1;
    IF v_susc_id IS NULL THEN
      v_susc_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.suscripciones (id, empresa_id, cliente_id, plan_id, precio, moneda, fecha_inicio, duracion_meses, estado)
      VALUES (v_susc_id, v_empresa_id, v_cliente_id, v_plan_id, 25000, 'GS', '2026-08-06', 12, 'activa');
      v_n_susc := v_n_susc + 1;
    END IF;
    v_numf := 'INSC-073';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_numf, '2026-08-06', '2026-08-06', 50000, 0, 'Pagado', 'contado', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Inscripción de socio', 1, 50000, 50000, 0, 50000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 50000, '2026-08-06', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
    v_numf := 'HIST-073-2026-08';
    SELECT count(*) INTO v_existente FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numf;
    IF v_existente = 0 THEN
      v_factura_id := gen_random_uuid();
      INSERT INTO asociacionazulgranaerp.facturas (id, empresa_id, cliente_id, suscripcion_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_factura_id, v_empresa_id, v_cliente_id, v_susc_id, v_numf, '2026-08-01', '2026-08-10', 30000, 0, 'Pagado', 'suscripcion', 'GS');
      INSERT INTO asociacionazulgranaerp.factura_items (id, factura_id, empresa_id, descripcion, cantidad, precio_unitario, subtotal, iva, total)
      VALUES (gen_random_uuid(), v_factura_id, v_empresa_id, 'Aporte mensual 2026-08', 1, 30000, 30000, 0, 30000);
      INSERT INTO asociacionazulgranaerp.pagos (id, empresa_id, factura_id, monto, fecha_pago, metodo_pago, referencia)
      VALUES (gen_random_uuid(), v_empresa_id, v_factura_id, 30000, '2026-08-31', 'efectivo', 'Historico Excel');
      v_n_facturas := v_n_facturas + 1;
      v_n_pagos := v_n_pagos + 1;
    END IF;
  END IF;

  RAISE NOTICE 'suscripciones nuevas: % — facturas: % — pagos: %',
    v_n_susc, v_n_facturas, v_n_pagos;
  PERFORM pg_notify('pgrst', 'reload schema');
END;
$carga$;

-- Verificacion: totales por socio (deberia coincidir con APORTE TOTAL del Excel)
SELECT c.numero_socio, c.nombre_contacto,
       count(p.id)                     AS pagos,
       coalesce(sum(p.monto), 0)::bigint AS total_pagado
FROM asociacionazulgranaerp.clientes c
LEFT JOIN asociacionazulgranaerp.facturas f ON f.cliente_id = c.id
LEFT JOIN asociacionazulgranaerp.pagos p    ON p.factura_id = f.id
WHERE c.empresa_id = '498add65-8616-412a-9ee7-d5d60adba136' AND c.numero_socio IS NOT NULL
GROUP BY c.numero_socio, c.nombre_contacto
ORDER BY c.numero_socio;
