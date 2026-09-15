# Neura ERP · Asociación Hernandarias Azulgrana — puesta en marcha

ERP independiente, copia de `neura-erp-sistemas-propio`, con su propio schema
Postgres, su propia empresa y su propio login. No comparte datos ni historial
git con el ERP original.

| | |
|---|---|
| Repo | `bartsilvera12-gif/neura-erp-asociacion-azulgrana` |
| Schema de datos | `asociacionazulgranaerp` (clonado de `instemaq`) |
| URL | `http://asociacionhernandariasazulgrana.neura.com.py` (HTTP: el TLS lo termina Cloudflare) |
| Empresa id | `498add65-8616-412a-9ee7-d5d60adba136` |
| Login admin | `admin@asociacionhernandariasazulgrana.com` (rol `admin`) |

---

## 1 · Base de datos

Los scripts están en `supabase/asociacionazulgrana/`. Se pegan en el SQL Editor
de Supabase self-hosted **en este orden**, uno por vez, leyendo los `NOTICE`
que devuelve cada uno.

| # | Archivo | Qué hace |
|---|---|---|
| 00 | `00_diagnostico_schema_origen.sql` | Opcional, solo lectura. Confirma que `instemaq` es el origen. |
| 01 | `01_clonar_schema.sql` | Crea `asociacionazulgranaerp` como copia estructural de `instemaq`, **sin datos**. |
| 02 | `02_catalogo_modulos.sql` | Copia el catálogo `modulos` (lista de módulos del producto). |
| 03 | `03_empresa_admin_modulos.sql` | Empresa + usuario admin + los 6 módulos habilitados. |
| 04 | `04_verificacion.sql` | Solo lectura. Compara origen vs destino y busca fugas. |

### Antes de ejecutar

El schema origen es **`instemaq`** y ya está fijado en los scripts 01, 02 y
04: no hay nada que ajustar ahí. Lo único que tenés que tocar es
**`v_password` en el 03**, antes de ejecutarlo.

### Garantías de aislamiento

- El 01 solo hace `CREATE` dentro de `asociacionazulgranaerp`. Al schema origen
  únicamente lo lee; a `public`, `auth` y `storage` no los toca.
- Toda referencia interna `<origen>.x` se reescribe a `asociacionazulgranaerp.x`:
  FKs, triggers, policies RLS, vistas, defaults y el `search_path` de las
  funciones `SECURITY DEFINER`. El ERP nuevo no queda colgado del viejo.
- Las FKs a `auth.users` se mantienen: es la tabla de Supabase, compartida por
  diseño (un solo GoTrue para toda la instancia).
- El 01 aborta si `asociacionazulgranaerp` ya existe: no pisa nada.
- Corre en una sola transacción.

### Después del 01

La exposición del schema en PostgREST la hacés vos (queda fuera de estos
scripts, como pediste): agregar `asociacionazulgranaerp` a los *exposed schemas*
y recargar. Los scripts ya emiten `pg_notify('pgrst', 'reload schema')`.

---

## 2 · Módulos habilitados

El menú se arma con `empresa_modulos ∩ usuario_modulos`. El script 03 deja
activos **exactamente estos 6** y desactiva cualquier otro:

`clientes`, `cobranzas`, `dashboard`, `gestion-clientes`, `planes`, `reportes`.

Que en el sidebar se ven como: **Clientes**, **Cobranzas**, **Dashboard**,
**Gestión Clientes**, **Planes**, **Reportes**.

El script 03 también inserta esos 6 slugs en el catálogo `modulos` si faltan
(en `instemaq` algunas filas del catálogo se sembraron sobre otro schema y no
existen).

> Ojo: si `empresa_modulos` quedara vacía para esta empresa, el ERP muestra
> **todos** los módulos por retrocompatibilidad
> (`src/lib/modulos/resolve-effective-modules.ts`). Las filas del script 03 son
> las que recortan el menú: no las borres.

---

## 3 · Variables de entorno (Coolify)

Partí de las variables del proyecto de sistemas-propio y aplicá esta tabla.

### Cambian sí o sí

| Variable | Valor |
|---|---|
| `APP_DB_SCHEMA` | `asociacionazulgranaerp` |
| `NEXT_PUBLIC_APP_URL` | `http://asociacionhernandariasazulgrana.neura.com.py` |

### Se copian tal cual (misma instancia de Supabase self-hosted)

`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_URL`, `DATABASE_URL`, `DIRECT_URL`,
`SUPABASE_DB_PASSWORD`, `PG_POOL_MAX`.

El pool de Postgres no fija `search_path`: todas las consultas van calificadas
con `APP_DB_SCHEMA`, así que la misma cadena de conexión sirve para todos los
ERP sin mezclarlos.

### Empresa: hay que poner el id nuevo o borrarlas

`WHATSAPP_DEFAULT_EMPRESA_ID`, `YCLOUD_WEBHOOK_EMPRESA_ID`,
`CRM_WEBHOOK_EMPRESA_ID`, `META_MSG_EMPRESA_ID`, `CONTACT_CENTER_EMPRESA_IDS`,
`FACTURACION_MENSUAL_EMPRESA_IDS`.

Si se copian con el id viejo, este ERP escribe sobre la empresa del otro.
Como los módulos omnicanal y de campañas quedan fuera, lo más limpio es **no
definirlas**; si alguna hace falta, va
`498add65-8616-412a-9ee7-d5d60adba136`.

### Secretos propios (generar nuevos, no reusar)

`CRON_SECRET`, `WEBHOOK_SECRET`, `SIFEN_SECRETS_KEY`, `BAILEYS_BRIDGE_SECRET`,
`RAFFLES_N8N_SECRET`, `QA_SORTEO_TICKET_SECRET`, `WHATSAPP_VERIFY_TOKEN`,
`META_MSG_VERIFY_TOKEN`.

`SIFEN_SECRETS_KEY` cifra las contraseñas de certificados SIFEN. Si se comparte
con otro ERP, cada uno puede descifrar los certificados del otro.

### Opcionales, según qué se use

`SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` / `SMTP_FROM`,
`ANTHROPIC_API_KEY`, `ASSISTANT_ENABLED`, `NEXT_PUBLIC_ASSISTANT_ENABLED`,
`GOOGLE_CLOUD_VISION_API_KEY`, `NEXT_PUBLIC_SUPER_ADMIN_EMAILS`,
`FACTURA_PREFIJO`, `FACTURA_DIAS_CREDITO_DEFAULT`, `COBROS_NOTIFY_EMAILS`,
credenciales de Firebase, Meta y WhatsApp.

### Script para clonar de Coolify

Hay un script en `scripts/coolify-clonar-env.mjs` que copia todas las variables
de un proyecto Coolify a otro (borra las que hereda de la empresa vieja).
Requiere `COOLIFY_URL`, `COOLIFY_TOKEN`, `SOURCE_APP_UUID`, `DEST_APP_UUID`.

---

## 4 · Dominio

`asociacionhernandariasazulgrana.neura.com.py` por HTTP en Coolify (Cloudflare
termina el TLS). Ya quedaron apuntando ahí en el repo:

- `NEXT_PUBLIC_APP_URL` (fallback en `src/lib/cobranzas/cobro-pendiente-notificar.ts`)
- `capacitor.config.ts` (`server.url`, `allowNavigation`, `cleartext: true`)
- `tutorial-erp/scripts/capture-tutorial.mjs`
