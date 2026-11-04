/**
 * Normaliza el prefijo del número de comprobante para mostrarlo uniforme
 * al usuario. Los registros cargados por el flujo legacy traen prefijo
 * CUOTA- (ej. CUOTA-56-202607) mientras que los del flujo actual traen
 * FAC- o HIST-. Para el usuario final son todos facturas de suscripción,
 * así que mostramos todo como FAC-* sin tocar el dato en base.
 *
 * Preserva el resto del identificador para no perder trazabilidad; el
 * backend sigue viendo el valor original cuando lo necesita (logs, SIFEN,
 * notificaciones).
 */
export function displayNumeroFactura(numero: string | null | undefined): string {
  if (!numero) return "";
  const s = String(numero).trim();
  if (s.startsWith("CUOTA-")) return "FAC-" + s.slice("CUOTA-".length);
  return s;
}
