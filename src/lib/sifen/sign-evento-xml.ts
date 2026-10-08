/**
 * Firma XML-DSig del Evento SIFEN (rEve con atributo Id).
 *
 * Importante (contrato SIFEN v150):
 *  - La <ds:Signature> va como HERMANO del <rEve>, dentro del <rGesEve>.
 *    No va como hijo del <rEve> — la XSD oficial no lo permite.
 *  - El prefijo "ds:" es exigido por la XSD en varias versiones de SET.
 *  - La Reference apunta al atributo Id del <rEve> (URI="#id").
 */

import { SignedXml } from "xml-crypto";
import { createPrivateKey } from "node:crypto";
import type { P12KeyMaterial } from "./sign-xml";

const XPATH_REVE = "/*[local-name(.)='rGesEve']/*[local-name(.)='rEve']";

const TRANSFORMS_REVE = [
  "http://www.w3.org/2000/09/xmldsig#enveloped-signature",
  "http://www.w3.org/2001/10/xml-exc-c14n#",
] as const;
const DIGEST = "http://www.w3.org/2001/04/xmlenc#sha256";
const SIG_ALG = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";

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
  // xml-crypto emite <ds:Signature xmlns:ds="..."> cuando se setea prefix.
  sig.signatureAlgorithm = SIG_ALG;

  sig.addReference({
    xpath: XPATH_REVE,
    transforms: [...TRANSFORMS_REVE],
    digestAlgorithm: DIGEST,
  });

  sig.computeSignature(trimmed, {
    prefix: "ds",
    location: {
      reference: XPATH_REVE,
      /** HERMANO posterior al <rEve> (sibling, no child), dentro de <rGesEve>. */
      action: "after",
    },
  });

  return sig.getSignedXml();
}
