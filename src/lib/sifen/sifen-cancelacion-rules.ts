/**
 * Reglas de cancelación lógica del DE (SIFEN) en ERP.
 * El plazo se calcula desde `sifen_aprobado_at`, no desde la fecha comercial de la factura.
 */

export type SifenCancelacionContext = {
  estadoSifen: string | null;
  sifenAprobadoAtIso: string | null;
  sifenCanceladoAtIso: string | null;
  plazoHoras: number;
  pagosCount: number;
  /** Instantánea de referencia (servidor); tests pueden fijarla. */
  nowMs: number;
  /** Estado del envio del Evento de Cancelacion a SET (null | enviado | aprobado | rechazado). */
  setCancelacionEstado?: string | null;
};

export type SifenCancelacionPreview = {
  puede_cancelar: boolean;
  /** Fecha/hora límite inclusive del plazo (ISO UTC). */
  cancelable_hasta: string | null;
  motivo_bloqueo: string | null;
  requiere_nota_credito: boolean;
  tiene_pagos: boolean;
  plazo_horas: number;
  /** True si se puede intentar el envio del Evento de Cancelacion a SET
   *  (DE aprobado o pseudo-cancelado en ERP, dentro de las 48h, sin
   *  cancelacion SET previamente aprobada). */
  puede_cancelar_set: boolean;
  /** Estado del envio SET (null si nunca se intento). */
  set_cancelacion_estado: string | null;
  /** True si el plazo SET ya expiró y hay que ir por Nota de Credito. */
  plazo_set_expirado: boolean;
};

function parseMs(iso: string | null): number | null {
  if (iso == null || String(iso).trim() === "") return null;
  const t = Date.parse(String(iso));
  return Number.isFinite(t) ? t : null;
}

/** Si la config no trae valor válido, coincide con default en BD (48). */
export function normalizePlazoCancelacionHoras(raw: unknown): number {
  const n = typeof raw === "number" ? raw : Number(raw);
  if (!Number.isFinite(n)) return 48;
  const h = Math.floor(n);
  if (h < 1) return 1;
  if (h > 8760) return 8760;
  return h;
}

export function buildSifenCancelacionPreview(ctx: SifenCancelacionContext): SifenCancelacionPreview {
  const estado = ctx.estadoSifen == null ? "" : String(ctx.estadoSifen).trim();
  const plazo_horas = normalizePlazoCancelacionHoras(ctx.plazoHoras);
  const tiene_pagos = ctx.pagosCount > 0;
  const setEstado = (ctx.setCancelacionEstado ?? "").trim() || null;
  const aprobadoMs = parseMs(ctx.sifenAprobadoAtIso);

  // Flags derivados comunes
  const limiteMs = aprobadoMs != null ? aprobadoMs + plazo_horas * 60 * 60 * 1000 : null;
  const cancelable_hasta = limiteMs != null ? new Date(limiteMs).toISOString() : null;
  const dentroPlazo = limiteMs != null && ctx.nowMs <= limiteMs;
  const plazo_set_expirado = limiteMs != null && ctx.nowMs > limiteMs;

  // `puede_cancelar_set`: podemos intentar enviar el Evento a SET si
  //   - el DE fue aprobado por SET (hay aprobado_at)
  //   - estado 'aprobado' o 'cancelado' en ERP (la pseudo-cancelacion no bloquea)
  //   - aun dentro del plazo
  //   - no se aprobó una cancelacion SET antes
  const puede_cancelar_set =
    aprobadoMs != null &&
    (estado === "aprobado" || estado === "cancelado") &&
    dentroPlazo &&
    setEstado !== "aprobado";

  if (estado === "cancelado" || ctx.sifenCanceladoAtIso) {
    return {
      puede_cancelar: false,
      cancelable_hasta,
      motivo_bloqueo:
        setEstado === "aprobado"
          ? "El documento ya fue cancelado en SET."
          : "El documento electrónico ya fue cancelado en el ERP.",
      requiere_nota_credito: plazo_set_expirado && setEstado !== "aprobado",
      tiene_pagos,
      plazo_horas,
      puede_cancelar_set,
      set_cancelacion_estado: setEstado,
      plazo_set_expirado,
    };
  }

  if (estado !== "aprobado") {
    return {
      puede_cancelar: false,
      cancelable_hasta: null,
      motivo_bloqueo: "Solo se puede cancelar un DE en estado «aprobado» por SET.",
      requiere_nota_credito: false,
      tiene_pagos,
      plazo_horas,
      puede_cancelar_set: false,
      set_cancelacion_estado: setEstado,
      plazo_set_expirado: false,
    };
  }

  if (aprobadoMs == null) {
    return {
      puede_cancelar: false,
      cancelable_hasta: null,
      motivo_bloqueo:
        "No hay marca de aprobación SET (sifen_aprobado_at). Ejecute «Consultar lote SET» para sincronizar el estado.",
      requiere_nota_credito: true,
      tiene_pagos,
      plazo_horas,
      puede_cancelar_set: false,
      set_cancelacion_estado: setEstado,
      plazo_set_expirado: false,
    };
  }

  if (tiene_pagos) {
    return {
      puede_cancelar: false,
      cancelable_hasta,
      motivo_bloqueo: "La factura tiene pagos registrados; no aplica cancelación del DE en ventana corta.",
      requiere_nota_credito: true,
      tiene_pagos,
      plazo_horas,
      puede_cancelar_set,
      set_cancelacion_estado: setEstado,
      plazo_set_expirado,
    };
  }

  if (plazo_set_expirado) {
    return {
      puede_cancelar: false,
      cancelable_hasta,
      motivo_bloqueo: "Venció el plazo de cancelación desde la aprobación SET.",
      requiere_nota_credito: true,
      tiene_pagos,
      plazo_horas,
      puede_cancelar_set: false,
      set_cancelacion_estado: setEstado,
      plazo_set_expirado: true,
    };
  }

  return {
    puede_cancelar: true,
    cancelable_hasta,
    motivo_bloqueo: null,
    requiere_nota_credito: false,
    tiene_pagos,
    plazo_horas,
    puede_cancelar_set,
    set_cancelacion_estado: setEstado,
    plazo_set_expirado: false,
  };
}
