# Neura ERP · Asociación Hernandarias Azulgrana

ERP de la Asociación Hernandarias Azulgrana: copia independiente de
[`neura-erp-sistemas-propio`](https://github.com/bartsilvera12-gif/neura-erp-sistemas-propio),
con su propio schema Postgres (`asociacionazulgranaerp`), su propia empresa y
su propio login. Mismo código, datos totalmente separados.

- **Puesta en marcha (SQL, variables de entorno, dominio):** [`DEPLOY_ASOCIACIONAZULGRANA.md`](DEPLOY_ASOCIACIONAZULGRANA.md)
- **Scripts SQL:** [`supabase/asociacionazulgrana/`](supabase/asociacionazulgrana/)
- **Documentación funcional heredada:** [`DOCUMENTACION_TECNICA.md`](DOCUMENTACION_TECNICA.md), [`docs/`](docs/)

| | |
|---|---|
| Stack | Next.js (App Router) · Supabase self-hosted · Coolify |
| Schema de datos | `asociacionazulgranaerp` (`APP_DB_SCHEMA`) |
| URL | `http://asociacionhernandariasazulgrana.neura.com.py` |
| Empresa id | `498add65-8616-412a-9ee7-d5d60adba136` |
| Admin | `admin@asociacionhernandariasazulgrana.com` |

## Desarrollo

```bash
npm install
npm run dev     # http://localhost:3000
npm run lint
```

Requiere un `.env.local` con al menos `APP_DB_SCHEMA=asociacionazulgranaerp`,
`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` y
`SUPABASE_SERVICE_ROLE_KEY`. La lista completa está en el documento de
puesta en marcha.

## Módulos habilitados

**Clientes · Cobranzas · Dashboard · Gestión Clientes · Planes · Reportes**

El menú sale de `empresa_modulos`, no del código: se amplía o se recorta desde
la base, sin tocar el repo.
