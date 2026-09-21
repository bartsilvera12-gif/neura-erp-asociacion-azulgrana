import type { AppSupabaseClient } from "@/lib/supabase/schema";

/**
 * Calcula el siguiente N° de socio libre para la empresa: MAX(numero_socio) + 1
 * sobre `clientes` no eliminados. No busca huecos intermedios — por diseño el
 * comportamiento es "siguiente después del máximo" (predecible y consistente
 * con lo que ve el usuario en la lista).
 *
 * Si no hay socios registrados aún, arranca en 1.
 */
export async function calcularNextNumeroSocio(
  supabase: AppSupabaseClient,
  empresaId: string
): Promise<number> {
  const { data, error } = await supabase
    .from("clientes")
    .select("numero_socio")
    .eq("empresa_id", empresaId)
    .is("deleted_at", null)
    .not("numero_socio", "is", null)
    .order("numero_socio", { ascending: false })
    .limit(1);

  if (error) throw new Error(error.message);

  const row = (data ?? [])[0] as { numero_socio: number | string | null } | undefined;
  const raw = row?.numero_socio;
  if (raw == null) return 1;
  const n = typeof raw === "number" ? raw : parseInt(String(raw), 10);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) + 1 : 1;
}
