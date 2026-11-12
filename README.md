# SkillBot

Plataforma para emprendedores que quieren resolver problemas de Marketing, Finanzas y Administración con inteligencia artificial. El usuario completa un cuestionario de seis preguntas, recibe casos recomendados y, en las prácticas disponibles, resuelve desafíos que le dan XP, suben sus habilidades y desbloquean logros.

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
| `npm test` | Pruebas de prácticas, progreso, caso del día, búsqueda, onboarding y borrador |

## Base de datos

El schema vive en [supabase/migrations/](supabase/migrations/) y los datos iniciales (catálogo de casos de uso) en [supabase/seed.sql](supabase/seed.sql). Hay que aplicar las migraciones en orden y después el seed: el seed inserta en tablas que crean las migraciones. Los perfiles de usuario los crea el trigger de Auth, no el seed.

### Opción A: SQL Editor del dashboard

1. Abrir el SQL Editor del proyecto.
2. Pegar y ejecutar [supabase/migrations/20261006232500_init_skillbot.sql](supabase/migrations/20261006232500_init_skillbot.sql) (si la base ya existía, saltear este paso).
3. Pegar y ejecutar [supabase/migrations/20261012230000_use_case_catalog.sql](supabase/migrations/20261012230000_use_case_catalog.sql).
4. Pegar y ejecutar [supabase/migrations/20261020210000_guided_resolution.sql](supabase/migrations/20261020210000_guided_resolution.sql).
5. Pegar y ejecutar [supabase/migrations/20261020223000_resolve_use_case.sql](supabase/migrations/20261020223000_resolve_use_case.sql).
6. Pegar y ejecutar [supabase/migrations/20261021010000_practice_challenges.sql](supabase/migrations/20261021010000_practice_challenges.sql).
7. Pegar y ejecutar [supabase/migrations/20261021020000_award_xp_on_correct.sql](supabase/migrations/20261021020000_award_xp_on_correct.sql).
8. Pegar y ejecutar [supabase/migrations/20261027120000_supabase_auth.sql](supabase/migrations/20261027120000_supabase_auth.sql).
9. Pegar y ejecutar [supabase/migrations/20261027130000_profile_initials.sql](supabase/migrations/20261027130000_profile_initials.sql).
10. Pegar y ejecutar [supabase/migrations/20261027140000_secure_progress_writes.sql](supabase/migrations/20261027140000_secure_progress_writes.sql).
11. Pegar y ejecutar [supabase/migrations/20261027150000_update_profile_name.sql](supabase/migrations/20261027150000_update_profile_name.sql).
12. Pegar y ejecutar [supabase/migrations/20261027160000_harden_update_profile_name.sql](supabase/migrations/20261027160000_harden_update_profile_name.sql).
13. Pegar y ejecutar [supabase/migrations/20261027200000_help_community.sql](supabase/migrations/20261027200000_help_community.sql) (centro de ayuda).
14. Pegar y ejecutar [supabase/migrations/20261027210000_help_community_auth.sql](supabase/migrations/20261027210000_help_community_auth.sql).
15. Pegar y ejecutar [supabase/migrations/20261103120000_onboarding_model.sql](supabase/migrations/20261103120000_onboarding_model.sql).
16. En una query nueva, pegar y ejecutar [supabase/seed.sql](supabase/seed.sql). El seed deja 53 casos publicados: los 8 originales y 45 para emprendedores.

La activación de Auth (Email provider, Site URL, usuarios de prueba) está en [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

⚠️ La migración del catálogo **borra el progreso del perfil demo** (XP, logros, habilidades, racha y avance), porque apuntaba a los casos viejos de `src/data.js`, que ya no existen. La migración `20261027120000_supabase_auth` además **elimina el perfil demo** (y, por `ON DELETE CASCADE`, su progreso). El progreso pasa a ser por cuenta de Auth. El impacto está documentado en [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

Para copiar al portapapeles sin abrir los archivos (macOS): `pbcopy < supabase/seed.sql`.

Si después querés usar el CLI, hay que avisarle que esas migraciones ya corrieron, porque aplicarlas por el editor no las registra en el historial:

```bash
supabase migration repair --status applied 20261006232500 20261012230000 20261020210000 20261020223000 20261021010000 20261021020000 20261027120000 20261027130000 20261027140000 20261027150000 20261027160000 20261027200000 20261027210000 20261103120000
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

Veintiséis tablas en `public`, todas con RLS activado.

**Catálogos y configuración**

| Tabla | Contenido |
|---|---|
| `levels` | Umbrales de nivel: Principiante, Intermedio, Avanzado, Experto |
| `skills` | Taxonomía de habilidades a la que apuntan los casos de uso |
| `achievements` | Catálogo de logros con su ícono y descripción |

**Catálogo de casos de uso**

| Tabla | Contenido |
|---|---|
| `use_cases` | Ficha del caso: situación, habilidad, dificultad, tiempo, error típico, qué aprende, XP, estado (`published` o `reserve`) y `area` (`marketing`, `finanzas`, `administracion` o null en `estudiar-material`, que sirve para cualquier área) |
| `categories` / `use_case_categories` | Clasificación histórica por tipo de tarea. Sigue en la base, pero Explorar ya no la muestra como filtro. |
| `tools` / `use_case_tools` | IA recomendadas por caso, con rol (`primary`, `alternative`, `complement`) y el motivo |
| `use_case_steps` | Paso a paso, con prompt de ejemplo, checklist y confirmación obligatoria opcionales |
| `use_case_survey_tasks` | Tareas de la encuesta que cubre el caso y sus menciones |
| `use_case_challenges` / `challenge_options` | Desafíos de opción múltiple con feedback por opción; una sola correcta por desafío |

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

**Centro de ayuda**

| Tabla | Contenido |
|---|---|
| `help_topics` | Preguntas de la comunidad, con caso relacionado opcional y la respuesta marcada como solución |
| `help_replies` | Respuestas a cada pregunta |

Cualquiera lee el centro de ayuda. Cada cuenta publica con su propio perfil. El nombre del autor lo copia un trigger desde `profiles`, así que no se puede publicar con otro nombre. Solo el autor de la pregunta puede marcar la solución.

**Onboarding**

| Tabla | Contenido |
|---|---|
| `onboarding_options` | Vocabulario de áreas, problemas, herramientas, experiencia, objetivo y tiempo. Lectura pública. |
| `onboarding_responses` | Una fila por usuario. Solo el dueño la lee y la escribe. |
| `use_case_tags` | Etiquetas del caso, con ids de `onboarding_options`. No guardan datos personales. |

`complete_onboarding` guarda las seis respuestas del usuario autenticado (`auth.uid()`) y, si `profiles.onboarding_completed_at` era null, lo fija en la misma transacción. Una edición posterior no mueve esa fecha. El cliente no actualiza esa columna a mano.

`complete_practice_challenge(use_case_id, position, selected, day)` suma el XP de un desafío una sola vez. El servidor decide si la opción es correcta leyendo `challenge_options.is_correct`; el cliente no envía `p_correct`. Al terminar los tres, suma el bonus, marca el caso y sube la habilidad. Copiar el pedido o abrir una herramienta no suma XP. Si el caso ya estaba completado, no se vuelve a pagar.

### Sobre RLS y el login

El login y el registro usan Supabase Auth (`signInWithPassword` / `signUp` / `signOut`). `public.profiles.id` es el mismo UUID que `auth.users.id`. Un trigger `on_auth_user_created` crea el perfil al nacer la cuenta, con el `display_name` enviado en la metadata del signup.

Las políticas de datos privados permiten al rol `authenticated` leer **solo sus propias filas** (`id = auth.uid()` o `profile_id = auth.uid()`). `profiles.xp` y `profiles.level_id` no se pueden actualizar desde el cliente: los cambia `add_xp` vía RPC. El nombre se cambia con `update_profile_name`, que recalcula `initials` en SQL. El rol `anon` puede leer el catálogo público y no puede modificar progreso ni perfiles. Las RPCs de práctica (`resolve_use_case`, `complete_practice_challenge`) son `SECURITY DEFINER`, resuelven al usuario con `auth.uid()` y son la vía de escritura de XP, rewards y skills.

El perfil demo (Martín) ya no participa en runtime. Los pasos para aplicar la migración, crear usuarios de prueba y verificar aislamiento están en [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

## Estructura del código

```
src/
  App.jsx                  Gate de sesión y enrutado por estado
  pages/                   Login, registro, inicio, explorar, caso, progreso y perfil
  components/              Buscador, formulario dinámico, resultado y OnboardingWizard.jsx
  data/guidedCases.js      Fixture temporal. Borrarlo cuando la migración y el seed estén aplicados
  styles.css               Estilos
  lib/supabase.js          Cliente de Supabase con persistencia de sesión
  lib/queries.js           Lecturas y escrituras contra la base del usuario autenticado
  lib/onboarding.js        Preguntas, validación y normalización de respuestas
  lib/matching.js          Ranking de casos a partir de las respuestas
  lib/progress.js          Porcentaje de progreso, solo sobre prácticas completables
  context/Auth.jsx         Sesión, signIn, signUp y signOut
  context/SkillbotData.jsx Provider: carga, estados derivados y mutadores
supabase/
  migrations/              Schema versionado
  seed.sql                 Esqueleto y catálogo de casos de uso
  seeds/reset_progress.sql Vuelve a cero el progreso de un perfil (uuid obligatorio)
```

El provider carga todo al montar (catálogo, etiquetas y onboarding incluidos) y expone `data`, `loading`, `error`, `reload`, `recommendations`, `personalized` y los mutadores `toggleStep`, `beginPractice`, `restartPractice`, `finishChallenge`, `saveDisplayName` y `saveOnboarding`. Los valores derivados (racha, grilla semanal, progreso de prácticas, casos resueltos, habilidades practicadas) se calculan en `derive()` a partir de las filas, no se guardan. El ranking sale de `rankUseCases` en [src/lib/matching.js](src/lib/matching.js): corre en memoria, no se guarda en la base y se recalcula al editar las respuestas. El Inicio no muestra el ranking crudo: `selectRecommendations` elige seis casos, pone primero hasta tres prácticas que coinciden con un problema o con el objetivo, y deja afuera los casos empezados o completados, que ya tienen su propia sección. Las fórmulas están en [docs/fase-4-5-matching-dashboard.md](docs/fase-4-5-matching-dashboard.md).

## El catálogo de casos de uso

Los casos viven en la base y se cargan desde [supabase/seed.sql](supabase/seed.sql). El catálogo publicado tiene 53 casos: 8 originales y 45 nuevos (15 de Marketing, 15 de Finanzas y 15 de Administración). Los originales también tienen etiquetas y área, salvo `estudiar-material`, que queda sin área y solo aparece en Todas. Once tienen práctica completa (los 8 originales más `auditoria-instagram`, `diagnostico-financiero` y `pedidos-multicanal`). Los otros 42 son fichas: se pueden abrir, muestran la situación y el error frecuente, no habilitan desafíos y no entran en el porcentaje de progreso ni en el caso del día. Explorar filtra solo por área de negocio. Para agregar o editar un caso alcanza con tocar el seed y volver a correrlo. Las pantallas de detalle se arman con lo que trae cada caso.

- `use_cases.icon` es el nombre de un ícono de `lucide-react`. Tiene que estar en `caseIcons` en [src/components/icons.js](src/components/icons.js); si no, se muestra uno genérico.
- `use_cases.skill_id` define qué habilidad sube al resolverlo.
- Un paso con `requires_confirmation` bloquea los pasos siguientes y el desafío hasta que el usuario lo confirma con el texto de `confirmation_label` (por ejemplo, "Hice una copia de la planilla").
- Los casos con `status = 'reserve'` no le llegan a la app.

**Progreso de un caso:** queda en práctica al empezar y se completa al terminar los 3 desafíos. El XP se otorga ahí, no al armar el pedido. `src/data/guidedCases.js` y `src/data/practiceChallenges.js` son un respaldo temporal mientras la base no tenga la migración `20261021010000`. Después de aplicar las migraciones y el seed, el catálogo vive en Supabase.

Las tablas de progreso tienen foreign key hacia `use_cases`, así que no pueden quedar filas apuntando a casos que no existen. Las opciones del desafío se leen con `is_correct` para el feedback visual; el XP lo calcula la RPC en SQL.

## Seeds

[supabase/seed.sql](supabase/seed.sql) siembra el esqueleto (niveles, habilidades y logros) y el catálogo de casos de uso. No inserta usuarios ni progreso. Es idempotente; si se saca un paso o una opción del archivo, hay que borrar esa fila a mano.

Cada cuenta Auth arranca en cero: 0 XP, 0%, sin racha, habilidades en 0% y los cuatro logros bloqueados. Todo se llena practicando.

[supabase/seeds/reset_progress.sql](supabase/seeds/reset_progress.sql) devuelve a cero el progreso de **un** perfil. Hay que pegar el uuid en `target_profile_id`; el sentinela `00000000-...` aborta. **No se aplica solo**: el `config.toml` carga únicamente `seed.sql`. El reset global está en `supabase/seeds/reset_all_progress_destructive.sql` y no es el script estándar.

### Cómo se desbloquean los logros

La lógica está en `loadWithAchievements` en [src/context/SkillbotData.jsx](src/context/SkillbotData.jsx), que corre después de marcar un paso o responder un desafío:

| Logro | Condición |
|---|---|
| Primer caso resuelto | 1 caso completado |
| 3 días practicando | racha de 3 días |
| Explorador de IA | 3 casos de uso distintos empezados |
| 5 problemas resueltos | 5 casos completados |

## Estado del MVP

Terminado en código: autenticación, onboarding de seis preguntas, ranking en el cliente, inicio con recomendaciones, explorar por área, 53 casos, 11 prácticas, 42 fichas, progreso, XP, logros y centro de ayuda.

Verificado con pruebas automáticas, build y consultas de solo lectura a la base. El recorrido con una cuenta real (registro, cuestionario, práctica y progreso) no se ejecutó en esta entrega para no escribir datos en el proyecto remoto. El detalle está en [docs/fase-6-qa-final.md](docs/fase-6-qa-final.md).

No hay un despliegue de producción documentado. El bundle de producción supera 500 kB y Vite avisa por eso y por la directiva `use client` de `lucide-react`.

## Problemas frecuentes

**"No pudimos conectarnos a la base" con el mensaje `Could not find the table 'public.levels'`**
La migración no se aplicó. Ver la sección de base de datos.

**"No encontramos tu perfil"**
La cuenta Auth existe pero no hay fila en `public.profiles`. Falta aplicar [supabase/migrations/20261027120000_supabase_auth.sql](supabase/migrations/20261027120000_supabase_auth.sql) (trigger `handle_new_user`) o recargar si la cuenta se acaba de crear.

**`Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY`**
No existe `.env.local` o está incompleto. Copiarlo de `.env.example`.

**Cambié `.env.local` y la app sigue usando los valores viejos**
Vite lee las variables al arrancar. Hay que reiniciar `npm run dev`.

**`supabase db push` da timeout o corta la conexión**
La red no llega a Postgres. Ver la nota sobre IPv6 y el pooler en la Opción B.
