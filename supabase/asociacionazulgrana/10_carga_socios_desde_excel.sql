-- =============================================================================
-- 10 · CARGA INICIAL DE SOCIOS desde el Excel del cliente
-- =============================================================================
-- Fuente: "ASOCIACION - HERNANDARIAS AZULGRANA.xlsx" hoja "DATOS DE SOCIOS".
-- Carga 79 filas: los 68 socios con datos + los 11 huecos numerados reservados.
--
-- Los huecos entran como cliente con:
--   · numero_socio = N° del Excel
--   · nombre_contacto = 'Reservado'
--   · tipo_socio = 'RESERVADO', estado='inactivo'
-- Todos los demás campos NULL. Se completan editando el cliente en la UI.
--
-- Agrega antes las columnas numero_socio y tipo_socio a la tabla clientes.
-- Idempotente: matchea por (empresa_id, numero_socio); si ya existe, NO reemplaza
-- (no queremos pisar ediciones hechas desde la UI).
-- =============================================================================

ALTER TABLE asociacionazulgranaerp.clientes ADD COLUMN IF NOT EXISTS numero_socio integer;
ALTER TABLE asociacionazulgranaerp.clientes ADD COLUMN IF NOT EXISTS tipo_socio text;
CREATE UNIQUE INDEX IF NOT EXISTS clientes_empresa_numero_socio_key
  ON asociacionazulgranaerp.clientes (empresa_id, numero_socio) WHERE numero_socio IS NOT NULL;

DO $carga$
DECLARE
  v_empresa_id uuid := '498add65-8616-412a-9ee7-d5d60adba136';
  v_n_insertados int := 0;
  v_n_existentes int := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'asociacionazulgranaerp') THEN
    RAISE EXCEPTION 'falta el schema asociacionazulgranaerp — corré antes 01_clonar_schema.sql';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 1) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 1, 'SOCIO FUNDADOR', 'RUBEN ANTONIO FRANCO', '1666587', '0973-591 022', 'ruben.franco01/@gmail.com', 'GRAL. GENES C/CURUPAYTY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1972-02-17","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 2) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 2, 'SOCIO FUNDADOR', 'ANDRES ROA FARIÑA', '2862351', '0985-734039', NULL, 'AREA 6', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1986-01-31","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 3) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 3, 'SOCIO FUNDADOR', 'DOMINGO DAMIAN GONZALEZ BENTIEZ', '4505390', '0973-419281', 'mingui_damian@hotmail.com', 'MCAL LOPEZ C/ GRAL BRUGUEZ', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1988-04-03","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 4) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 4, 'SOCIO FUNDADOR', 'FERNANDO JAVIER CHAMORRO', '6224272', '0973-507299', 'ferchu.stefi@gmail.com', 'AVDA KAÁ', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1989-04-23","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 5) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 5, 'SOCIO FUNDADOR', 'JOSE HORACIO LOPEZ NUARTE', '3393276', '0971-976697', 'joselopezjl.jl836@gmail.com', 'AVDA CALLE 1 C/ PETROPAR', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-06-20","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 6) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 6, 'SOCIO FUNDADOR', 'ANDRES DAVID GONZALEZ DIAZ', '4750077', '0994-994147', 'davicho02@gmail.com', 'AVDA KAÁ', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1988-01-21","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-30","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 7) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 7, 'SOCIO FUNDADOR', 'REINERIO RODRIGO AGÜERO BENITEZ', '3386300', '0991-230458', 'rodrygoaguero1@gmail.com', 'BARRIO PUERTA DEL SOL', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1992-06-30","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 8) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 8, 'SOCIO FUNDADOR', 'ALCIDES BARRIOS', '1814000', '0983-666004', 'alcidesbarrios64@gmail.com', 'GRAL. AQUINO C/CURUPAYTY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1965-03-27","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 9) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 9, 'SOCIO FUNDADOR', 'JAVIER WALDEMAR ROTELA ROCHEMBACH', '5509294', '0973-514284', 'rochembachjavi@gmail.com', 'BELLA VISTA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1993-03-04","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 10) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 10, 'SOCIO FUNDADOR', 'RICHARD ROLON', '3182969', '0982-587454', 'richard_rolon1987@hotmail.com', 'BARRIO FATIMA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1987-11-20","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-10-31","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 11) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 11, 'SOCIO FUNDADOR', 'ELVIS GABRIEL MARCIANO CAÑIZA ARZAMENDIA', '6234349', '0993-294897', 'somacontabilidad@outlook.com', 'PUERTA DEL SOL', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1998-08-14","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 12) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 12, 'SOCIO FUNDADOR', 'DIEGO ARMANDO GARCIA', '5015773', '0973-159468', 'universo_diegogarcia@hotmail.com', 'PUERTA DEL SOL', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1990-04-27","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 13) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 13, 'SOCIO FUNDADOR', 'PABLO CESAR FERNANDEZ DUARTE', '3747032', '0983-911610', 'pablofernandez.pf67@gmail.com', 'MARISCAL LOPEZ', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1986-07-11","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-20","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 14) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 14, 'SOCIO FUNDADOR', 'DERLIS GABRIEL TORALES PANIAGUA', '4673714', '0973-201970', 'derlis.torales92@gmail.com', 'CALLE BOLIVIA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1992-10-23","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-20","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 15) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 15, 'SOCIO FUNDADOR', 'FREDDY RICARDO MORAL DUARTE', '4843187', '0973-538267', 'frm267@gmail.com', 'RUTA PY VII C/CNEL.BOGADO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1989-07-06","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-14","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 16) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 16, 'SOCIO FUNDADOR', 'ISAAC ROA FARIÑA', '2862352', '0973-234639', 'isaac.roafa2@gmail.com', 'FELIX DE AZARA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1981-01-08","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-21","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 17) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 17, 'SOCIO FUNDADOR', 'JUAN MARCELO ARCE LOPEZ', '3924193', '0983-256474', 'arpez721@gmail.com', 'PARAGUARI Y PRO.DE MARZO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1992-07-21","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-20","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 18) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 18, 'SOCIO FUNDADOR', 'PEDRO ALCIDES ROLON ALONZO', '3182968', '0973-400889', 'rolonalcides@hotmail.com', 'SUPER CARRETERA C/JUAN EOLEARY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-06-21","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-24","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 19) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 19, 'SOCIO FUNDADOR', 'MILNER GUSTAVO BRIZUELA', '4736360', '0994-268928', 'brizuelamilner@gmail.com', 'HERNANDARIAS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1989-04-30","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-25","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 20) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 20, 'SOCIO FUNDADOR', 'WILSON MEDINA GAVILAN', '3744066', '0983-420937', 'wilmedina1989@gmal.com', 'JUAN B.FLORES E/AQUIDABAN', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1989-06-30","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 21) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 21, 'SOCIO FUNDADOR', 'MILCIADES SOSA MARTINEZ', '2891129', '0983-554456', 'milciadessm@gmail.com', 'HONDURAS C/MEJICO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1979-06-02","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 22) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 22, 'SOCIO FUNDADOR', 'JORGE MERCEDES PEREZ CABRAL', '3829630', '0973-548212', 'jperezcabral@gmail.com', 'TAJY C/FULGENCIO YEGROS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1983-09-24","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 23) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 23, 'SOCIO FUNDADOR', 'RAFAEL ANDERSON WIRSCHKE MONGES', '5321275', '0973-632571', 'rafael_monges@hotmail.com', 'JUAN EOLEARY C/SUPERCARRETERA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1987-09-29","fecha":"2026-09-16T12:10:12.849Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-02","fecha":"2026-09-16T12:10:12.849Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 24) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 24, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 25) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 25, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 26) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 26, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 27) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 27, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 28) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 28, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 29) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 29, 'ACTIVO', 'RUBEN EDUARDO FRANCO MARTINEZ', '5463072', '0975-823787', 'rubenfrancoaa@gmail.com', 'GRAL.GENES C/CURUPAYTY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1993-05-07","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 30) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 30, 'ACTIVO', 'FERNANDO JAVIER CUMBAI BOGARIN', '2270726', '0973-874336', 'fjcumbai2509@gmail.com', 'PARAGUARI C/EL MENSU', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1987-09-29","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 31) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 31, 'ACTIVO', 'RONALD ADOLFO HOBECKER GOMEZ', '5145125', '0985-266380', 'hobeckerronald@gmail.com', 'BAHAMAS Y GRANADA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-01-15","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 32) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 32, 'ACTIVO', 'VICTOR DANIEL FRANCO VERON', '3854698', '0973-589167', 'victfranco83@hotmail.com', 'BARRIO PUERTA DEL SOL', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1983-07-19","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-01","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 33) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 33, 'ACTIVO', 'WILMAR LORENZO TORALES PANIAGUA', '2538064', '0973-606602', 'wilmar.torales88@gmail.com', 'CHILE C/BAHAMAS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1988-08-10","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-14","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 34) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 34, 'ACTIVO', 'CESAR DAVID PALMA CHAMORRO', '5264647', '0973-507299', NULL, 'PUERTA DEL SOL', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1986-06-23","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-11","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 35) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 35, 'ACTIVO', 'OMAR ARIEL BURGOS PASTER', '1348947', '0973-536204', 'burgospaster@hotmail.com', 'MONTE LINDO AREA 5', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1982-01-02","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-14","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 36) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 36, 'ACTIVO', 'JESUS MANUEL ARGUELLO ALARCON', '2339957', '0984-708419', 'arguelloyalarcon.py@gmail.com', 'PUERTO RICO Y DOMINICANA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1986-10-16","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-14","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 37) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 37, 'ACTIVO', 'FELIPE CARBALLO DUARTE', '3990447', '0992-508752', 'fcarballo659@gmail.com', 'LAS AMERICAS AREA 6', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1984-04-07","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-19","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 38) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 38, 'ACTIVO', 'FERNANDO EFIGENIO CACERES SERVIAN', '3987895', '0982-715366', 'fercaserv@gmail.com', 'AV. JUAN B.FLORES C/TUYUTI', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1984-09-30","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 39) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 39, 'ACTIVO', 'DIEGO DANIEL ROTELA ROCHEMBACH', '4242010', '0975-557571', 'danirote2016@gmail.com', 'BARRIO FATIMA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1989-06-22","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 40) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 40, 'ACTIVO', 'CRISTHIAN OSMAR GERDING ESPINOLA', '3543718', '0973-668436', 'killogerding@gmail.com', 'VILLARRICA C/SALTO DEL GUAIRA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1980-06-22","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-21","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 41) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 41, 'ACTIVO', 'ROLANDO JAVIER CACERES SANABRIA', '4345556', '0973-438780', 'rolycaceres77@gmail.com', 'CUBA Y CANADA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-09-18","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-14","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 42) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 42, 'ACTIVO', 'VICTOR ANTONIO VELAZQUEZ', '4828219', '0986-707282', 'velazquezvictor21442@gmail.com', 'TRIGAL III', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1988-12-08","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-26","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 43) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 43, 'ACTIVO', 'JOSE MARIA ROLON LOPEZ', '3915330', '0973-595366', 'josemrolon@hotmail.com', 'CALLE TACURU PUCU', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1990-12-26","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 44) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 44, 'ACTIVO', 'PEDRO GUZMAN ROTELA ROCHEMBACH', '4242011', '0973-506358', NULL, 'EL MENSU', 'Hernandarias', 'Paraguay', 'GS', '[{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 45) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 45, 'ACTIVO', 'LAURA ANTONELA FRANCO MARTINEZ', '5463003', '0973-655427', 'laurafranco.contable@gmail.com', 'GRAL.GENES C/CURUPAYTY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 2000-12-05","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 46) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 46, 'ACTIVO', 'FERNANDO FRANCO ARZAMENDIA', '5267220', '0983-400682', 'ferfrancoarza@gmail.com', 'CESAR GIANOTTI C/FDO.DE LA MORA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1994-01-09","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 47) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 47, 'ACTIVO', 'JONATHAN CESAR FRANCO ARZAMENDIA', '6608528', '0972-793505', NULL, 'CESAR GIANOTTI C/FDO.DE LA MORA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 2002-01-16","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 48) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 48, 'ACTIVO', 'DENIS IRAN ORTIZ DE OLIVEIRA', '3871219', '0974-689311', NULL, 'AV. MARISCAL LOPEZ', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1987-09-29","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 49) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 49, 'ACTIVO', 'RAMON DARIO ACOSTA GARCETE', '4284398', '0985-864367', 'da918170@gmail.com', 'ANTEQUERA C/PRO.DE MARZO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 50) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 50, 'ACTIVO', 'ALFREDO RAMON LOMAQUIZ ESCALANTE', '1880046', '0983-614372', 'gtalomaquiz@hotmail.com', 'NICARAGUA C/GUYANA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1973-03-23","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-28","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 51) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 51, 'ACTIVO', 'OVIDIO RAMON ANTONIO REYES ASCONA', '3834229', '0993-588704', 'ovidioreyes1993@gmail.com', 'BARRIO LAS AMERICAS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1993-06-13","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-28","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 52) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 52, 'ACTIVO', 'VANNIA MARIA MARTINEZ VILLAR', '2926617', '0973-140534', 'vanniamariamartinez@gmail.com', 'MCAL. ESTIGARRIBIA GRAL. GENES', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1980-01-18","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-29","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 53) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 53, 'ACTIVO', 'JUAN LORENZO VELOTTO GONZALEZ', '2173451', '0973-502050', 'juanbelts@gmail.com', 'DR. RAMON AGÜERO SOSA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1975-08-10","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-01","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 54) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 54, 'ACTIVO', 'RICHARD SEBASTIAN CHAMORRO', '5470653', '0975-169597', 'richardluciaestefy.6915@gmail.com', 'TRIGAL III', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1986-08-03","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 55) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 55, 'ACTIVO', 'ADALIZ MAKHARENA SACHELARIDI', '5210517', '0973-419674', 'makha.sache92@gmail.com', 'AQUIDABAN', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1992-08-06","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-02","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 56) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 56, 'ACTIVO', 'DENIS MARCELO VILLALBA LEGUIZAMÓN', '4615252', '0972-237902', 'denis.villalba92@gmail.com', 'CAACUPEMI', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1992-06-19","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-02","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 57) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 57, 'ACTIVO', 'RONALD ARSENIO PENAYO ULDERA', '4881074', '0973-632402', 'ronaldarsenio@icloud.com', 'AVDA EL MENSU C/ ITURBE', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-07-27","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-11-27","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 58) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 58, 'ACTIVO', 'CRISTHIAN GONZÁLEZ CARDOZO', '4164028', '0983-918704', 'cgcz918@gmail.com', 'AVDA MONDAY C/ BOQUERON', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1994-12-20","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-03","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 59) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 59, 'ACTIVO', 'HUGO FRANCISCO CENTURION ESQUIVEL', '4937785', '0986-562543', 'hugomtk.ventas@gmail.com', 'HAITI 358', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-06-01","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-03","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 60) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 60, 'ACTIVO', 'JUAN ANGEL GOMEZ ORREGO', '3801565', '0983-074009', 'gereorrego88@hotmail.com', 'PALO SANTO C/ YVYRA PYTA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1984-04-13","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-03","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 61) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 61, 'ACTIVO', 'DERLIS ARMANDO SAMUDIO VALDEZ', '4707297', '0983-877154', 'samudioderlis060@gmail.com', 'KM 11 ACARAY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1985-11-01","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-05","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 62) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 62, 'ACTIVO', 'RAUL ANTONIO WEIMBERG ESCURRA', '4391131', '0973-501420', 'raulweimberg16@gmail.com', 'BARRIO SANTO DOMINGO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-12-30","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-09","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 63) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 63, 'ACTIVO', 'CARLOS DAVID BALMACEDA LAGRAVE', '3188872', '0983-626999', 'carlos.dbalmacedas@gmail.com', 'CALLE BAHAMAS 272', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1980-03-01","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-15","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 64) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 64, 'ACTIVO', 'CHRISTIAN ESTEBAN LUGO SAMANIEGO', '1283567', '0983-747696', 'celugsam@gmail.com', 'ARGENTINA C/ JAMAICA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1968-08-03","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-18","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 65) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 65, 'ACTIVO', 'JAVIER CRIPIN VILLALBA LEGUIZAMON', '4543331', '0972-648285', 'xavier.villalba13@gmail.com', 'CALLE MARACANA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-03-31","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 66) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 66, 'ACTIVO', 'BERNARDO BRITEZ PAREDES', '5899143', '0973-656472', 'consultoriafernandez1234@gmail.com', 'KM 13 ACARAY', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1991-11-16","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2025-12-24","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 67) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 67, 'ACTIVO', 'FEDERICO KENNEDY GIMENEZ', '3927297', '0973-127150', 'fedekenedy@gmail.com', 'HERNANDARIAS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1994-04-25","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-01-21","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 68) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 68, 'ACTIVO', 'ALEJANDRO MEZA BENITEZ', '5465488', '0972-472815', 'walmez93@gmail.com', 'HERNANDARIAS', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1993-03-20","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-01-28","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 69) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 69, 'ACTIVO', 'RENEE HERMINIO ARANDA CANTERO', '4242028', '0973-692628', 'r3n33harandac@gmail.com', 'BARRIO SAN ANTONIO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1987-08-18","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-01-30","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 70) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 70, 'ACTIVO', 'HUGO CESAR FRANCO', '2936588', '0993-422789', 'hugofranco9452@gmail.com', 'BARRIO FATIMA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1977-04-28","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-07-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 71) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 71, 'ACTIVO', 'VICTOR ANTONIO ALVAREZ ULLON', '4030726', '0973-665040', 'victoraau84@gmail.com', 'JAMAICA C/GUYANA', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1985-01-07","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-07-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 72) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 72, 'ACTIVO', 'CARLOS ELIAS BENITEZ CABELLO', '2947551', '0973-561842', 'deklema33@gmail.com', 'LAS AMERICAS AREA 6', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1984-04-28","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-07-20","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 73) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 73, 'ACTIVO', 'JUAN MANUEL AZUAGA', '2050853', '0985-462810', 'juanmanuelazu@gmail.com', 'HAITI C/MEJICO', 'Hernandarias', 'Paraguay', 'GS', '[{"id":1,"texto":"Fecha de nacimiento: 1974-03-17","fecha":"2026-09-16T12:10:12.850Z"},{"id":2,"texto":"Fecha de ingreso a la asociación: 2026-08-06","fecha":"2026-09-16T12:10:12.850Z"}]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 74) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 74, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 75) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 75, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 76) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 76, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 77) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 77, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 78) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 78, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asociacionazulgranaerp.clientes WHERE empresa_id = v_empresa_id AND numero_socio = 79) THEN
    INSERT INTO asociacionazulgranaerp.clientes (id, empresa_id, tipo_cliente, origen, estado, numero_socio, tipo_socio, nombre_contacto, documento, telefono, email, direccion, ciudad, pais, moneda_preferida, notas, created_at, updated_at) VALUES (gen_random_uuid(), v_empresa_id, 'persona', 'MANUAL', 'activo', 79, 'RESERVADO', 'Reservado', NULL, NULL, NULL, NULL, 'Hernandarias', 'Paraguay', 'GS', '[]'::jsonb, now(), now());
    v_n_insertados := v_n_insertados + 1;
  ELSE
    v_n_existentes := v_n_existentes + 1;
  END IF;

  RAISE NOTICE 'socios: % insertados, % ya existían (no se pisan)', v_n_insertados, v_n_existentes;
  PERFORM pg_notify('pgrst', 'reload schema');
END;
$carga$;

-- Resultado
SELECT numero_socio, tipo_socio, estado, nombre_contacto, documento, telefono, email
FROM asociacionazulgranaerp.clientes
WHERE empresa_id = '498add65-8616-412a-9ee7-d5d60adba136' AND numero_socio IS NOT NULL
ORDER BY numero_socio;
