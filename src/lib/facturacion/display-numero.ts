/**
 * Normaliza el prefijo del número de comprobante para mostrarlo uniforme
 * al usuario. Hay tres prefijos en la base por razones históricas:
 *   - FAC-*   (flujo actual del motor de facturación)
 *   - CUOTA-* (flujo legacy de carga de cuotas)
 *   - HIST-*  (migración histórica de pagos y cuotas previas)
 * Para el usuario final son todos facturas de suscripción, mostrar tres
 * formatos distintos en la misma lista confunde. Normalizamos todos a
 * FAC-* sin tocar el dato en base.
 *
 * Preserva el resto del identificador para no perder trazabilidad; el
 * backend sigue viendo el valor original cuando lo necesita (logs, SIFEN,
 * notificaciones).
 */
export function displayNumeroFactura(numero: string | null | undefined): string {
  if (!numero) return "";
  const s = String(numero).trim();
  if (s.startsWith("CUOTA-")) return "FAC-" + s.slice("CUOTA-".length);
  if (s.startsWith("HIST-"))  return "FAC-" + s.slice("HIST-".length);
  return s;
}
