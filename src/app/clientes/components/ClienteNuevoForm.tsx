"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  apiCreateCliente,
  apiCreateFactura,
  apiCreateSuscripcion,
  apiGetGestionTributariaClientes,
  apiGetObligacionesTributariasCatalogo,
  apiPutClientePerfilTributario,
  type DuplicadoMatchClient,
} from "@/lib/api/client";
import {
  ClientePerfilTributarioForm,
  buildPerfilTributarioPutBody,
  emptyTributarioForm,
  getErrorDiaVencimientoTributario,
  type TributarioFormState,
} from "@/components/clientes/ClientePerfilTributarioForm";
import { getProspecto, updateProspecto } from "@/lib/crm/storage";
import { getUsuariosActivosEmpresa, type UsuarioEmpresa } from "@/lib/usuarios/empresa";
import MontoInput from "@/components/ui/MontoInput";
import { getPlanes } from "@/lib/planes/storage";
import type { Cliente, TipoCliente, OrigenCliente } from "@/lib/clientes/types";
import { ClienteDatosSifenReceptorForm } from "@/components/clientes/ClienteDatosSifenReceptorForm";
import { formatTelefonoPy } from "@/lib/clientes/format-telefono";
import {
  limpiarDocumento,
  validarDocumento,
  validarEmail,
  validarNombre,
  validarNumeroSocio,
  validarRuc,
  validarSitioWeb,
  validarTelefono,
} from "@/lib/clientes/validators";
import type { Plan } from "@/lib/planes/types";

export type ClienteNuevoFormProps = {
  variant?: "page" | "modal";
  /** Si está definido, se llama con el id del nuevo cliente en lugar de hacer router.push */
  onCreated?: (id: string) => void;
  onCancel?: () => void;
  /** Precargar desde un prospecto CRM (equivale a `?from_crm=<id>`, pero para uso como modal). */
  fromProspectoId?: string;
};

// ── Estilos ────────────────────────────────────────────────────────────────────

const inputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 shadow-sm transition-colors hover:border-[#4FAEB2]/60 focus:border-[#4FAEB2] focus:outline-none focus:ring-2 focus:ring-[#4FAEB2]/20";
const labelClass = "block text-xs font-medium uppercase tracking-wide text-slate-500 mb-1.5";

/** Mensaje de error inline (rojo) debajo de un input. */
function FieldError({ msg }: { msg: string | null | undefined }) {
  if (!msg) return null;
  return <p className="mt-1 text-xs text-rose-600">{msg}</p>;
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <div className="mb-4 flex items-center gap-2">
      <span aria-hidden="true" className="block h-5 w-1 rounded-full bg-[#4FAEB2]" />
      <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-slate-600">{children}</p>
    </div>
  );
}

// ── Componente interno (necesita Suspense por useSearchParams) ─────────────────

function ClienteNuevoFormInner({ variant = "page", onCreated, onCancel, fromProspectoId }: ClienteNuevoFormProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const fromCrmId = fromProspectoId ?? searchParams?.get("from_crm");

  const isModal = variant === "modal";

  const [crmBanner, setCrmBanner] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  /** Errores por campo (validación inline). */
  const [fieldErrors, setFieldErrors] = useState<Record<string, string | null>>({});
  const [duplicado, setDuplicado] = useState<
    { mensaje: string; hay_inactivo: boolean; matches: DuplicadoMatchClient[] } | null
  >(null);
  const [guardando, setGuardando] = useState(false);
  /** El nombre del cliente autocompleta la razón social de factura hasta que el usuario la edite. */
  const [razonSocialTouched, setRazonSocialTouched] = useState(false);
  /** El RUC del cliente autocompleta el RUC de factura hasta que el usuario lo edite. */
  const [rucFacturaTouched, setRucFacturaTouched] = useState(false);
  const [planes, setPlanes] = useState<Plan[]>([]);
  const [usuariosEmpresa, setUsuariosEmpresa] = useState<UsuarioEmpresa[]>([]);
  const [usuariosEmpresaError, setUsuariosEmpresaError] = useState<string | null>(null);

  const [form, setForm] = useState({
    tipo_cliente: "persona" as TipoCliente,
    empresa: "",
    razon_social: "",
    ruc_factura: "",
    nombre_contacto: "",
    ruc: "",
    documento: "",
    telefono: "",
    telefono_secundario: "",
    email: "",
    email_secundario: "",
    direccion: "",
    ciudad: "",
    pais: "PARAGUAY",
    sitio_web: "",
    instagram: "",
    linkedin: "",
    valor_cliente: "",
    condicion_pago: "CONTADO",
    moneda_preferida: "GS" as "GS" | "USD",
    vendedor_usuario_id: "",
    origen: "MANUAL" as OrigenCliente,
    prospecto_id: null as string | null,
    numero_socio: "" as string,
    tipo_socio: "" as string,
    estado: "activo" as "activo" | "inactivo",
    sifen_receptor_manual: false,
    sifen_receptor_naturaleza: "" as string,
    sifen_ti_ope: "" as string,
    sifen_tipo_doc: "" as string,
    sifen_num_id_de: "",
    sifen_codigo_pais: "",
    sifen_direccion_de: "",
    sifen_num_casa_de: "",
    sifen_descripcion_tipo_doc: "",
  });

  const [formSusc, setFormSusc] = useState({
    plan_id: "",
    precio: "",
    duracion_meses: "12",
    dia_facturacion: "1",
    dia_vencimiento: "10",
    generar_factura: false,
  });

  const [formContado, setFormContado] = useState({
    emitir_factura: false,
    monto: "",
    descripcion: "Venta al contado",
  });

  const [gestionTributariaEmpresa, setGestionTributariaEmpresa] = useState(false);
  const [catalogoObligaciones, setCatalogoObligaciones] = useState<
    { id: string; slug: string; nombre: string; requiere_detalle_otro: boolean }[]
  >([]);
  const [formTributario, setFormTributario] = useState<TributarioFormState>(() => emptyTributarioForm());

  useEffect(() => {
    getPlanes().then(setPlanes);
  }, []);

  // Pre-carga el N° de socio con el siguiente libre (MAX+1). Es solo sugerencia:
  // el usuario puede editarlo o borrarlo si prefiere dejarlo vacío. Si el fetch
  // falla, arrancamos vacío (nunca bloqueamos el form).
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { fetchWithSupabaseSession } = await import("@/lib/api/fetch-with-supabase-session");
        const res = await fetchWithSupabaseSession("/api/clientes/next-numero-socio", { cache: "no-store" });
        if (!res.ok) return;
        const json = (await res.json()) as { success?: boolean; data?: { next?: number } };
        if (cancelled) return;
        const next = json?.data?.next;
        if (typeof next === "number" && Number.isFinite(next) && next > 0) {
          setForm((prev) => (prev.numero_socio ? prev : { ...prev, numero_socio: String(next) }));
        }
      } catch {
        // Silencioso: si falla, dejamos el input vacío. No es bloqueante.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const usuarios = await getUsuariosActivosEmpresa();
        if (cancelled) return;
        setUsuariosEmpresa(usuarios);
        setUsuariosEmpresaError(null);
      } catch (e) {
        if (cancelled) return;
        setUsuariosEmpresa([]);
        setUsuariosEmpresaError(e instanceof Error ? e.message : "No se pudieron cargar usuarios activos.");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const on = await apiGetGestionTributariaClientes();
        if (cancelled) return;
        setGestionTributariaEmpresa(on);
        if (on) {
          const cat = await apiGetObligacionesTributariasCatalogo();
          if (!cancelled) setCatalogoObligaciones(cat);
        }
      } catch (e) {
        if (cancelled) return;
        setGestionTributariaEmpresa(false);
        if (process.env.NODE_ENV === "development") {
          console.error("[nuevo cliente] gestión tributaria (¿migración/columna empresas?):", e);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (form.condicion_pago !== "CONTADO") return;
    const p = planes.find((x) => x.id === formSusc.plan_id);
    if (p) setFormContado((fc) => ({ ...fc, monto: String(p.precio) }));
  }, [formSusc.plan_id, form.condicion_pago, planes]);

  useEffect(() => {
    if (!fromCrmId) return;
    let cancelled = false;
    getProspecto(fromCrmId).then((prospecto) => {
      if (cancelled || !prospecto) return;
      setCrmBanner(`Prospecto ${prospecto.numero_control} — ${prospecto.empresa}`);
      setForm((prev) => ({
        ...prev,
        tipo_cliente: "persona",
        empresa: prospecto.empresa,
        nombre_contacto: prospecto.contacto,
        telefono: prospecto.telefono ?? "",
        email: prospecto.email ?? "",
        origen: "CRM",
        prospecto_id: prospecto.id,
      }));
    });
    return () => {
      cancelled = true;
    };
  }, [fromCrmId]);

  const upper = ["empresa", "razon_social", "nombre_contacto", "ciudad", "pais", "condicion_pago", "direccion", "sifen_codigo_pais"];
  const lower = ["email", "email_secundario"];

  function setFieldError(name: string, msg: string | null) {
    setFieldErrors((prev) => ({ ...prev, [name]: msg }));
  }

  function handleChange(e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) {
    setError(null);
    const { name, value } = e.target;
    const type = (e.target as HTMLInputElement).type;
    let normalized = value;
    if (lower.includes(name) || type === "email") normalized = value.toLowerCase();
    else if (upper.includes(name)) normalized = value.toUpperCase();
    // Los campos de "nombre" bloquean números y símbolos raros mientras se tipea.
    if (name === "nombre_contacto" || name === "empresa" || name === "razon_social") {
      normalized = normalized.replace(/[^A-Za-zÀ-ÿñÑ'\-\s.]/g, "");
    }
    // RUC / RUC de factura: solo dígitos y un guión.
    if (name === "ruc" || name === "ruc_factura") {
      normalized = normalized.replace(/[^0-9-]/g, "");
      // permitir solo un guión
      const partes = normalized.split("-");
      if (partes.length > 2) normalized = partes[0] + "-" + partes.slice(1).join("");
    }
    // Documento: dígitos + separadores visuales (se limpian al enviar).
    if (name === "documento") {
      normalized = normalized.replace(/[^0-9.,\s]/g, "");
    }
    // Teléfono secundario: dígitos, espacios, guiones y +.
    if (name === "telefono_secundario") {
      normalized = normalized.replace(/[^0-9+\-\s()]/g, "");
    }
    // Validación inline por campo (mensajes en rojo debajo del input).
    if (name === "nombre_contacto") setFieldError(name, validarNombre(normalized, "El nombre de contacto"));
    else if (name === "empresa") setFieldError(name, validarNombre(normalized, "El nombre de empresa"));
    else if (name === "razon_social") setFieldError(name, validarNombre(normalized, "La razón social"));
    else if (name === "ruc") setFieldError(name, validarRuc(normalized, form.tipo_cliente));
    else if (name === "ruc_factura") setFieldError(name, validarRuc(normalized, form.tipo_cliente));
    else if (name === "documento") setFieldError(name, validarDocumento(normalized));
    else if (name === "email") setFieldError(name, validarEmail(normalized));
    else if (name === "email_secundario") setFieldError(name, validarEmail(normalized));
    else if (name === "telefono_secundario") setFieldError(name, validarTelefono(normalized));
    else if (name === "sitio_web") setFieldError(name, validarSitioWeb(normalized));
    setForm((prev) => {
      const next = { ...prev, [name]: normalized };
      // Espejo: mientras el usuario no toque la razón social, sigue al nombre del cliente
      // (empresa → razón social; persona → nombre completo). Así no hay que tipear dos veces.
      if (name === "razon_social") setRazonSocialTouched(true);
      else if (!razonSocialTouched) {
        if (name === "empresa" && prev.tipo_cliente === "empresa") next.razon_social = normalized;
        else if (name === "nombre_contacto" && prev.tipo_cliente === "persona") next.razon_social = normalized;
      }
      // Espejo del RUC de factura: sigue al RUC del cliente (empresa) o a un documento con forma de
      // RUC (persona con guión); una cédula sin guión NO se copia (no es un RUC válido).
      if (name === "ruc_factura") setRucFacturaTouched(true);
      else if (!rucFacturaTouched) {
        if (name === "ruc" && prev.tipo_cliente === "empresa") next.ruc_factura = normalized;
        else if (
          name === "documento" &&
          prev.tipo_cliente === "persona" &&
          /^\d{4,}-\d$/.test(normalized.replace(/\s/g, ""))
        ) {
          next.ruc_factura = normalized;
        }
      }
      return next;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setDuplicado(null);

    if (!form.nombre_contacto.trim()) return setError("El nombre de contacto es obligatorio.");
    if (form.tipo_cliente === "empresa" && !form.empresa.trim())
      return setError("El nombre de empresa es obligatorio.");

    // Corre las validaciones una vez más antes del submit: si el usuario deja un
    // campo con error, no dejamos que se envíe (ni intento de red ni "carga
    // silenciosa" contra la API).
    const checks: Record<string, string | null> = {
      empresa: validarNombre(form.empresa, "El nombre de empresa"),
      nombre_contacto: validarNombre(form.nombre_contacto, "El nombre de contacto"),
      razon_social: validarNombre(form.razon_social, "La razón social"),
      ruc: validarRuc(form.ruc, form.tipo_cliente),
      ruc_factura: validarRuc(form.ruc_factura, form.tipo_cliente),
      documento: validarDocumento(form.documento),
      telefono_secundario: validarTelefono(form.telefono_secundario),
      email: validarEmail(form.email),
      email_secundario: validarEmail(form.email_secundario),
      sitio_web: validarSitioWeb(form.sitio_web),
      numero_socio: validarNumeroSocio(form.numero_socio),
    };
    // Empresa: RUC de 8 dígitos si se completó — la regla combinada.
    if (form.tipo_cliente === "empresa" && form.ruc.trim() && !/^\d{8}(-\d)?$/.test(form.ruc.trim())) {
      checks.ruc = "El RUC de empresa debe tener 8 dígitos (ej. 80012345-6).";
    }
    const primerError = Object.entries(checks).find(([, v]) => v);
    if (primerError) {
      setFieldErrors(checks);
      return setError(primerError[1] as string);
    }

    if (form.condicion_pago === "MENSUAL" && form.estado === "activo") {
      const dur = parseInt(formSusc.duracion_meses, 10) || 0;
      const diaFac = parseInt(formSusc.dia_facturacion, 10) || 0;
      const diaVenc = parseInt(formSusc.dia_vencimiento, 10) || 0;
      if (dur <= 0) return setError("La duración del contrato debe ser mayor a 0.");
      if (diaFac < 1 || diaFac > 28) return setError("El día de facturación debe estar entre 1 y 28.");
      if (diaVenc < 1 || diaVenc > 31) return setError("El día de vencimiento debe estar entre 1 y 31.");
      if (diaVenc <= diaFac) return setError("El día de vencimiento debe ser mayor al día de facturación.");
      if (!formSusc.plan_id.trim()) return setError("Seleccioná un plan para clientes mensuales.");
      const precio = parseFloat(formSusc.precio) || 0;
      if (precio <= 0) return setError("El precio debe ser mayor a 0.");
    }

    if (form.condicion_pago === "CONTADO" && formContado.emitir_factura) {
      const monto = parseFloat(formContado.monto) || 0;
      if (monto <= 0) return setError("El monto de la factura debe ser mayor a 0.");
    }

    if (gestionTributariaEmpresa && formTributario.perfil_activo) {
      const eDia = getErrorDiaVencimientoTributario(formTributario);
      if (eDia) return setError(eDia);
      const otro = catalogoObligaciones.find((c) => c.slug === "otro");
      if (otro && formTributario.obligacion_catalogo_ids.includes(otro.id) && !formTributario.obligacion_otro_detalle.trim()) {
        return setError('Completá el detalle cuando seleccionás la obligación "Otro".');
      }
    }

    if (form.sifen_receptor_manual) {
      if (!form.sifen_receptor_naturaleza.trim()) return setError("SIFEN receptor: elegí la naturaleza del receptor.");
      if (!form.sifen_ti_ope.trim()) return setError("SIFEN receptor: elegí el tipo de operación (B2B / B2C / B2G / B2F).");
      if (!form.sifen_direccion_de.trim()) return setError("SIFEN receptor (modo explícito): completá la dirección para el DE.");
      if (form.sifen_num_casa_de.trim() === "") return setError("SIFEN receptor (modo explícito): indicá el número de casa para el DE (0 si no aplica).");
      if (form.sifen_receptor_naturaleza === "extranjero") {
        const iso = form.sifen_codigo_pais.trim().toUpperCase();
        if (!/^[A-Z]{3}$/.test(iso) || iso === "PRY") return setError("SIFEN receptor (extranjero): indicá un código país ISO3 válido distinto de PRY.");
      }
      if (form.sifen_receptor_naturaleza === "contribuyente_paraguayo" && !form.ruc.trim()) {
        return setError("SIFEN receptor (contribuyente): el RUC del cliente es obligatorio.");
      }
      if (
        form.sifen_receptor_naturaleza !== "contribuyente_paraguayo" &&
        !form.sifen_num_id_de.trim() &&
        !form.documento.trim() &&
        !form.ruc.trim()
      ) {
        return setError("SIFEN receptor: completá el número de documento del DE o el documento/RUC del cliente.");
      }
      const td = form.sifen_tipo_doc.trim();
      if (td === "9") {
        const d = form.sifen_descripcion_tipo_doc.trim();
        if (d.length < 9 || d.length > 41) {
          return setError("SIFEN receptor: con tipo de documento «Otro», la descripción debe tener entre 9 y 41 caracteres (SET).");
        }
      }
    }

    const sifenManualCreate: Partial<Parameters<typeof apiCreateCliente>[0]> = form.sifen_receptor_manual
      ? {
          sifen_receptor_manual: true,
          sifen_receptor_naturaleza: (form.sifen_receptor_naturaleza.trim() || null) as Cliente["sifen_receptor_naturaleza"],
          sifen_ti_ope: form.sifen_ti_ope.trim() ? parseInt(form.sifen_ti_ope, 10) : null,
          sifen_tipo_doc_receptor: form.sifen_tipo_doc.trim() ? parseInt(form.sifen_tipo_doc, 10) : null,
          sifen_num_id_de: form.sifen_num_id_de.trim() || null,
          sifen_codigo_pais: form.sifen_codigo_pais.trim().toUpperCase() || null,
          sifen_direccion_de: form.sifen_direccion_de.trim() || null,
          sifen_num_casa_de:
            form.sifen_num_casa_de.trim() === "" ? null : Math.max(0, parseInt(form.sifen_num_casa_de, 10) || 0),
          sifen_descripcion_tipo_doc: form.sifen_descripcion_tipo_doc.trim() || null,
        }
      : {};

    setGuardando(true);

    const creado = await apiCreateCliente({
      tipo_cliente: form.tipo_cliente,
      empresa: form.tipo_cliente === "empresa" ? form.empresa.trim().toUpperCase() : undefined,
      razon_social: form.razon_social.trim().toUpperCase() || undefined,
      ruc_factura: form.ruc_factura.trim() || undefined,
      nombre_contacto: form.nombre_contacto.trim().toUpperCase(),
      ruc: form.ruc.trim() || undefined,
      documento: limpiarDocumento(form.documento) ?? undefined,
      telefono: form.telefono.trim() || undefined,
      telefono_secundario: form.telefono_secundario.trim() || undefined,
      email: form.email.trim() || undefined,
      email_secundario: form.email_secundario.trim().toLowerCase() || undefined,
      direccion: form.direccion.trim() || undefined,
      ciudad: form.ciudad.trim().toUpperCase() || undefined,
      pais: form.pais.trim().toUpperCase() || undefined,
      sitio_web: form.sitio_web.trim() || undefined,
      instagram: form.instagram.trim() || undefined,
      linkedin: form.linkedin.trim() || undefined,
      valor_cliente: form.valor_cliente.trim() === "" ? null : Number(form.valor_cliente) || null,
      condicion_pago: form.condicion_pago.trim().toUpperCase() || undefined,
      moneda_preferida: form.moneda_preferida,
      estado: form.estado,
      plan_comercial_id: formSusc.plan_id.trim() || null,
      vendedor_usuario_id: form.vendedor_usuario_id.trim() || null,
      numero_socio: form.numero_socio.trim() === "" ? null : Math.max(1, parseInt(form.numero_socio, 10) || 0) || null,
      tipo_socio: form.tipo_socio.trim() || null,
      ...sifenManualCreate,
    });

    if (creado.ok !== true) {
      setGuardando(false);
      if (creado.code === "DUPLICATE") {
        setDuplicado({
          mensaje: creado.error,
          hay_inactivo: creado.hay_inactivo ?? false,
          matches: creado.matches ?? [],
        });
        return;
      }
      return setError(creado.error || "Error al guardar. Revisá la consola.");
    }
    const clienteId = creado.data.id;

    if (gestionTributariaEmpresa && formTributario.perfil_activo) {
      const put = await apiPutClientePerfilTributario(clienteId, buildPerfilTributarioPutBody(formTributario));
      if (!put.ok) {
        setGuardando(false);
        return setError(put.error ?? "El cliente se creó, pero no se pudo guardar el perfil tributario.");
      }
    }

    if (form.condicion_pago === "MENSUAL" && form.estado === "activo") {
      const plan = planes.find((p) => p.id === formSusc.plan_id);
      await apiCreateSuscripcion({
        cliente_id: clienteId,
        plan_id: formSusc.plan_id || null,
        precio: parseFloat(formSusc.precio) || (plan?.precio ?? 0),
        moneda: form.moneda_preferida,
        fecha_inicio: new Date().toISOString().slice(0, 10),
        duracion_meses: parseInt(formSusc.duracion_meses, 10) || 12,
        dia_facturacion: parseInt(formSusc.dia_facturacion, 10) || 1,
        dia_vencimiento: parseInt(formSusc.dia_vencimiento, 10) || 10,
        generar_factura_este_mes: formSusc.generar_factura,
      });
    }

    if (form.condicion_pago === "CONTADO" && formContado.emitir_factura) {
      const monto = parseFloat(formContado.monto) || 0;
      if (monto > 0) {
        const hoy = new Date().toISOString().slice(0, 10);
        await apiCreateFactura({
          cliente_id: clienteId,
          fecha: hoy,
          fecha_vencimiento: hoy,
          monto,
          tipo: "contado",
          moneda: form.moneda_preferida,
          descripcion_linea: formContado.descripcion.trim() || "Venta al contado",
        });
      }
    }

    if (form.prospecto_id) {
      // Best-effort: marcar el prospecto como convertido a cliente. Si falla la marca,
      // el cliente ya se creó — no queremos abortar el flujo.
      try {
        await updateProspecto(form.prospecto_id, { cliente_creado: true });
      } catch (e) {
        console.warn("[clientes] no se pudo marcar prospecto como cliente_creado", e);
      }
    }

    setGuardando(false);

    if (onCreated) {
      onCreated(clienteId);
    } else {
      router.push(`/clientes/${clienteId}`);
    }
  }

  const sectionWrap = isModal ? "rounded-2xl border border-slate-200 bg-white p-5 shadow-sm" : "";
  const planBoxCls = isModal
    ? "mt-6 p-4 rounded-2xl bg-[#4FAEB2]/5 border border-[#4FAEB2]/30 space-y-4"
    : "mt-6 p-4 bg-slate-50 rounded-xl border border-slate-200 space-y-4";

  return (
    <form
      onSubmit={handleSubmit}
      className={
        isModal
          ? "flex h-full min-h-0 flex-col"
          : "bg-white border border-slate-200 rounded-2xl shadow-sm p-6 max-w-3xl space-y-8"
      }
    >
      <div
        className={
          isModal
            ? "min-h-0 flex-1 space-y-5 overflow-y-auto bg-slate-50/50 px-6 py-5"
            : "space-y-8"
        }
      >
        {/* Banner CRM */}
        {crmBanner && (
          <div className="flex items-center gap-3 rounded-2xl border border-violet-200 bg-violet-50 px-5 py-3">
            <span className="text-lg text-violet-500">🔗</span>
            <div>
              <p className="text-sm font-semibold text-violet-800">Creando desde CRM</p>
              <p className="text-xs text-violet-600">{crmBanner}</p>
            </div>
          </div>
        )}

        {/* Identificación */}
        <section className={sectionWrap}>
          <SectionTitle>Identificación</SectionTitle>
          <div className="space-y-4">
            {/* Fila principal: nombre del cliente + su documento tributario (RUC empresa / CI persona) */}
            {form.tipo_cliente === "empresa" ? (
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className={labelClass}>
                    Nombre de empresa <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="empresa"
                    value={form.empresa}
                    onChange={handleChange}
                    placeholder="CÓMO CONOCÉS A LA EMPRESA"
                    className={`${inputClass} uppercase`}
                  />
                  <FieldError msg={fieldErrors.empresa} />
                </div>
                <div>
                  <label className={labelClass}>RUC</label>
                  <input
                    type="text"
                    name="ruc"
                    value={form.ruc}
                    onChange={handleChange}
                    placeholder="00000000-0"
                    inputMode="numeric"
                    className={inputClass}
                  />
                  <FieldError msg={fieldErrors.ruc} />
                </div>
              </div>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className={labelClass}>
                    Nombre completo <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="nombre_contacto"
                    value={form.nombre_contacto}
                    onChange={handleChange}
                    placeholder="NOMBRE Y APELLIDO"
                    className={`${inputClass} uppercase`}
                    required
                  />
                  <FieldError msg={fieldErrors.nombre_contacto} />
                </div>
                <div>
                  <label className={labelClass}>CI / Documento</label>
                  <input
                    type="text"
                    name="documento"
                    value={form.documento}
                    onChange={handleChange}
                    placeholder="CI sin puntos"
                    inputMode="numeric"
                    className={inputClass}
                  />
                  <FieldError msg={fieldErrors.documento} />
                </div>
              </div>
            )}

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>N° Socio (sugerido, editable)</label>
                <input
                  type="number"
                  min={1}
                  step={1}
                  name="numero_socio"
                  value={form.numero_socio}
                  onChange={(e) => setForm((prev) => ({ ...prev, numero_socio: e.target.value.replace(/[^0-9]/g, "") }))}
                  placeholder="Siguiente libre — podés cambiarlo o dejarlo vacío"
                  className={inputClass}
                />
                <p className="mt-1 text-xs text-slate-500">
                  Se sugiere el siguiente número libre. Podés editarlo o dejarlo vacío para asignarlo después.
                </p>
                <FieldError msg={fieldErrors.numero_socio} />
              </div>
              <div>
                <label className={labelClass}>Tipo de socio</label>
                <select
                  name="tipo_socio"
                  value={form.tipo_socio}
                  onChange={(e) => setForm((prev) => ({ ...prev, tipo_socio: e.target.value }))}
                  className={inputClass}
                >
                  <option value="">— Sin categoría —</option>
                  <option value="SOCIO FUNDADOR">SOCIO FUNDADOR</option>
                  <option value="ACTIVO">ACTIVO</option>
                  <option value="RESERVADO">RESERVADO</option>
                </select>
              </div>
            </div>

            {/* Contacto directo: persona de contacto (solo empresa) + teléfono con formato +595 */}
            <div className="grid gap-4 sm:grid-cols-2">
              {form.tipo_cliente === "empresa" ? (
                <div>
                  <label className={labelClass}>
                    Persona de contacto <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="nombre_contacto"
                    value={form.nombre_contacto}
                    onChange={handleChange}
                    placeholder="NOMBRE Y APELLIDO"
                    className={`${inputClass} uppercase`}
                    required
                  />
                  <FieldError msg={fieldErrors.nombre_contacto} />
                </div>
              ) : null}
              <div>
                <label className={labelClass}>Teléfono de contacto</label>
                <input
                  type="tel"
                  name="telefono"
                  inputMode="numeric"
                  value={form.telefono}
                  onChange={(e) => setForm((prev) => ({ ...prev, telefono: formatTelefonoPy(e.target.value) }))}
                  placeholder="+595 9xx-xxx-xxx"
                  className={inputClass}
                />
              </div>
            </div>

            <div>
              <label className={labelClass}>Teléfono secundario</label>
              <input
                type="tel"
                name="telefono_secundario"
                inputMode="tel"
                value={form.telefono_secundario}
                onChange={handleChange}
                placeholder="Opcional"
                className={inputClass}
              />
              <FieldError msg={fieldErrors.telefono_secundario} />
            </div>
          </div>
        </section>

        {/* Datos para factura */}
        <section className={sectionWrap}>
          <SectionTitle>Datos para factura</SectionTitle>
          <p className="-mt-2 mb-4 text-xs text-slate-500">
            Lo que sale en el documento tributario (SIFEN). La factura SIEMPRE se emite contra un RUC. Si lo dejás
            vacío, se factura con el nombre y documento del cliente.
          </p>
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className={labelClass}>
                {form.tipo_cliente === "empresa" ? "Razón social" : "Nombre para factura"}
              </label>
              <input
                type="text"
                name="razon_social"
                value={form.razon_social}
                onChange={handleChange}
                placeholder={
                  form.tipo_cliente === "empresa"
                    ? "Razón social legal (como en el RUC)"
                    : "Nombre como figura en el documento"
                }
                className={`${inputClass} uppercase`}
              />
              <FieldError msg={fieldErrors.razon_social} />
            </div>
            <div>
              <label className={labelClass}>RUC</label>
              <input
                type="text"
                name="ruc_factura"
                value={form.ruc_factura}
                onChange={handleChange}
                placeholder="00000000-0"
                inputMode="numeric"
                className={inputClass}
              />
              <FieldError msg={fieldErrors.ruc_factura} />
            </div>
          </div>
        </section>

        {/* Contacto */}
        <section className={sectionWrap}>
          <SectionTitle>Contacto</SectionTitle>
          <div className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>Email</label>
                <input
                  type="email"
                  name="email"
                  value={form.email}
                  onChange={handleChange}
                  placeholder="contacto@empresa.com"
                  className={inputClass}
                />
                <FieldError msg={fieldErrors.email} />
              </div>
              <div>
                <label className={labelClass}>Email secundario</label>
                <input
                  type="email"
                  name="email_secundario"
                  value={form.email_secundario}
                  onChange={handleChange}
                  placeholder="Opcional"
                  className={inputClass}
                />
                <FieldError msg={fieldErrors.email_secundario} />
              </div>
            </div>

            <div>
              <label className={labelClass}>Dirección</label>
              <input
                type="text"
                name="direccion"
                value={form.direccion}
                onChange={handleChange}
                placeholder="Av. / Calle y número"
                className={inputClass}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>Ciudad</label>
                <input
                  type="text"
                  name="ciudad"
                  value={form.ciudad}
                  onChange={handleChange}
                  placeholder="ASUNCIÓN"
                  className={`${inputClass} uppercase`}
                />
              </div>
              <div>
                <label className={labelClass}>País</label>
                <input
                  type="text"
                  name="pais"
                  value={form.pais}
                  onChange={handleChange}
                  className={`${inputClass} uppercase`}
                />
              </div>
            </div>

            <ClienteDatosSifenReceptorForm
              value={{
                sifen_receptor_manual: form.sifen_receptor_manual,
                sifen_receptor_naturaleza: (form.sifen_receptor_naturaleza || null) as Cliente["sifen_receptor_naturaleza"],
                sifen_ti_ope: form.sifen_ti_ope.trim() ? parseInt(form.sifen_ti_ope, 10) : null,
                sifen_tipo_doc_receptor: form.sifen_tipo_doc.trim() ? parseInt(form.sifen_tipo_doc, 10) : null,
                sifen_codigo_pais: form.sifen_codigo_pais.trim() || null,
                sifen_num_id_de: form.sifen_num_id_de.trim() || null,
                sifen_direccion_de: form.sifen_direccion_de.trim() || null,
                sifen_num_casa_de:
                  form.sifen_num_casa_de.trim() === "" ? null : Math.max(0, parseInt(form.sifen_num_casa_de, 10) || 0),
                sifen_descripcion_tipo_doc: form.sifen_descripcion_tipo_doc.trim() || null,
              }}
              onChange={(patch) => {
                setForm((p) => {
                  if (patch.sifen_receptor_manual === false) {
                    return {
                      ...p,
                      sifen_receptor_manual: false,
                      sifen_receptor_naturaleza: "",
                      sifen_ti_ope: "",
                      sifen_tipo_doc: "",
                      sifen_num_id_de: "",
                      sifen_codigo_pais: "",
                      sifen_direccion_de: "",
                      sifen_num_casa_de: "",
                      sifen_descripcion_tipo_doc: "",
                    };
                  }
                  return {
                    ...p,
                    ...(patch.sifen_receptor_manual !== undefined
                      ? { sifen_receptor_manual: Boolean(patch.sifen_receptor_manual) }
                      : {}),
                    ...(patch.sifen_receptor_naturaleza !== undefined
                      ? { sifen_receptor_naturaleza: patch.sifen_receptor_naturaleza ?? "" }
                      : {}),
                    ...(patch.sifen_ti_ope !== undefined
                      ? { sifen_ti_ope: patch.sifen_ti_ope != null ? String(patch.sifen_ti_ope) : "" }
                      : {}),
                    ...(patch.sifen_tipo_doc_receptor !== undefined
                      ? {
                          sifen_tipo_doc:
                            patch.sifen_tipo_doc_receptor != null ? String(patch.sifen_tipo_doc_receptor) : "",
                        }
                      : {}),
                    ...(patch.sifen_num_id_de !== undefined ? { sifen_num_id_de: patch.sifen_num_id_de ?? "" } : {}),
                    ...(patch.sifen_codigo_pais !== undefined
                      ? { sifen_codigo_pais: patch.sifen_codigo_pais ?? "" }
                      : {}),
                    ...(patch.sifen_direccion_de !== undefined
                      ? { sifen_direccion_de: patch.sifen_direccion_de ?? "" }
                      : {}),
                    ...(patch.sifen_num_casa_de !== undefined
                      ? {
                          sifen_num_casa_de:
                            patch.sifen_num_casa_de != null ? String(patch.sifen_num_casa_de) : "",
                        }
                      : {}),
                    ...(patch.sifen_descripcion_tipo_doc !== undefined
                      ? { sifen_descripcion_tipo_doc: patch.sifen_descripcion_tipo_doc ?? "" }
                      : {}),
                  };
                });
              }}
            />
          </div>
        </section>

        {/* Presencia digital (opcionales) */}
        <section className={sectionWrap}>
          <SectionTitle>Presencia digital</SectionTitle>
          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <label className={labelClass}>Sitio web</label>
              <input
                type="text"
                name="sitio_web"
                value={form.sitio_web}
                onChange={handleChange}
                placeholder="https://empresa.com"
                className={inputClass}
              />
              <FieldError msg={fieldErrors.sitio_web} />
            </div>
            <div>
              <label className={labelClass}>Instagram</label>
              <input
                type="text"
                name="instagram"
                value={form.instagram}
                onChange={(e) => setForm((p) => ({ ...p, instagram: e.target.value }))}
                placeholder="@usuario"
                className={inputClass}
              />
            </div>
            <div>
              <label className={labelClass}>LinkedIn</label>
              <input
                type="text"
                name="linkedin"
                value={form.linkedin}
                onChange={(e) => setForm((p) => ({ ...p, linkedin: e.target.value }))}
                placeholder="URL o perfil"
                className={inputClass}
              />
            </div>
          </div>
        </section>

        {/* Datos comerciales */}
        <section className={sectionWrap}>
          <SectionTitle>Datos comerciales</SectionTitle>
          <div className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>Condición de pago</label>
                <select
                  name="condicion_pago"
                  value={form.condicion_pago}
                  onChange={handleChange}
                  className={inputClass}
                >
                  <option value="CONTADO">Contado</option>
                  <option value="15 DÍAS">15 días</option>
                  <option value="30 DÍAS">30 días</option>
                  <option value="60 DÍAS">60 días</option>
                  <option value="90 DÍAS">90 días</option>
                  <option value="MENSUAL">Mensual</option>
                </select>
              </div>
              <div>
                <label className={labelClass}>Moneda preferida</label>
                <select
                  name="moneda_preferida"
                  value={form.moneda_preferida}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, moneda_preferida: e.target.value === "USD" ? "USD" : "GS" }))
                  }
                  className={inputClass}
                >
                  <option value="GS">Guaraníes (Gs.)</option>
                  <option value="USD">Dólares (USD)</option>
                </select>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>Valor anual estimado (Gs.)</label>
                <MontoInput
                  value={form.valor_cliente}
                  onChange={(n) => setForm((p) => ({ ...p, valor_cliente: String(n) }))}
                  className={inputClass}
                  decimals={false}
                  placeholder="Opcional"
                />
              </div>
              <div>
                <label className={labelClass}>Vendedor responsable</label>
                <select
                  name="vendedor_usuario_id"
                  value={form.vendedor_usuario_id}
                  onChange={(e) => setForm((prev) => ({ ...prev, vendedor_usuario_id: e.target.value }))}
                  className={inputClass}
                >
                  <option value="">— Sin asignar —</option>
                  {usuariosEmpresa.map((u) => (
                    <option key={u.id} value={u.id}>
                      {(u.nombre ?? "").trim() || u.email}
                    </option>
                  ))}
                </select>
                {usuariosEmpresaError ? (
                  <p className="mt-1 text-xs text-rose-600">{usuariosEmpresaError}</p>
                ) : usuariosEmpresa.length === 0 ? (
                  <p className="mt-1 text-xs text-slate-500">No hay usuarios activos disponibles para asignar.</p>
                ) : null}
              </div>
            </div>

            {/* Origen del cliente: oculto por ahora (no aporta al alta). El valor se sigue
                seteando internamente (MANUAL, o CRM cuando viene del funnel). */}
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className={labelClass}>Estado inicial</label>
                <select
                  name="estado"
                  value={form.estado}
                  onChange={(e) => setForm((prev) => ({ ...prev, estado: e.target.value as "activo" | "inactivo" }))}
                  className={inputClass}
                >
                  <option value="activo">Activo</option>
                  <option value="inactivo">Inactivo</option>
                </select>
              </div>
            </div>

            <div className={planBoxCls}>
              <SectionTitle>Plan</SectionTitle>
              <div>
                <label className={labelClass}>Plan</label>
                <select
                  value={formSusc.plan_id}
                  onChange={(e) => {
                    const p = planes.find((x) => x.id === e.target.value);
                    setFormSusc((prev) => ({
                      ...prev,
                      plan_id: e.target.value,
                      precio: p ? String(p.precio) : prev.precio,
                    }));
                  }}
                  className={inputClass}
                >
                  <option value="">— Seleccionar plan —</option>
                  {planes.filter((p) => p.estado === "activo").map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.nombre} — {p.moneda} {p.precio.toLocaleString("es-PY")}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {form.condicion_pago === "CONTADO" && (
              <div className={planBoxCls}>
                <SectionTitle>Facturación al contado</SectionTitle>
                <label className="flex items-center gap-2 text-sm text-slate-700">
                  <input
                    type="checkbox"
                    checked={formContado.emitir_factura}
                    onChange={(e) => setFormContado((p) => ({ ...p, emitir_factura: e.target.checked }))}
                    className="h-4 w-4 rounded border-slate-300 text-[#4FAEB2] accent-[#4FAEB2] focus:ring-[#4FAEB2]/30"
                  />
                  Emitir factura inicial
                </label>
                {formContado.emitir_factura && (
                  <>
                    <div>
                      <label className={labelClass}>Monto (Gs.)</label>
                      <MontoInput
                        value={formContado.monto}
                        onChange={(n) => setFormContado((p) => ({ ...p, monto: String(n) }))}
                        className={inputClass}
                        placeholder="Monto de la factura"
                      />
                    </div>
                    <div>
                      <label className={labelClass}>Descripción</label>
                      <input
                        type="text"
                        value={formContado.descripcion}
                        onChange={(e) => setFormContado((p) => ({ ...p, descripcion: e.target.value }))}
                        className={inputClass}
                        placeholder="Venta al contado"
                      />
                    </div>
                  </>
                )}
              </div>
            )}

            {form.condicion_pago === "MENSUAL" && (
              <div className={planBoxCls}>
                <SectionTitle>Configuración de suscripción</SectionTitle>
                <div>
                  <label className={labelClass}>Precio (Gs.)</label>
                  <MontoInput
                    value={formSusc.precio}
                    onChange={(n) => setFormSusc((p) => ({ ...p, precio: String(n) }))}
                    className={inputClass}
                    placeholder="Monto mensual"
                  />
                </div>
                <div>
                  <label className={labelClass}>Duración contrato (meses)</label>
                  <input
                    type="number"
                    value={formSusc.duracion_meses}
                    onChange={(e) => setFormSusc((p) => ({ ...p, duracion_meses: e.target.value }))}
                    className={inputClass}
                    min={1}
                  />
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className={labelClass}>Día facturación (1–28)</label>
                    <input
                      type="number"
                      value={formSusc.dia_facturacion}
                      onChange={(e) => setFormSusc((p) => ({ ...p, dia_facturacion: e.target.value }))}
                      className={inputClass}
                      min={1}
                      max={28}
                    />
                  </div>
                  <div>
                    <label className={labelClass}>Día vencimiento (1–31)</label>
                    <input
                      type="number"
                      value={formSusc.dia_vencimiento}
                      onChange={(e) => setFormSusc((p) => ({ ...p, dia_vencimiento: e.target.value }))}
                      className={inputClass}
                      min={1}
                      max={31}
                    />
                  </div>
                </div>
                <label className="flex items-center gap-2 text-sm text-slate-700">
                  <input
                    type="checkbox"
                    checked={formSusc.generar_factura}
                    onChange={(e) => setFormSusc((p) => ({ ...p, generar_factura: e.target.checked }))}
                    className="h-4 w-4 rounded border-slate-300 text-[#4FAEB2] accent-[#4FAEB2] focus:ring-[#4FAEB2]/30"
                  />
                  Emitir factura este mes
                </label>
              </div>
            )}
          </div>
        </section>

        {gestionTributariaEmpresa && (
          <section className={sectionWrap}>
            <details className="group rounded-2xl border border-[#4FAEB2]/25 bg-gradient-to-b from-slate-50/80 to-white shadow-sm open:shadow-md transition-shadow [open]:shadow-md">
              <summary className="cursor-pointer list-none px-4 py-3 sm:px-5 sm:py-3.5 flex items-center justify-between gap-2 text-left [&::-webkit-details-marker]:hidden">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Opcional</p>
                  <p className="text-sm font-semibold text-slate-800 mt-0.5">Perfil tributario</p>
                  <p className="text-xs text-slate-500 mt-0.5 max-w-xl">
                    Expandir para IVA, IRE, honorarios y obligaciones. Los datos fiscales no reemplazan la ficha
                    comercial.
                  </p>
                </div>
                <span
                  className="shrink-0 rounded-lg border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 group-open:bg-[#4FAEB2]/10 group-open:text-[#3F8E91] group-open:border-[#4FAEB2]/30"
                  aria-hidden
                >
                  Expandir
                </span>
              </summary>
              <div className="px-4 pb-4 sm:px-5 sm:pb-5 pt-0">
                <ClientePerfilTributarioForm
                  catalog={catalogoObligaciones}
                  value={formTributario}
                  onChange={setFormTributario}
                  tipoCliente={form.tipo_cliente}
                />
              </div>
            </details>
          </section>
        )}

        {duplicado && (
          <div
            className={
              "rounded-xl border px-4 py-3 text-sm " +
              (duplicado.hay_inactivo
                ? "border-amber-200 bg-amber-50 text-amber-800"
                : "border-rose-200 bg-rose-50 text-rose-700")
            }
          >
            <p className="font-semibold">{duplicado.mensaje}</p>
            <ul className="mt-3 space-y-2">
              {duplicado.matches.map((m) => (
                <li
                  key={m.cliente_id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-white/60 bg-white/70 px-3 py-2"
                >
                  <div className="min-w-0">
                    <p className="truncate font-medium text-slate-800">{m.nombre}</p>
                    <p className="text-xs text-slate-500">
                      {m.documento ? `RUC/Cédula: ${m.documento} · ` : ""}
                      Estado: {m.activo ? "Activo" : "Inactivo"}
                      {` · coincide por ${m.match_type === "ambos" ? "RUC/Cédula y nombre" : m.match_type === "documento" ? "RUC/Cédula" : "nombre"}`}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => router.push(`/clientes/${m.cliente_id}`)}
                    className="shrink-0 rounded-lg bg-[#4FAEB2] px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition-colors hover:bg-[#3F8E91]"
                  >
                    {m.activo ? "Abrir ficha" : "Abrir ficha para reactivar"}
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            <span>⚠</span>
            <span className="font-medium">{error}</span>
          </div>
        )}
      </div>

      {/* Acciones */}
      <div
        className={
          isModal
            ? "flex flex-wrap items-center justify-end gap-2 border-t border-slate-100 bg-white px-6 py-4"
            : "flex flex-wrap gap-3 pt-2"
        }
      >
        {(onCancel || !isModal) && (
          <button
            type="button"
            onClick={() => (onCancel ? onCancel() : router.push("/clientes"))}
            className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm transition-colors hover:border-[#4FAEB2]/60 hover:text-[#4FAEB2]"
          >
            Cancelar
          </button>
        )}
        <button
          type="submit"
          disabled={guardando}
          className="rounded-xl bg-[#4FAEB2] px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-[#4FAEB2]/20 transition-colors hover:bg-[#3F8E91] disabled:cursor-not-allowed disabled:bg-slate-200 disabled:text-slate-400 disabled:shadow-none"
        >
          {guardando ? "Guardando…" : "Guardar cliente"}
        </button>
      </div>
    </form>
  );
}

export default function ClienteNuevoForm(props: ClienteNuevoFormProps) {
  return (
    <Suspense fallback={<div className="animate-pulse text-slate-400 text-sm p-8">Cargando formulario...</div>}>
      <ClienteNuevoFormInner {...props} />
    </Suspense>
  );
}
