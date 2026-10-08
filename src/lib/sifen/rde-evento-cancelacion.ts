/**
 * XML del Evento de Cancelación SIFEN (rGesEve → rEve → gGroupTiEvt → rGeVeCan).
 *
 * Referencia: MT (Manual Técnico) SIFEN v150 - sección Eventos. El evento se
 * envía al endpoint de eventos (`/de/ws/eventos/evento.wsdl`, operación
 * `siRecepEvento_V150`) para dar de baja un DE ya aprobado por SET.
 *
 * El `rEve` lleva un atributo `Id` que es la referencia de la firma XML-DSig,
 * y un `dSecMsg` secuencial unico por emisor (SIFEN exige unicidad para
 * detectar reenvios).
 *
 * Plazo oficial SIFEN: hasta 48 hs desde la aprobacion del DE. Si se envia
 * fuera de plazo, SET responde con un rechazo (dCodRes != '0601') y hay que
 * ir por Nota de Credito.
 */

import {
  SIFEN_EKUATIA_TARGET_NS,
  buildSifenSiRecepEventoV150SchemaLocation,
} from "./sifen-xsi-schema-location";
import { escapeXml } from "./xml";

const XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance";

export interface BuildCancelacionEventXmlOptions {
  /** CDC de 44 dígitos del DE que se quiere cancelar. */
  cdc: string;
  /** Motivo (5-500 caracteres). */
  motivo: string;
  /** Fecha de firma del evento (ISO-8601 local, SIFEN acepta sin TZ). */
  dFecFirma?: Date;
  /** Secuencia unica por emisor (1 - 9_999_999_999_999_999). La asignacion la
   *  hace el caller con el counter de empresa_sifen_config.sifen_evento_seq. */
  dSecMsg: string;
  /** RUC del emisor sin DV (ej. "80012345"). SIFEN lo exige en el nodo rGesEve. */
  rucEmisor: string;
  /** DV del RUC del emisor (ej. "7"). */
  dvEmisor: string;
  /** Razón social del emisor. */
  nombreEmisor: string;
}

/** Formato de fecha SIFEN: YYYY-MM-DDTHH:mm:ss (sin TZ, hora local Paraguay). */
function fechaSifen(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  );
}

/**
 * Arma el XML del evento de cancelacion. El `Id` del rEve es el valor pasado
 * en `dSecMsg` para que caller y firma coincidan en la referencia.
 */
export function buildCancelacionEventXml(opts: BuildCancelacionEventXmlOptions): {
  xml: string;
  rEveId: string;
} {
  const cdc = (opts.cdc ?? "").trim();
  if (!/^\d{44}$/.test(cdc)) {
    throw new Error("CDC invalido: se requieren exactamente 44 digitos.");
  }
  const motivo = (opts.motivo ?? "").trim();
  if (motivo.length < 5 || motivo.length > 500) {
    throw new Error("motivo debe tener entre 5 y 500 caracteres.");
  }
  const dSecMsg = (opts.dSecMsg ?? "").trim();
  if (!/^\d{1,15}$/.test(dSecMsg)) {
    throw new Error("dSecMsg debe ser un entero positivo (1-15 digitos).");
  }
  const ruc = (opts.rucEmisor ?? "").trim();
  const dv = (opts.dvEmisor ?? "").trim();
  if (!ruc || !dv) throw new Error("rucEmisor y dvEmisor son obligatorios.");
  const nombre = (opts.nombreEmisor ?? "").trim();
  if (!nombre) throw new Error("nombreEmisor es obligatorio.");

  const dFecFirma = fechaSifen(opts.dFecFirma ?? new Date());
  // El Id del rEve debe ser el mismo dSecMsg para que la firma pueda referenciarlo.
  const rEveId = dSecMsg;

  // Estructura segun SIFEN Manual Tecnico v150, seccion Eventos + facturae-xmlgen
  // (lib Paraguaya en produccion):
  //   <rGesEve xmlns xmlns:xsi xsi:schemaLocation>  ← schemaLocation requerido por XSD
  //     <rEve Id="X">...payload...</rEve>
  //     <ds:Signature>...</ds:Signature>  ← HERMANO del rEve, dentro del rGesEve
  //   </rGesEve>
  const schemaLoc = buildSifenSiRecepEventoV150SchemaLocation();
  const xml =
    `<?xml version="1.0" encoding="UTF-8"?>` +
    `<rGesEve xmlns="${SIFEN_EKUATIA_TARGET_NS}"` +
      ` xmlns:xsi="${XMLNS_XSI}" xsi:schemaLocation="${escapeXml(schemaLoc)}">` +
      `<rEve Id="${escapeXml(rEveId)}">` +
        `<dFecFirma>${escapeXml(dFecFirma)}</dFecFirma>` +
        `<dVerFor>150</dVerFor>` +
        `<gGroupTiEvt>` +
          `<rGeVeCan>` +
            `<Id>${escapeXml(cdc)}</Id>` +
            `<mOtEve>${escapeXml(motivo)}</mOtEve>` +
          `</rGeVeCan>` +
        `</gGroupTiEvt>` +
      `</rEve>` +
    `</rGesEve>`;

  return { xml, rEveId };
}
