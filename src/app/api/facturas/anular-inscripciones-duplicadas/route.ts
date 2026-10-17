import { NextRequest, NextResponse } from "next/server";
import { getAuthWithRol, isAdmin } from "@/lib/middleware/auth";
import { getFacturasServiceClientForEmpresa } from "@/lib/facturacion/facturas-service-client";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { anularInscripcionesDuplicadas } from "@/lib/facturacion/anular-inscripciones-duplicadas";

/**
 * POST /api/facturas/anular-inscripciones-duplicadas  (SOLO admin)
 *
 * Limpieza acotada: anula las copias `INSCRIP-NN` de inscripción duplicada que NO
 * tienen pago real, conservando la `INSC-0NN` que sí lo tiene. Omite cualquier caso
 * que no siga ese patrón exacto (lo reporta como anomalía). Audita en cliente_historial.
 *
 * Por seguridad es DRY-RUN por defecto: devuelve el plan sin tocar nada.
 * Para aplicar de verdad hay que mandar { "aplicar": true } en el body.
 */
export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthWithRol(request);
    if (!auth?.empresa_id) {
      return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    }
    if (!isAdmin(auth)) {
      return NextResponse.json(
        errorResponse("Solo usuarios administradores pueden ejecutar esta limpieza."),
        { status: 403 }
      );
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      body = {};
    }
    const b = body != null && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const aplicar = b.aplicar === true;

    const supabase = await getFacturasServiceClientForEmpresa(auth.empresa_id);
    const result = await anularInscripcionesDuplicadas(supabase, auth, { dryRun: !aplicar });
    return NextResponse.json(successResponse(result));
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json(errorResponse(msg), { status: 500 });
  }
}
