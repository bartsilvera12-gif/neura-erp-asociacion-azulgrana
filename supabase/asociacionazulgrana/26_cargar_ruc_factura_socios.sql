-- =============================================================================
-- 26 · CARGA EN LOTE del RUC de factura de los socios (desde Excel)
-- =============================================================================
-- Rellena `clientes.ruc_factura` (el RUC contra el que se emite la factura SIFEN)
-- para los socios que ya tienen RUC. Cada socio se identifica por su N° de socio.
--
-- ───────────────────────────── CÓMO USARLO ──────────────────────────────────
--   1) En tu Excel armá DOS columnas:  N° de socio  |  RUC
--         - El RUC va con guión y dígito verificador. Ej.: 80012345-6
--   2) Copiá esos pares acá abajo, dentro del bloque VALUES, uno por línea:
--
--            (29, '80012345-6'),
--            (31, '1234567-8'),
--            (33, '4505390-7')      <-- la ÚLTIMA línea SIN coma al final
--
--         - El número de socio va SIN comillas.
--         - El RUC va ENTRE comillas simples '...'.
--   3) Reemplazá las filas de ejemplo (dicen REEMPLAZAME) por las tuyas.
--   4) Pegá todo el archivo en el SQL Editor de Supabase y dale RUN.
--
--   Al final te muestra dos tablas:
--      · "actualizados"      → los socios que quedaron con su RUC cargado.
--      · "no_encontrados"    → N° de socio que pusiste pero que no existe (revisar).
--
-- Es idempotente y seguro: podés correrlo las veces que quieras; solo toca los
-- socios que estén en tu lista (al resto no los toca). Si todavía están las filas
-- de ejemplo, se detiene y te avisa (no escribe nada).
-- =============================================================================

BEGIN;

-- Lista temporal con tus datos (se borra sola al terminar).
CREATE TEMP TABLE _ruc_socios (numero_socio int, ruc text) ON COMMIT DROP;

INSERT INTO _ruc_socios (numero_socio, ruc) VALUES
  -- ░░░░░░░░░░░░░░ PEGÁ ACÁ TUS DATOS (N° socio, RUC) ░░░░░░░░░░░░░░
  (29, 'REEMPLAZAME'),
  (31, 'REEMPLAZAME')
  -- ░░░░░░░░░░░░░░░░░░░░░ FIN DE TUS DATOS ░░░░░░░░░░░░░░░░░░░░░░░░░
;

-- ── Freno de seguridad: si no reemplazaste el ejemplo, aborta sin tocar nada ──
DO $guard$
BEGIN
  IF EXISTS (SELECT 1 FROM _ruc_socios WHERE upper(ruc) = 'REEMPLAZAME') THEN
    RAISE EXCEPTION 'Todavía están las filas de EJEMPLO. Reemplazá el bloque VALUES por tus socios y RUC reales, y volvé a correr.';
  END IF;
END $guard$;

-- ── Normalizar el RUC: deja solo dígitos y un guión (saca puntos, espacios) ──
UPDATE _ruc_socios
  SET ruc = regexp_replace(btrim(ruc), '[^0-9-]', '', 'g');

-- ── Validar formato RUC (dígitos + guión + dígito verificador). Si hay alguno
--    mal escrito, aborta y te dice cuáles, sin escribir nada. ──
DO $valida$
DECLARE
  v_malos text;
BEGIN
  SELECT string_agg(format('socio %s → "%s"', numero_socio, ruc), ', ')
    INTO v_malos
  FROM _ruc_socios
  WHERE ruc !~ '^[0-9]{3,8}-[0-9]$';

  IF v_malos IS NOT NULL THEN
    RAISE EXCEPTION 'RUC con formato inválido (esperado: dígitos-DV, ej. 80012345-6): %', v_malos;
  END IF;
END $valida$;

-- ── Aplicar: carga el ruc_factura de cada socio de la lista ──
UPDATE asociacionazulgranaerp.clientes AS c
   SET ruc_factura = s.ruc,
       updated_at  = now()
  FROM _ruc_socios AS s
 WHERE c.empresa_id   = '498add65-8616-412a-9ee7-d5d60adba136'
   AND c.numero_socio = s.numero_socio;

-- ── Resultado: una fila por cada socio de tu lista, con su estado ──
--    estado = "cargado OK"  → quedó con el RUC.
--    estado = "NO EXISTE..." → ese N° de socio no está en el sistema (revisar el Excel).
SELECT s.numero_socio,
       c.nombre_contacto,
       c.documento   AS cedula,
       s.ruc         AS ruc_de_tu_lista,
       CASE WHEN c.id IS NULL THEN 'NO EXISTE ese N° de socio'
            ELSE 'cargado OK' END AS estado,
       c.ruc_factura AS ruc_guardado
  FROM _ruc_socios AS s
  LEFT JOIN asociacionazulgranaerp.clientes AS c
    ON c.empresa_id   = '498add65-8616-412a-9ee7-d5d60adba136'
   AND c.numero_socio = s.numero_socio
 ORDER BY s.numero_socio;

COMMIT;
