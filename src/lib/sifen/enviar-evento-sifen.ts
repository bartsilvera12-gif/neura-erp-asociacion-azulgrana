/**
 * Envio de Eventos SIFEN (siRecepEvento_V150) por SOAP + mTLS.
 *
 * Espeja la logica de enviar-lote-sifen-test.ts pero contra el endpoint de
 * eventos (`/de/ws/eventos/evento.wsdl`). El cuerpo SOAP envuelve el XML del
 * evento (ya firmado) dentro de `rEnvioEvento` + `dEvReg`, sin ZIP (los
 * eventos se mandan en claro, a diferencia de los lotes de DE).
 */

import * as https from "node:https";
import type { AmbienteSifen } from "./types";
import { extractKeyAndCertFromP12, type P12KeyMaterial } from "./sign-xml";
import { urlRecepEvento } from "./sifen-ws-urls";
import { SIFEN_EKUATIA_TARGET_NS } from "./sifen-xsi-schema-location";

// IMPORTANTE: el endpoint de eventos de SIFEN (/de/ws/eventos/evento.wsdl)
// solo acepta SOAP 1.1 (http://schemas.xmlsoap.org/soap/envelope/), no 1.2.
// Los endpoints de DE (recibe-lote, recibe sync) si aceptan SOAP 1.2, pero
// eventos no. Confirmado comparando con facturacionelectronicapy-setjs.
const SOAP_ENV_11 = "http://schemas.xmlsoap.org/soap/envelope/";
const SIFEN_NS = SIFEN_EKUATIA_TARGET_NS;

export interface EnviarEventoSifenParams {
  empresaConfig: {
    ambiente: AmbienteSifen;
    certificadoP12: Buffer;
    certificadoPassword: string;
  };
  /** XML del evento ya firmado (rGesEve con <ds:Signature>). */
  xmlEventoFirmado: string;
  /** dId SOAP (envoltorio del lote de eventos). Se autogenera si no viene. */
  dId?: number;
}

export interface EventoSifenRespuestaParsed {
  httpStatus: number;
  /** `dCodRes` global del envio (ej. 0300 = recibido). */
  dCodRes: string | null;
  /** `dMsgRes` global. */
  dMsgRes: string | null;
  /** `dCodResEve` resultado del evento especifico (0601 = aprobado, otros = rechazo). */
  dCodResEve: string | null;
  /** Mensaje del evento (motivo del rechazo si aplica). */
  dMsgResEve: string | null;
  /** Protocolo de autorizacion del evento (si fue aprobado). */
  dProtAut: string | null;
  dFecProc: string | null;
  cuerpoSoapCrudo: string;
  /** Snapshot del request para poder debugguear si rechaza. */
  solicitudHttps: {
    url: string;
    method: string;
    contentType: string;
    soapBodyUtf8: string;
  };
}

function stripXmlDecl(xml: string): string {
  return xml.replace(/^﻿?/, "").replace(/^<\?xml[^?]*\?>\s*/i, "").trim();
}

function generarDId(): number {
  const mod = BigInt("999999999999999");
  let n = Number(BigInt(Date.now()) % mod);
  if (!Number.isFinite(n) || n < 1) n = 1;
  return n;
}

/**
 * Envuelve el XML del evento firmado en el SOAP de rEnvioEvento (siRecepEvento_V150).
 * Estructura:
 *   <env:Envelope>
 *     <env:Body>
 *       <rEnvioEvento xmlns=SIFEN>
 *         <dId>N</dId>
 *         <dEvReg>
 *           <rGesEve>...</rGesEve>    ← evento ya firmado
 *         </dEvReg>
 *       </rEnvioEvento>
 *     </env:Body>
 *   </env:Envelope>
 */
function construirSoapRecibeEvento(dId: number, xmlEventoFirmado: string): string {
  const inner = stripXmlDecl(xmlEventoFirmado);
  // SOAP 1.1: prefijo "soap:", namespace schemas.xmlsoap.org, sin <soap:Header/>
  // vacio (algunos handlers lo rechazan).
  return (
    `<?xml version="1.0" encoding="UTF-8"?>` +
    `<soap:Envelope xmlns:soap="${SOAP_ENV_11}">` +
    `<soap:Body>` +
    `<rEnvioEvento xmlns="${SIFEN_NS}">` +
    `<dId>${dId}</dId>` +
    `<dEvReg>` +
    inner +
    `</dEvReg>` +
    `</rEnvioEvento>` +
    `</soap:Body>` +
    `</soap:Envelope>`
  );
}

function extraerTextoElemento(xml: string, local: string): string | null {
  const re = new RegExp(
    `<(?:[^\\s/>:]+:)?${local}\\b[^>]*>([\\s\\S]*?)</(?:[^\\s/>:]+:)?${local}\\b[^>]*>`,
    "i"
  );
  const m = xml.match(re);
  if (!m?.[1]) return null;
  const inner = m[1].replace(/<[^>]+>/g, "").trim();
  return inner.length > 0 ? inner : null;
}

function postHttpsMtls(
  urlStr: string,
  body: string,
  certPem: string,
  keyPem: string,
  contentType: string
): Promise<{ status: number; body: string }> {
  const url = new URL(urlStr);
  const port = url.port ? Number(url.port) : 443;
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: url.hostname,
        port,
        path: `${url.pathname}${url.search}`,
        method: "POST",
        cert: certPem,
        key: keyPem,
        rejectUnauthorized: true,
        headers: {
          "Content-Type": contentType,
          "Content-Length": Buffer.byteLength(body, "utf8"),
          // SOAP 1.1 requiere SOAPAction. SET usa string vacio como accion generica.
          SOAPAction: '""',
        },
      },
      (res) => {
        const chunks: Buffer[] = [];
        res.on("data", (ch) => chunks.push(ch as Buffer));
        res.on("end", () => {
          resolve({
            status: res.statusCode ?? 0,
            body: Buffer.concat(chunks).toString("utf8"),
          });
        });
      }
    );
    req.on("error", reject);
    req.write(body, "utf8");
    req.end();
  });
}

export async function enviarEventoSifen(
  params: EnviarEventoSifenParams
): Promise<EventoSifenRespuestaParsed> {
  const ambiente: AmbienteSifen = params.empresaConfig.ambiente ?? "test";
  if (ambiente !== "test" && ambiente !== "produccion") {
    throw new Error('ambiente debe ser "test" o "produccion".');
  }

  const url = urlRecepEvento(ambiente);
  const dId = params.dId ?? generarDId();
  const soapBody = construirSoapRecibeEvento(dId, params.xmlEventoFirmado);
  // SOAP 1.1: Content-Type text/xml + header SOAPAction obligatorio.
  const contentType = "text/xml; charset=utf-8";

  const material: P12KeyMaterial = extractKeyAndCertFromP12(
    params.empresaConfig.certificadoP12,
    params.empresaConfig.certificadoPassword
  );

  let httpStatus: number;
  let cuerpo: string;
  try {
    const res = await postHttpsMtls(url, soapBody, material.certificatePem, material.privateKeyPem, contentType);
    httpStatus = res.status;
    cuerpo = res.body;
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const label = ambiente === "produccion" ? "SIFEN producción" : "SIFEN TEST";
    throw new Error(`Fallo HTTPS/mTLS contra ${label} (eventos): ${msg}`);
  }

  return {
    httpStatus,
    dCodRes: extraerTextoElemento(cuerpo, "dCodRes"),
    dMsgRes: extraerTextoElemento(cuerpo, "dMsgRes"),
    dCodResEve: extraerTextoElemento(cuerpo, "dCodResEve"),
    dMsgResEve: extraerTextoElemento(cuerpo, "dMsgResEve"),
    dProtAut: extraerTextoElemento(cuerpo, "dProtAut"),
    dFecProc: extraerTextoElemento(cuerpo, "dFecProc"),
    cuerpoSoapCrudo: cuerpo,
    solicitudHttps: {
      url,
      method: "POST",
      contentType,
      soapBodyUtf8: soapBody,
    },
  };
}
