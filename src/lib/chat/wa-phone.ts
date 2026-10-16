/** Solo dígitos, sin prefijo + */
export function normalizeWaPhone(waId: string): string {
  return waId.replace(/\D/g, "");
}

/**
 * Deja el número listo para WhatsApp (JID destino): dígitos con código de país,
 * SIN el + ni ceros a la izquierda. Pensado para Paraguay.
 *
 * A diferencia de `normalizeWaPhone` (que solo saca lo que no son dígitos), esta
 * corrige los números que un humano cargó a mano o que están guardados en la ficha
 * del socio, que suelen venir en formato local (0981…) o con un 0 de más pegado al
 * código de país (0595…). Si no se corrige, el puente manda a un número que no existe
 * y el mensaje NUNCA llega.
 *
 * Reglas:
 *   "0595973591022" → "595973591022"   (saca el 0 inicial sobrante antes del 595)
 *   "0981234567"    → "595981234567"   (local PY: saca el 0 y antepone 595)
 *   "981234567"     → "595981234567"   (móvil PY sin 0 ni código de país)
 *   "595981234567"  → "595981234567"   (ya estaba bien)
 *   "+595 981 234"  → "595981234"      (saca símbolos)
 * Números de otro país que ya vienen en formato internacional se dejan igual.
 */
export function toWaDigitsPy(raw: string): string {
  const d = (raw ?? "").replace(/\D/g, "");
  if (!d) return "";
  // Quita ceros a la izquierda: tanto el 0 del formato local (0981…) como el
  // 00 internacional o un 0 pegado por error delante del 595 (0595…).
  const s = d.replace(/^0+/, "");
  if (!s) return "";
  if (s.startsWith("595")) return s; // ya trae el código de país Paraguay
  if (/^9\d{8}$/.test(s)) return "595" + s; // móvil PY de 9 dígitos, sin código
  return s; // ya parece internacional de otro país: no lo tocamos
}
