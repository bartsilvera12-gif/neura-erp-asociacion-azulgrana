/**
 * Validadores compartidos entre los forms de cliente (Nuevo/Detalle) y las rutas
 * de API (POST/PATCH). Mantienen las reglas simétricas: si la UI bloquea un
 * valor, la API también lo rechaza y viceversa. Todas las funciones devuelven
 * `null` cuando el valor es aceptable, o un mensaje de error humano en español.
 */

// Nombres, razón social, contacto: letras (con tildes/ñ), espacios,
// apóstrofes y guiones. Bloquea números y caracteres extraños.
export const RE_NOMBRE = /^[A-Za-zÀ-ÿñÑ'\-\s.]+$/;

/** Solo dígitos, o 6-8 dígitos + guión + un dígito verificador (RUC PY). */
export const RE_RUC = /^\d{6,8}(-\d)?$/;

/** RUC de empresa: 8 dígitos, con o sin guión-dígito verificador. */
export const RE_RUC_EMPRESA = /^\d{8}(-\d)?$/;

export const RE_EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** Teléfono: dígitos, espacios, guiones, +, paréntesis. 7-25 chars visibles. */
export const RE_TELEFONO = /^\+?[\d\s\-()]{7,25}$/;

/** Sitio web: http/https opcional pero dominio con TLD requerido. */
export const RE_SITIO_WEB = /^(https?:\/\/)?[\w-]+(\.[\w-]+)+([/?#].*)?$/i;

/** Número de socio: entero positivo. */
export const RE_NUMERO_SOCIO = /^[1-9]\d*$/;

export function validarNombre(v: string | null | undefined, campo = "El nombre"): string | null {
  const s = (v ?? "").trim();
  if (!s) return null;
  if (/\d/.test(s)) return `${campo} no puede contener números.`;
  if (!RE_NOMBRE.test(s)) return `${campo} solo puede contener letras, espacios, apóstrofes o guiones.`;
  return null;
}

export function validarRuc(v: string | null | undefined, tipo: "empresa" | "persona" = "empresa"): string | null {
  const s = (v ?? "").trim();
  if (!s) return null;
  if (!/^[\d-]+$/.test(s)) {
    return "El RUC solo puede tener números y un guión con dígito verificador (ej. 80012345-6).";
  }
  const re = tipo === "empresa" ? RE_RUC_EMPRESA : RE_RUC;
  if (!re.test(s)) {
    return tipo === "empresa"
      ? "El RUC de empresa debe tener 8 dígitos (ej. 80012345 o 80012345-6)."
      : "El RUC/documento debe tener 6-8 dígitos, opcionalmente seguidos de guión y dígito verificador.";
  }
  return null;
}

export function validarDocumento(v: string | null | undefined): string | null {
  const raw = (v ?? "").trim();
  if (!raw) return null;
  const limpio = raw.replace(/[.,\s]/g, "");
  if (!/^\d+$/.test(limpio)) return "El documento solo puede tener números (los puntos o comas se limpian al guardar).";
  if (limpio.length < 6 || limpio.length > 9) return "El documento suele tener entre 6 y 9 dígitos.";
  return null;
}

/** Limpia separadores visuales de un documento antes de persistir. */
export function limpiarDocumento(v: string | null | undefined): string | null {
  if (v == null) return null;
  const s = String(v).replace(/[.,\s]/g, "").trim();
  return s || null;
}

export function validarEmail(v: string | null | undefined): string | null {
  const s = (v ?? "").trim();
  if (!s) return null;
  if (!RE_EMAIL.test(s)) return "Formato de email inválido (ej. nombre@dominio.com).";
  return null;
}

export function validarTelefono(v: string | null | undefined): string | null {
  const s = (v ?? "").trim();
  if (!s) return null;
  if (!RE_TELEFONO.test(s)) return "El teléfono solo puede tener dígitos, espacios, guiones o +.";
  return null;
}

export function validarSitioWeb(v: string | null | undefined): string | null {
  const s = (v ?? "").trim();
  if (!s) return null;
  if (!RE_SITIO_WEB.test(s)) return "Sitio web inválido (ej. https://empresa.com).";
  return null;
}

export function validarNumeroSocio(v: string | number | null | undefined): string | null {
  if (v == null || v === "") return null;
  const s = String(v).trim();
  if (!RE_NUMERO_SOCIO.test(s)) return "El N° de socio debe ser un entero positivo.";
  return null;
}

/**
 * Corre TODAS las validaciones aplicables sobre el payload de creación/edición.
 * Devuelve el primer error encontrado o null. Se usa en el POST/PATCH para
 * cerrar el círculo si el cliente logra saltar la validación del form.
 */
export function validarPayloadCliente(input: {
  tipo_cliente?: string | null;
  empresa?: string | null;
  nombre_contacto?: string | null;
  razon_social?: string | null;
  ruc?: string | null;
  ruc_factura?: string | null;
  documento?: string | null;
  telefono?: string | null;
  telefono_secundario?: string | null;
  email?: string | null;
  email_secundario?: string | null;
  sitio_web?: string | null;
  numero_socio?: string | number | null;
}): string | null {
  const tipo = input.tipo_cliente === "persona" ? "persona" : "empresa";
  return (
    validarNombre(input.empresa, "El nombre de empresa") ||
    validarNombre(input.nombre_contacto, "El nombre de contacto") ||
    validarNombre(input.razon_social, "La razón social") ||
    validarRuc(input.ruc, tipo) ||
    validarRuc(input.ruc_factura, tipo) ||
    validarDocumento(input.documento) ||
    validarTelefono(input.telefono) ||
    validarTelefono(input.telefono_secundario) ||
    validarEmail(input.email) ||
    validarEmail(input.email_secundario) ||
    validarSitioWeb(input.sitio_web) ||
    validarNumeroSocio(input.numero_socio ?? null)
  );
}
