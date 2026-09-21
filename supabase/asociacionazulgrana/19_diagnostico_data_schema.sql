-- =============================================================================
-- 19 - Diagnostico: donde vive nuestra empresa (id 498add65...) y con que
--      valor de `data_schema` en cada catalogo compartido de Supabase.
-- =============================================================================
-- Sintoma: "Could not find the table 'distribuidorajmerp.ayuda_categorias' in
-- the schema cache". El resolver de schema (fetchDataSchemaForEmpresaId) lee
-- `empresas.data_schema` con service role apuntando al schema APP_DB_SCHEMA
-- del env. En este deploy APP_DB_SCHEMA=asociacionazulgranaerp y el usuario
-- confirmo que asociacionazulgranaerp.empresas.data_schema esta en NULL.
--
-- Igual el runtime devuelve `distribuidorajmerp`. Sospecha: existe otra fila
-- de `empresas` en un catalogo compartido (`neura`, `zentra_erp`, `public`,
-- alguna fork como `mariacuevas`, etc.) con `data_schema='distribuidorajmerp'`
-- residuo del clonado de env de distribuidorajm.
--
-- Este script NO modifica nada. Solo LISTA en que schemas existe una tabla
-- `empresas` con nuestro id y con que valor de `data_schema`. Copiar el
-- resultado y compartirlo permite decidir donde limpiar (lo hace el 20).
-- =============================================================================

DO $$
DECLARE
  v_empresa_id constant uuid := '498add65-8616-412a-9ee7-d5d60adba136'::uuid;
  r            record;
  v_sql        text;
  v_val        text;
  v_exists     boolean;
BEGIN
  RAISE NOTICE '== Diagnostico data_schema para empresa % ==', v_empresa_id;

  FOR r IN
    SELECT n.nspname AS schema_name
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind IN ('r','p','v','m')
       AND c.relname = 'empresas'
       AND n.nspname NOT IN ('pg_catalog','information_schema')
     ORDER BY n.nspname
  LOOP
    -- Chequeo por columna data_schema (algunos catalogos no la tienen)
    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = r.schema_name
         AND table_name   = 'empresas'
         AND column_name  = 'data_schema'
    ) INTO v_exists;

    IF v_exists THEN
      v_sql := format(
        'SELECT COALESCE(data_schema::text, ''(NULL)'') FROM %I.empresas WHERE id = $1',
        r.schema_name
      );
      BEGIN
        EXECUTE v_sql INTO v_val USING v_empresa_id;
        IF v_val IS NULL THEN
          RAISE NOTICE '  [%] empresa NO existe (columna data_schema presente)', r.schema_name;
        ELSE
          RAISE NOTICE '  [%] data_schema = %', r.schema_name, v_val;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  [%] error leyendo: %', r.schema_name, SQLERRM;
      END;
    ELSE
      v_sql := format('SELECT ''existe (sin col data_schema)'' FROM %I.empresas WHERE id = $1 LIMIT 1', r.schema_name);
      BEGIN
        EXECUTE v_sql INTO v_val USING v_empresa_id;
        IF v_val IS NULL THEN
          RAISE NOTICE '  [%] empresa NO existe (sin columna data_schema)', r.schema_name;
        ELSE
          RAISE NOTICE '  [%] existe (sin columna data_schema)', r.schema_name;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  [%] error leyendo: %', r.schema_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  RAISE NOTICE '== Fin diagnostico ==';
END $$;

-- Resultado tabular para copiar/pegar
SELECT n.nspname AS schema_name,
       EXISTS (
         SELECT 1 FROM information_schema.columns
          WHERE table_schema = n.nspname
            AND table_name   = 'empresas'
            AND column_name  = 'data_schema'
       ) AS tiene_col_data_schema
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE c.relkind IN ('r','p','v','m')
   AND c.relname = 'empresas'
   AND n.nspname NOT IN ('pg_catalog','information_schema')
 ORDER BY n.nspname;
