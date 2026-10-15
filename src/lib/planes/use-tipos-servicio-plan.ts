"use client";

import { useEffect, useMemo, useState } from "react";
import type { FancySelectOption } from "@/app/dashboard/proyectos/components/FancySelect";
import { fetchTiposFormCliente } from "@/lib/clientes/fetch-tipos-servicio-form";
import type { ClienteTipoServicioRow } from "@/lib/clientes/tipo-servicio-catalogo";

/**
 * Carga el catálogo de tipos de servicio del tenant (activos) para usarlos como
 * opciones de un `FancySelect`. Reutiliza `GET /api/cliente-tipos-servicio?form=1`
 * (mismo origen que el selector de tipo de servicio en Clientes).
 *
 * `includeSlug` suma el tipo actual aunque esté inactivo o fuera del catálogo base
 * (útil al editar un plan que ya tiene un slug): así la opción elegida nunca
 * aparece en blanco.
 */
export function useTiposServicioPlan(includeSlug?: string | null): {
  options: FancySelectOption[];
  loading: boolean;
} {
  const [filas, setFilas] = useState<ClienteTipoServicioRow[]>([]);
  const [loading, setLoading] = useState(true);
  const slug = (includeSlug ?? "").trim().toLowerCase();

  useEffect(() => {
    let cancel = false;
    fetchTiposFormCliente(slug || undefined)
      .then((rows) => {
        if (!cancel) setFilas(rows);
      })
      .finally(() => {
        if (!cancel) setLoading(false);
      });
    return () => {
      cancel = true;
    };
  }, [slug]);

  const options = useMemo<FancySelectOption[]>(
    () => filas.map((r) => ({ value: r.slug, label: r.nombre })),
    [filas]
  );

  return { options, loading };
}
