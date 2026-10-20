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

El schema vive en [supabase/migrations/](supabase/migrations/) y los datos iniciales (incluido el catálogo de casos de uso) en [supabase/seed.sql](supabase/seed.sql). Hay que aplicar las migraciones en orden y después el seed, porque el seed inserta en tablas que crean las migraciones y usa la función `demo_profile_id()` que se define ahí.

### Opción A: SQL Editor del dashboard

1. Abrir el SQL Editor del proyecto.
2. Pegar y ejecutar [supabase/migrations/20261006232500_init_skillbot.sql](supabase/migrations/20261006232500_init_skillbot.sql) (si la base ya existía, saltear este paso).
3. Pegar y ejecutar [supabase/migrations/20261012230000_use_case_catalog.sql](supabase/migrations/20261012230000_use_case_catalog.sql).
4. Pegar y ejecutar [supabase/migrations/20261020210000_guided_resolution.sql](supabase/migrations/20261020210000_guided_resolution.sql).
5. Pegar y ejecutar [supabase/migrations/20261020223000_resolve_use_case.sql](supabase/migrations/20261020223000_resolve_use_case.sql).
6. En una query nueva, pegar y ejecutar [supabase/seed.sql](supabase/seed.sql).

⚠️ La migración del catálogo **borra el progreso del perfil demo** (XP, logros, habilidades, racha y avance), porque apuntaba a los casos viejos de `src/data.js`, que ya no existen.

Para copiar al portapapeles sin abrir los archivos (macOS): `pbcopy < supabase/seed.sql`.

Si después querés usar el CLI, hay que avisarle que esas migraciones ya corrieron, porque aplicarlas por el editor no las registra en el historial:

```bash
supabase migration repair --status applied 20261006232500 20261012230000 20261020210000 20261020223000
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

Diecinueve tablas, todas con RLS activado.

**Catálogos y configuración**

| Tabla | Contenido |
|---|---|
| `levels` | Umbrales de nivel: Principiante, Intermedio, Avanzado, Experto |
| `skills` | Taxonomía de habilidades a la que apuntan los casos de uso |
| `achievements` | Catálogo de logros con su ícono y descripción |

**Catálogo de casos de uso**

| Tabla | Contenido |
|---|---|
| `use_cases` | Ficha del caso: situación, habilidad, dificultad, tiempo, error típico, qué aprende, XP y estado (`published` o `reserve`) |
| `categories` / `use_case_categories` | Categorías del filtro; un caso puede tener varias y una es la principal |
| `tools` / `use_case_tools` | IA recomendadas por caso, con rol (`primary`, `alternative`, `complement`) y el motivo |
| `use_case_steps` | Paso a paso, con prompt de ejemplo, checklist y confirmación obligatoria opcionales |
| `use_case_survey_tasks` | Tareas de la encuesta que cubre el caso y sus menciones |
| `use_case_challenges` / `challenge_options` | Desafío de opción múltiple con feedback por opción; una sola correcta por caso |

**Datos del usuario**

| Tabla | Contenido |
|---|---|
| `profiles` | Perfil, XP acumulado, nivel actual, objetivo e intereses |
| `user_skills` | Porcentaje por habilidad |
| `user_achievements` | Logros desbloqueados y cuándo |
| `use_case_progress` | Avance por caso de uso, con estado y fecha de completado |
| `use_case_step_progress` | Pasos marcados como hechos en cada caso |
| `challenge_attempts` | Historial de respuestas a los desafíos |
| `activity_days` | Una fila por día practicado; de acá se derivan la racha y la grilla semanal |

`resolve_use_case(use_case_id, day)` marca el caso, suma el XP del caso y sube la habilidad en una sola transacción. Llama a `add_xp`, que reajusta el nivel. Una segunda resolución del mismo caso no vuelve a sumar XP.

### Sobre RLS y el login

El login es una demo: no usa Supabase Auth, solo escribe una marca en `localStorage`. Por eso todo cuelga de un único perfil con un id fijo, definido en la función `demo_profile_id()` y replicado en [src/lib/supabase.js](src/lib/supabase.js) como `DEMO_PROFILE_ID`. Las políticas permiten al rol `anon` leer y escribir **solo sobre ese perfil**.

Es deliberadamente abierto y alcanza para una demo académica, pero no sirve para producción. El día que se migre a Supabase Auth, el cambio es reemplazar `demo_profile_id()` por `auth.uid()` en las políticas y crear el perfil con un trigger sobre `auth.users`.

## Estructura del código

```
src/
  App.jsx                  Login y enrutado por estado
  pages/                   Inicio, explorar, caso, desafío, progreso y perfil
  components/              Buscador, formulario dinámico y resultado
  data/guidedCases.js      Fixture temporal. Borrarlo cuando la migración y el seed estén aplicados
  styles.css               Estilos
  lib/supabase.js          Cliente de Supabase y el id del perfil demo
  lib/queries.js           Lecturas y escrituras contra la base
  context/SkillbotData.jsx Provider: carga, estados derivados y mutadores
supabase/
  migrations/              Schema versionado
  seed.sql                 Esqueleto y catálogo de casos de uso
  seeds/reset_progress.sql Vuelve el perfil demo a cero (ver abajo)
```

El provider carga todo al montar (catálogo incluido) y expone `data`, `loading`, `error` y los mutadores `toggleStep`, `markResolved` y `completeChallenge`. Los valores derivados (racha, grilla semanal, progreso general, casos resueltos, habilidades practicadas) se calculan en `derive()` a partir de las filas, no se guardan.

## El catálogo de casos de uso

Los casos viven en la base y se cargan desde [supabase/seed.sql](supabase/seed.sql). Para agregar o editar un caso alcanza con tocar el seed y volver a correrlo: no hace falta cambiar código. Las pantallas de detalle y desafío se arman con lo que trae cada caso.

- `use_cases.icon` es el nombre de un ícono de `lucide-react`. Tiene que estar en `caseIcons` en [src/App.jsx](src/App.jsx); si no, se muestra uno genérico.
- `use_cases.skill_id` define qué habilidad sube al resolverlo.
- Un paso con `requires_confirmation` bloquea los pasos siguientes y el desafío hasta que el usuario lo confirma con el texto de `confirmation_label` (por ejemplo, "Hice una copia de la planilla").
- Los casos con `status = 'reserve'` no le llegan a la app.

**Progreso de un caso:** cada paso marcado suma hasta el 80%. El 100% y el XP se otorgan la primera vez que se genera el resultado o se acierta el desafío, dentro de `resolve_use_case`. `src/data/guidedCases.js` es un respaldo temporal mientras la base no tenga las columnas nuevas. Después de aplicar las migraciones y el seed, hay que eliminarlo: el catálogo vive solo en Supabase.

Las tablas de progreso tienen foreign key hacia `use_cases`, así que no pueden quedar filas apuntando a casos que no existen. Las opciones del desafío se leen con `is_correct` incluido porque la corrección se hace en el frontend: en la demo, la respuesta es visible para quien inspeccione la red.

## Seeds

[supabase/seed.sql](supabase/seed.sql) siembra el esqueleto (niveles, perfil demo en 0 XP, habilidades y logros) y el catálogo de casos de uso. No inserta progreso del usuario. Es idempotente; si se saca un paso o una opción del archivo, hay que borrar esa fila a mano.

Con eso la app arranca en cero: 0 XP, 0%, sin racha, habilidades en 0% y los cuatro logros bloqueados. Todo se llena practicando.

[supabase/seeds/reset_progress.sql](supabase/seeds/reset_progress.sql) devuelve el perfil a cero sin tocar el esqueleto. **No se aplica solo**: el `config.toml` carga únicamente `seed.sql`, hay que correrlo a mano.

### Cómo se desbloquean los logros

La lógica está en `loadWithAchievements` en [src/context/SkillbotData.jsx](src/context/SkillbotData.jsx), que corre después de marcar un paso o responder un desafío:

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
