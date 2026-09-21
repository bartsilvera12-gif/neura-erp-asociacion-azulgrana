-- =============================================================================
-- 17 · Fix del índice único de numero_socio (soft-delete aware)
-- =============================================================================
-- Sintoma: al crear un cliente con N° de socio X, borrarlo desde la UI, y
-- volver a crear otro cliente con el mismo N° X, tira
-- "Ya hay otro cliente registrado con este N° de socio" — a pesar de que el
-- primero ya fue eliminado.
--
-- Causa: los clientes se borran con soft-delete (deleted_at IS NOT NULL, la fila
-- sigue en la tabla). El índice único parcial que puso el script 10 no
-- discriminaba entre borrados y activos, entonces el N° quedaba "ocupado"
-- por el registro fantasma para siempre.
--
-- Fix: recrear el índice único parcial excluyendo también los soft-deleted.
--
-- Idempotente y no destructivo.
-- =============================================================================

DROP INDEX IF EXISTS asociacionazulgranaerp.clientes_empresa_numero_socio_key;

CREATE UNIQUE INDEX IF NOT EXISTS clientes_empresa_numero_socio_key
  ON asociacionazulgranaerp.clientes (empresa_id, numero_socio)
  WHERE numero_socio IS NOT NULL
    AND deleted_at IS NULL;

NOTIFY pgrst, 'reload schema';

-- Verificacion: la definicion nueva debe incluir "deleted_at IS NULL" en el predicado
SELECT indexdef
FROM pg_indexes
WHERE schemaname = 'asociacionazulgranaerp'
  AND indexname  = 'clientes_empresa_numero_socio_key';
