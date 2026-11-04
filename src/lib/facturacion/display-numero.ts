/**
 * Normaliza el prefijo del número de comprobante para mostrarlo uniforme
 * al usuario. Hay varios prefijos en la base por razones históricas:
 *   - FAC-*     (flujo actual del motor de facturación)
 *   - CUOTA-*   (flujo legacy de carga de cuotas)
 *   - HIST-*    (migración histórica de pagos y cuotas previas)
 *   - INSCRIP-* (inscripciones migradas)
 *   - INSC-*    (inscripciones variante)
 * Para el usuario final son todos facturas (o cuotas de suscripción),
 * mostrar prefijos distintos en la misma lista confunde. Normalizamos
 * todos a FAC-* sin tocar el dato en base.
 *
 * Preserva el resto del identificador para no perder trazabilidad; el
 * backend sigue viendo el valor original cuando lo necesita (logs, SIFEN,
 * notificaciones).
 */
const LEGACY_PREFIXES = ["CUOTA-", "HIST-", "INSCRIP-", "INSC-"];

export function displayNumeroFactura(numero: string | null | undefined): string {
  if (!numero) return "";
  const s = String(numero).trim();
  for (const pfx of LEGACY_PREFIXES) {
    if (s.startsWith(pfx)) return "FAC-" + s.slice(pfx.length);
  }
  return s;
}
