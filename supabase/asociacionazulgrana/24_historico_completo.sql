-- =============================================================================
-- 24 · Historico faltante: Inscripciones, Gastos, Otras Entradas
-- =============================================================================
-- Fuente: Excel ASOCIACION HERNANDARIAS AZULGRANA (hojas TESORERIA, GASTOS,
-- OTRAS ENTRADAS). El SQL 23 solo trajo las cuotas mensuales adeudadas.
--
-- Este script trae:
--   * 62 inscripciones (Gs. 3,100,000) como facturas Pagadas
--   * 39 gastos historicos (Gs. 9,582,000)
--   * 4 otras entradas (Gs. 2,889,000) contra cliente OTROS INGRESOS
--
-- Idempotente. Rollback friendly.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_empresa_id     uuid;
  v_cliente_id     uuid;
  v_otros_id       uuid;
  v_numero_factura text;
BEGIN
  SELECT id INTO v_empresa_id FROM asociacionazulgranaerp.empresas LIMIT 1;
  IF v_empresa_id IS NULL THEN RAISE EXCEPTION 'sin empresa en el tenant'; END IF;

  -- ─── INSCRIPCIONES ───────────────────────────────────────────────────────
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 1;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-1';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-10-30', DATE '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 2;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-2';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-10-30', DATE '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 6;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-6';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-10-30', DATE '2025-10-30', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 7;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-7';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-10-31', DATE '2025-10-31', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 8;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-8';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 9;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-9';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 11;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-11';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 13;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-13';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-20', DATE '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 14;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-14';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-20', DATE '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 15;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-15';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-14', DATE '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 16;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-16';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-21', DATE '2025-11-21', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 17;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-17';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-20', DATE '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 18;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-18';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-24', DATE '2025-11-24', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 19;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-19';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-25', DATE '2025-11-25', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 20;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-20';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 21;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-21';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 22;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-22';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 23;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-23';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-02', DATE '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 29;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-29';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 31;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-31';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 32;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-32';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-01', DATE '2025-11-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 33;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-33';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-14', DATE '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 34;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-34';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-11', DATE '2025-11-11', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 35;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-35';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-14', DATE '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 36;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-36';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-14', DATE '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 37;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-37';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-19', DATE '2025-11-19', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 38;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-38';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-20', DATE '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 39;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-39';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-20', DATE '2025-11-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 40;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-40';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-21', DATE '2025-11-21', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 41;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-41';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-14', DATE '2025-11-14', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 42;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-42';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-26', DATE '2025-11-26', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 43;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-43';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 44;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-44';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 45;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-45';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 46;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-46';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 47;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-47';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 48;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-48';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 49;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-49';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 50;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-50';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-28', DATE '2025-11-28', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 51;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-51';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-28', DATE '2025-11-28', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 52;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-52';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-29', DATE '2025-11-29', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 53;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-53';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-01', DATE '2025-12-01', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 54;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-54';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 55;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-55';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-02', DATE '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 56;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-56';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-02', DATE '2025-12-02', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 57;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-57';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-11-27', DATE '2025-11-27', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 58;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-58';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-03', DATE '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 59;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-59';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-03', DATE '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 60;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-60';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-03', DATE '2025-12-03', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 61;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-61';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-05', DATE '2025-12-05', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 62;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-62';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-09', DATE '2025-12-09', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 63;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-63';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-15', DATE '2025-12-15', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 64;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-64';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-18', DATE '2025-12-18', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 65;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-65';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-20', DATE '2025-12-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 66;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-66';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2025-12-24', DATE '2025-12-24', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 67;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-67';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-01-21', DATE '2026-01-21', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 68;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-68';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-01-28', DATE '2026-01-28', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 69;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-69';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-01-30', DATE '2026-01-30', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 70;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-70';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-07-20', DATE '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 71;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-71';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-07-20', DATE '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 72;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-72';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-07-20', DATE '2026-07-20', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;
  SELECT id INTO v_cliente_id FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 73;
  IF v_cliente_id IS NOT NULL THEN
    v_numero_factura := 'INSCRIP-73';
    IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
      INSERT INTO asociacionazulgranaerp.facturas
        (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
      VALUES (v_empresa_id, v_cliente_id, v_numero_factura, DATE '2026-08-06', DATE '2026-08-06', 50000, 0, 'Pagado', 'contado', 'GS');
    END IF;
  END IF;

  -- ─── OTROS INGRESOS ──────────────────────────────────────────────────────
  SELECT id INTO v_otros_id FROM asociacionazulgranaerp.clientes
   WHERE empresa_id = v_empresa_id AND nombre_contacto = 'OTROS INGRESOS' LIMIT 1;
  IF v_otros_id IS NULL THEN
    INSERT INTO asociacionazulgranaerp.clientes
      (empresa_id, tipo_cliente, nombre_contacto, empresa, estado, origen)
    VALUES (v_empresa_id, 'persona', 'OTROS INGRESOS', 'OTROS INGRESOS', 'activo', 'MANUAL')
    RETURNING id INTO v_otros_id;
  END IF;

  v_numero_factura := 'OTRA-001';
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
    INSERT INTO asociacionazulgranaerp.facturas
      (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
    VALUES (v_empresa_id, v_otros_id, v_numero_factura, DATE '2025-11-15', DATE '2025-11-15', 120000, 0, 'Pagado', 'contado', 'GS');
  END IF;
  -- APORRTE DE CANCHA VIERNES
  v_numero_factura := 'OTRA-002';
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
    INSERT INTO asociacionazulgranaerp.facturas
      (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
    VALUES (v_empresa_id, v_otros_id, v_numero_factura, DATE '2025-11-15', DATE '2025-11-15', 2529000, 0, 'Pagado', 'contado', 'GS');
  END IF;
  -- CAJA ANTERIOR JUEVES 20
  v_numero_factura := 'OTRA-003';
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
    INSERT INTO asociacionazulgranaerp.facturas
      (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
    VALUES (v_empresa_id, v_otros_id, v_numero_factura, DATE '2025-11-15', DATE '2025-11-15', 120000, 0, 'Pagado', 'contado', 'GS');
  END IF;
  -- APORTE CANCHA
  v_numero_factura := 'OTRA-004';
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.facturas WHERE empresa_id = v_empresa_id AND numero_factura = v_numero_factura) THEN
    INSERT INTO asociacionazulgranaerp.facturas
      (empresa_id, cliente_id, numero_factura, fecha, fecha_vencimiento, monto, saldo, estado, tipo, moneda)
    VALUES (v_empresa_id, v_otros_id, v_numero_factura, DATE '2025-11-15', DATE '2025-11-15', 120000, 0, 'Pagado', 'contado', 'GS');
  END IF;
  -- APORTE CANCHA

  -- ─── GASTOS HISTORICOS ───────────────────────────────────────────────────
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-05' AND monto = 150000 AND descripcion = 'SELLO AUTOMATICO ''''GRAFICA FM''''') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'SELLO AUTOMATICO ''''GRAFICA FM''''', 150000, DATE '2025-11-05', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-13' AND monto = 100000 AND descripcion = 'IMPRESIÓN FORMULARIO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'IMPRESIÓN FORMULARIO', 100000, DATE '2025-11-13', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-07' AND monto = 330000 AND descripcion = 'ADELANTO DE CANCHA AQUILES') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'ADELANTO DE CANCHA AQUILES', 330000, DATE '2025-11-07', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-11' AND monto = 500000 AND descripcion = 'ALQUILER QUINTA DESPEDIDA') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'ALQUILER QUINTA DESPEDIDA', 500000, DATE '2025-11-11', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-20' AND monto = 500000 AND descripcion = 'PAGO DISEÑO PROYECTO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO DISEÑO PROYECTO', 500000, DATE '2025-11-20', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-20' AND monto = 300000 AND descripcion = 'CARNET') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CARNET', 300000, DATE '2025-11-20', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-26' AND monto = 150000 AND descripcion = 'PAGO CONTADORA MES OCTUBRE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO CONTADORA MES OCTUBRE', 150000, DATE '2025-11-26', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-27' AND monto = 500000 AND descripcion = 'CANCELACION DISEÑO PROYECTO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CANCELACION DISEÑO PROYECTO', 500000, DATE '2025-11-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-27' AND monto = 300000 AND descripcion = 'CARNET') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CARNET', 300000, DATE '2025-11-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-28' AND monto = 100000 AND descripcion = 'CUMPLES MES DE NOVIEMBRE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CUMPLES MES DE NOVIEMBRE', 100000, DATE '2025-11-28', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-28' AND monto = 175000 AND descripcion = 'VASOS PARA EL FESTEJO ADELANTO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'VASOS PARA EL FESTEJO ADELANTO', 175000, DATE '2025-11-28', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-29' AND monto = 300000 AND descripcion = 'CARNET CANCELACION') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CARNET CANCELACION', 300000, DATE '2025-11-29', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-11-29' AND monto = 175000 AND descripcion = 'VASOS PARA EL FESTEJO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'VASOS PARA EL FESTEJO', 175000, DATE '2025-11-29', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-13' AND monto = 162000 AND descripcion = 'AUTENTICACION DE DOCUMENTOS') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'AUTENTICACION DE DOCUMENTOS', 162000, DATE '2025-12-13', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-15' AND monto = 225000 AND descripcion = 'PAGO DE CARNET') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO DE CARNET', 225000, DATE '2025-12-15', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-18' AND monto = 300000 AND descripcion = 'IMPRESION DE CARNET') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'IMPRESION DE CARNET', 300000, DATE '2025-12-18', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-26' AND monto = 150000 AND descripcion = 'PAGO CONTADORA MES NOVIEMBRE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO CONTADORA MES NOVIEMBRE', 150000, DATE '2025-12-26', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-26' AND monto = 100000 AND descripcion = 'CUMPLES DICIEMBRE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CUMPLES DICIEMBRE', 100000, DATE '2025-12-26', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-08' AND monto = 105000 AND descripcion = 'VASOS FALTANTES') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'VASOS FALTANTES', 105000, DATE '2025-12-08', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2025-12-14' AND monto = 140000 AND descripcion = 'TINTAS PARA IMPRESIÓN') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'TINTAS PARA IMPRESIÓN', 140000, DATE '2025-12-14', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-01-23' AND monto = 120000 AND descripcion = 'CANCHA') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CANCHA', 120000, DATE '2026-01-23', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-01-27' AND monto = 150000 AND descripcion = 'PAGO CONTADORA MES DICIEMBRE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO CONTADORA MES DICIEMBRE', 150000, DATE '2026-01-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-01-27' AND monto = 210000 AND descripcion = 'REFRIGERIO PARA REUNION') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'REFRIGERIO PARA REUNION', 210000, DATE '2026-01-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-01-27' AND monto = 100000 AND descripcion = 'ALQUILER NÁUTICO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'ALQUILER NÁUTICO', 100000, DATE '2026-01-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-02-17' AND monto = 160000 AND descripcion = 'PAGO CRNET') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO CRNET', 160000, DATE '2026-02-17', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-02-28' AND monto = 150000 AND descripcion = 'PAGO DE CONTADORA ENERO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO DE CONTADORA ENERO', 150000, DATE '2026-02-28', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-03-26' AND monto = 70000 AND descripcion = 'APERTURA CAJA DE AHORRO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'APERTURA CAJA DE AHORRO', 70000, DATE '2026-03-26', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-03-26' AND monto = 150000 AND descripcion = 'PAGO CONTADORA FEBRERO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'PAGO CONTADORA FEBRERO', 150000, DATE '2026-03-26', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-04-15' AND monto = 50000 AND descripcion = 'COMBUSTIBLE PARA PRESI') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'COMBUSTIBLE PARA PRESI', 50000, DATE '2026-04-15', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-04-15' AND monto = 500000 AND descripcion = 'FIRMA DIGITAL') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'FIRMA DIGITAL', 500000, DATE '2026-04-15', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-04-17' AND monto = 900000 AND descripcion = 'ADELANTO TRABAJO CONTADORA') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'ADELANTO TRABAJO CONTADORA', 900000, DATE '2026-04-17', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-04-27' AND monto = 150000 AND descripcion = 'CONTADORA PAGO MARZO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA PAGO MARZO', 150000, DATE '2026-04-27', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-05-23' AND monto = 150000 AND descripcion = 'CONTADORA PAGO ABRIL') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA PAGO ABRIL', 150000, DATE '2026-05-23', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-05-11' AND monto = 900000 AND descripcion = 'CONTADORA PAGO SIARA Y BALANCE') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA PAGO SIARA Y BALANCE', 900000, DATE '2026-05-11', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-06-12' AND monto = 500000 AND descripcion = 'GRAFICA BANNER') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'GRAFICA BANNER', 500000, DATE '2026-06-12', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-06-25' AND monto = 150000 AND descripcion = 'CONTADORA MES MAYO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA MES MAYO', 150000, DATE '2026-06-25', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-07-17' AND monto = 110000 AND descripcion = 'EVENTOS CE LAGOON BAR') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'EVENTOS CE LAGOON BAR', 110000, DATE '2026-07-17', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-07-28' AND monto = 150000 AND descripcion = 'CONTADORA PAGO JUNIO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA PAGO JUNIO', 150000, DATE '2026-07-28', 'General', 'historico');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.gastos
     WHERE empresa_id = v_empresa_id AND fecha = DATE '2026-08-27' AND monto = 150000 AND descripcion = 'CONTADORA PAGO JULIO') THEN
    INSERT INTO asociacionazulgranaerp.gastos
      (empresa_id, categoria, descripcion, monto, fecha, tipo, estado)
    VALUES (v_empresa_id, 'General', 'CONTADORA PAGO JULIO', 150000, DATE '2026-08-27', 'General', 'historico');
  END IF;

END $$;

SELECT
  (SELECT count(*) FROM asociacionazulgranaerp.facturas WHERE numero_factura LIKE 'INSCRIP-%') AS inscripciones,
  (SELECT sum(monto) FROM asociacionazulgranaerp.facturas WHERE numero_factura LIKE 'INSCRIP-%') AS inscripciones_gs,
  (SELECT count(*) FROM asociacionazulgranaerp.facturas WHERE numero_factura LIKE 'OTRA-%')    AS otras_entradas,
  (SELECT sum(monto) FROM asociacionazulgranaerp.facturas WHERE numero_factura LIKE 'OTRA-%')  AS otras_entradas_gs,
  (SELECT count(*) FROM asociacionazulgranaerp.gastos WHERE estado = 'historico')             AS gastos,
  (SELECT sum(monto) FROM asociacionazulgranaerp.gastos WHERE estado = 'historico')           AS gastos_gs;

COMMIT;
-- ROLLBACK;
