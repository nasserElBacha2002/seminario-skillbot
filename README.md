# SkillBot

Aplicación de práctica para aprender a resolver tareas cotidianas con IA. El usuario explora casos de uso, sigue un recorrido paso a paso y resuelve desafíos que le dan XP, suben sus habilidades y desbloquean logros.

Proyecto de seminario (UADE). React + Vite en el frontend, Supabase (Postgres) como base de datos.

## Puesta en marcha

Requiere Node 20.19+ o 22.12+ (lo que pide Vite 8).

```bash
npm install
cp .env.example .env.local   # completar con los valores del dashboard
npm run dev
```

La app queda en `http://localhost:5173`.

Las variables de entorno salen de **Project Settings → API** en el dashboard de Supabase:

```
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon public key>
```

La `anon key` es pública por diseño (la protección real son las políticas de RLS), pero igual no se commitea: `.env.local` está en el `.gitignore`.

### Scripts

| Comando | Qué hace |
|---|---|
| `npm run dev` | Servidor de desarrollo con recarga en caliente |
| `npm run build` | Build de producción en `dist/` |
| `npm run preview` | Sirve el build para revisarlo |

## Base de datos

El schema vive en [supabase/migrations/](supabase/migrations/) y los datos iniciales en [supabase/seed.sql](supabase/seed.sql). Hay que aplicar los dos, **en ese orden**, porque el seed inserta en tablas que crea la migración y usa la función `demo_profile_id()` que se define ahí.

### Opción A: SQL Editor del dashboard

1. Abrir el SQL Editor del proyecto.
2. Pegar y ejecutar [supabase/migrations/20261006232500_init_skillbot.sql](supabase/migrations/20261006232500_init_skillbot.sql).
3. En una query nueva, pegar y ejecutar [supabase/seed.sql](supabase/seed.sql).

Para copiar al portapapeles sin abrir los archivos (macOS): `pbcopy < supabase/seed.sql`.

Si después querés usar el CLI, hay que avisarle que esa migración ya corrió, porque aplicarla por el editor no la registra en el historial:

```bash
supabase migration repair --status applied 20261006232500
```

### Opción B: Supabase CLI

```bash
brew install supabase/tap/supabase
supabase login
supabase link --project-ref <project-ref>
supabase db push --include-seed
```

El `db push` necesita alcanzar Postgres directamente. La conexión directa de los proyectos nuevos es solo IPv6, así que en una red sin IPv6 hay que usar el pooler: el connection string exacto está en **Project Settings → Database → Connection string → Session pooler**.

### Desarrollo local contra una base propia

Con Docker corriendo:

```bash
supabase start          # levanta Postgres y PostgREST, aplica migración y seed
supabase db reset        # vuelve a aplicar todo desde cero
supabase stop
```

`supabase start` imprime la URL y la `anon key` locales, que van en `.env.local` para apuntar la app ahí.

## Schema

Nueve tablas, todas con RLS activado.

**Catálogos y configuración**

| Tabla | Contenido |
|---|---|
| `levels` | Umbrales de nivel: Principiante, Intermedio, Avanzado, Experto |
| `skills` | Taxonomía de habilidades a la que apuntan los casos de uso |
| `achievements` | Catálogo de logros con su ícono y descripción |

**Datos del usuario**

| Tabla | Contenido |
|---|---|
| `profiles` | Perfil, XP acumulado, nivel actual, objetivo e intereses |
| `user_skills` | Porcentaje por habilidad |
| `user_achievements` | Logros desbloqueados y cuándo |
| `use_case_progress` | Avance por caso de uso, con estado y fecha de completado |
| `challenge_attempts` | Historial de respuestas a los desafíos |
| `activity_days` | Una fila por día practicado; de acá se derivan la racha y la grilla semanal |

La función `add_xp(profile_id, amount)` suma XP y reajusta el nivel según los umbrales de `levels`, en una sola llamada.

### Sobre RLS y el login

El login es una demo: no usa Supabase Auth, solo escribe una marca en `localStorage`. Por eso todo cuelga de un único perfil con un id fijo, definido en la función `demo_profile_id()` y replicado en [src/lib/supabase.js](src/lib/supabase.js) como `DEMO_PROFILE_ID`. Las políticas permiten al rol `anon` leer y escribir **solo sobre ese perfil**.

Es deliberadamente abierto y alcanza para una demo académica, pero no sirve para producción. El día que se migre a Supabase Auth, el cambio es reemplazar `demo_profile_id()` por `auth.uid()` en las políticas y crear el perfil con un trigger sobre `auth.users`.

## Estructura del código

```
src/
  App.jsx                  Todas las páginas y el enrutado por estado
  data.js                  Catálogo de casos de uso (no está en la base)
  styles.css               Estilos
  lib/supabase.js          Cliente de Supabase y el id del perfil demo
  lib/queries.js           Lecturas y escrituras contra la base
  context/SkillbotData.jsx Provider: carga, estados derivados y mutadores
supabase/
  migrations/              Schema versionado
  seed.sql                 Esqueleto mínimo
  seeds/demo_progress.sql  Datos de demo opcionales (ver abajo)
```

El provider carga todo al montar y expone `data`, `loading`, `error` y los mutadores. Los valores derivados (racha, grilla semanal, progreso general, casos resueltos, habilidades practicadas) se calculan en `derive()` a partir de las filas, no se guardan.

## El catálogo de casos de uso

Los casos de uso **no están en la base**: viven en [src/data.js](src/data.js). La decisión es a propósito, porque el catálogo va a ser reemplazado por casos más avanzados.

Las tablas de progreso referencian cada caso por su `id` en una columna `text` **sin foreign key**, así que cambiar el catálogo no requiere ninguna migración. Cada caso declara además un campo `skill` con el id de la habilidad que entrena, para que resolverlo suba la barra correcta.

El recorrido detallado y el desafío están implementados para un solo caso, el señalado por `featuredUseCaseId`.

⚠️ **Antes de reemplazar el catálogo**, hay que borrar el progreso existente. Si quedan filas en `use_case_progress` o `challenge_attempts` apuntando a casos que ya no existen, la app las sigue contando en "casos resueltos" y en el progreso general. Para eso está [supabase/seeds/reset_progress.sql](supabase/seeds/reset_progress.sql).

## Seeds

[supabase/seed.sql](supabase/seed.sql) siembra **solo el esqueleto**: los niveles, el perfil demo en 0 XP y los catálogos de habilidades y logros. No inserta nada atado a casos de uso concretos, así que no deja filas para borrar después. Es idempotente.

Con eso la app arranca en cero: 0 XP, 0%, sin racha, habilidades en 0% y los cuatro logros bloqueados. Todo se llena practicando.

[supabase/seeds/reset_progress.sql](supabase/seeds/reset_progress.sql) devuelve el perfil a cero sin tocar el esqueleto. **No se aplica solo**: el `config.toml` carga únicamente `seed.sql`, hay que correrlo a mano.

### Cómo se desbloquean los logros

La lógica está en `completeChallenge` en [src/context/SkillbotData.jsx](src/context/SkillbotData.jsx):

| Logro | Condición |
|---|---|
| Primer caso resuelto | 1 caso completado |
| 3 días practicando | racha de 3 días |
| Explorador de IA | 3 casos de uso distintos empezados |
| 5 problemas resueltos | 5 casos completados |

## Problemas frecuentes

**"No pudimos conectarnos a la base" con el mensaje `Could not find the table 'public.levels'`**
La migración no se aplicó. Ver la sección de base de datos.

**"No pudimos conectarnos a la base" con el mensaje `The result contains 0 rows`**
La migración se aplicó pero el seed no. Falta correr [supabase/seed.sql](supabase/seed.sql): sin la fila del perfil, la consulta que la app hace con `.single()` falla.

**`Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY`**
No existe `.env.local` o está incompleto. Copiarlo de `.env.example`.

**Cambié `.env.local` y la app sigue usando los valores viejos**
Vite lee las variables al arrancar. Hay que reiniciar `npm run dev`.

**`supabase db push` da timeout o corta la conexión**
La red no llega a Postgres. Ver la nota sobre IPv6 y el pooler en la Opción B.
