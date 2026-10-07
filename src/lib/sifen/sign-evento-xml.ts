/**
 * Firma XML-DSig del Evento SIFEN (rEve con atributo Id).
 *
 * Mismo stack que sign-xml.ts (xml-crypto + node-forge), pero la Reference
 * apunta al rEve en vez del DE. La firma queda como ultimo hijo del rEve
 * (ubicacion aceptada por SET para eventos).
 */

import { SignedXml } from "xml-crypto";
import { createPrivateKey } from "node:crypto";
import type { P12KeyMaterial } from "./sign-xml";

const XPATH_REVE =
  "/*[local-name(.)='rGesEve']/*[local-name(.)='rEve']";

const TRANSFORMS_REVE = [
  "http://www.w3.org/2000/09/xmldsig#enveloped-signature",
  "http://www.w3.org/2001/10/xml-exc-c14n#",
] as const;
const DIGEST = "http://www.w3.org/2001/04/xmlenc#sha256";
const SIG_ALG = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";

/**
 * Firma un XML de evento (rGesEve → rEve) con el mismo certificado P12 del
 * emisor. Devuelve el XML con <ds:Signature> dentro del rEve.
 */
export function signSifenEventoXml(xmlUtf8: string, material: P12KeyMaterial): string {
  const trimmed = xmlUtf8.trim();
  if (!/<\s*rEve\b/i.test(trimmed) || !/<\s*rGesEve\b/i.test(trimmed)) {
    throw new Error("Se esperaba un XML con raíz rGesEve que contenga un elemento rEve para firmar.");
  }

  const privateKey = createPrivateKey({
    key: material.privateKeyPem,
    format: "pem",
  });

  const sig = new SignedXml({
    privateKey,
    publicCert: material.certificatePem,
    signatureAlgorithm: SIG_ALG,
    canonicalizationAlgorithm: "http://www.w3.org/2001/10/xml-exc-c14n#",
  });

  sig.addReference({
    xpath: XPATH_REVE,
    transforms: [...TRANSFORMS_REVE],
    digestAlgorithm: DIGEST,
  });

  sig.computeSignature(trimmed, {
    location: {
      reference: XPATH_REVE,
      /** La firma queda como ultimo hijo DENTRO del rEve (append). */
      action: "append",
    },
  });

  return sig.getSignedXml();
}
