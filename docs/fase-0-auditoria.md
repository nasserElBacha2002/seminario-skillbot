# SkillBot — Fase 0: auditoría y plan técnico

Fecha de revisión del repositorio: 3 de noviembre de 2026.

Esta fase es solo análisis. No se modificó código de producción, no se crearon migraciones, no se tocó Supabase, no se instalaron dependencias y no se ejecutaron tests ni `npm run build`.

Convención del informe:

- **Hecho:** verificado leyendo archivos de este repositorio.
- **Propuesta:** diseño recomendado para las fases siguientes. No está implementado.
- **No comprobado:** no se pudo verificar desde el código. No tratarlo como cierto.

---

## 1. Resumen del estado actual

SkillBot es una SPA de React 19 + Vite que practica resolución de tareas con IA. El usuario inicia sesión con Supabase Auth, explora un catálogo, arma un pedido a partir de sus datos y completa tres desafíos por caso. El progreso (XP, habilidades, racha, logros) vive en Postgres.

El producto actual no está orientado a emprendedores ni a las áreas Marketing, Finanzas y Administración. No hay onboarding ni motor de recomendaciones.

El catálogo publicado en `supabase/seed.sql` tiene **8 casos**, no 45. Los ocho tienen guía completa: pasos, campos, plantilla de prompt y tres desafíos.

La deuda más importante para la Fase 1 no es la falta de tablas de onboarding. Es que **el frontend y la documentación describen un esquema de Auth más nuevo que el SQL que está en el repositorio**. Cinco migraciones citadas en `README.md` y `SUPABASE_SETUP.md` no existen como archivos. Una instalación limpia con los SQL presentes no crea `update_profile_name` y deja `complete_practice_challenge` con el parámetro `p_correct`, que el cliente ya no envía.

## 2. Arquitectura identificada

### Frontend

No hay React Router. `src/App.jsx` elige la pantalla con `useState`.

```
AuthProvider
  Gate
    sin sesión o recuperación de contraseña → AuthFlow
    con sesión → SkillbotDataProvider → Shell
```

Pantallas de `Shell`: `inicio`, `explorar`, `detalle` / `desafio` (la misma `UseCasePage`), `progreso`, `ayuda`, `perfil`.

El estado de negocio se carga entero al montar `SkillbotDataProvider` (`src/context/SkillbotData.jsx` → `src/lib/queries.js`). Los derivados (racha, semana, progreso general) se calculan en `derive()` y no se persisten.

Borradores del formulario, resultado del pedido y sesión de práctica van a `localStorage`, con clave `skillbot:<uid>:...` (`src/lib/storage.js`). El progreso durable va a Supabase.

Estilos: un solo archivo, `src/styles.css`, con breakpoints en 850px y 570px. `index.html` declara `viewport`. No hay Tailwind en el CSS aunque `tailwindcss` figura en `package.json`.

### Backend

Cliente único en `src/lib/supabase.js`: `createClient` con `persistSession`, `autoRefreshToken` y `detectSessionInUrl`. Variables: `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` (`.env.example`). No hay `service_role` en el cliente.

`supabase/config.toml` apunta el Auth local a `http://localhost:5173`, con signup habilitado, confirmación de email desactivada y contraseña mínima de 8 caracteres. Eso aplica a `supabase start`, no al proyecto remoto.

### Dependencias fijadas en el lockfile

| Paquete | Versión en `package-lock.json` |
|---|---|
| vite | 8.3.1 |
| react / react-dom | 19.3.0 |
| @supabase/supabase-js | 2.117.2 |
| tailwindcss | 4.3.3 |

`package.json` declara `"vite": "latest"` y `"react": "latest"`. Los scripts son solo `dev`, `build` y `preview`. No hay script de test. No hay archivos `*.test.*` ni `*.spec.*`. No hay `vite.config.js` ni `vite.config.ts`. `@vitejs/plugin-react` está en dependencias y no está referenciado por ningún archivo del repo.

**No comprobado:** si `npm run dev` y `npm run build` pasan con ese `package.json` en esta máquina. No se ejecutaron.

## 3. Inventario de funcionalidades existentes

### Autenticación — reutilizar

| Función | Dónde |
|---|---|
| Login con email y contraseña | `src/pages/Login.jsx`, `src/context/Auth.jsx` (`signInWithPassword`) |
| Registro con `display_name` en metadata | `src/pages/Register.jsx`. El perfil lo crea el trigger, no el cliente |
| Recuperación y cambio de contraseña | `src/pages/ForgotPassword.jsx`, `src/pages/UpdatePassword.jsx` |
| Cierre de sesión | `src/pages/ProfilePage.jsx` |
| Edición de nombre | `ProfilePage` → `updateProfileName()` → RPC `update_profile_name` |

El trigger `handle_new_user` está en `supabase/migrations/20261027120000_supabase_auth.sql`. Inserta `profiles` con `goal` genérico, `interests = '{}'`, `xp = 0` y `level_id = 'principiante'`.

`profile_initials` de esa misma migración, para un solo nombre, toma **las dos primeras letras** (`left(words[1], 2)`). La documentación describe un comportamiento distinto (una sola letra) que correspondería a un archivo que no está en el repo.

### Perfil — reutilizar la pantalla, no el modelo de preferencias

`profiles` ya tiene `goal text` e `interests text[]`. La UI los muestra y no permite editarlos (`src/pages/ProfilePage.jsx`). El objetivo que se ve es el texto fijo del trigger. Los intereses arrancan vacíos, así que la lista se renderiza vacía.

Eso no alcanza para seis preguntas con selecciones múltiples, problemas concretos, herramientas, experiencia y tiempo. No hay columna de estado de onboarding.

### Catálogo y exploración — reutilizar

`src/pages/ExplorePage.jsx` + `src/components/CaseBrowser.jsx`: búsqueda (`src/lib/search.js`, con sinónimos) y filtro por categoría. Las categorías salen de la tabla `categories`. Hoy son tipos de tarea, no áreas de negocio:

| id | nombre |
|---|---|
| presentaciones | Presentaciones |
| datos | Datos y análisis |
| estudio | Estudio |
| organizacion | Organización y productividad |
| contenido | Contenido y redacción |
| automatizacion | Automatización |

Un caso puede tener varias categorías (`use_case_categories`, una sola `is_primary`).

RLS: `use_cases` publicados son legibles por `anon` y `authenticated`. `status = 'reserve'` no llega a la app.

### Resolución guiada — reutilizar

`src/pages/UseCasePage.jsx` exige práctica completa para habilitar el botón:

```text
ready = hay campos de práctica && hay exactamente 3 desafíos && hay output_template
```

Si falta algo, muestra: «Este caso todavía no tiene la práctica armada.» Ese hueco ya permite publicar fichas sin guía.

Flujo cuando está listo: intro → formulario (`DynamicCaseForm`) → guía y pasos (`CaseGuide`, `CaseSteps`) → tres rondas (`PracticeRound`) → resultado y prompt (`CaseResult`, `src/lib/template.js`).

XP de la práctica: `completePracticeChallenge` en `src/lib/queries.js` llama la RPC **sin** `p_correct`. La corrección visual usa `is_correct` que viene en el select del catálogo.

`resolveUseCase` está exportada en `queries.js` y **ningún componente la llama**. `src/pages/ChallengePage.jsx` devuelve `null` y no está importada.

### Progreso — reutilizar la tabla existente

No existe `user_case_progress`. El progreso es `use_case_progress` (`profile_id`, `use_case_slug`, `progress`, `status`, `completed_at`). Tablas relacionadas: `use_case_step_progress`, `practice_rewards`, `challenge_attempts`, `user_skills`, `user_achievements`, `activity_days`.

Logros, calculados en el cliente después de practicar (`loadWithAchievements`): primer caso, racha de 3, 3 casos empezados, 5 casos completados. Los ids están en el seed y no deben cambiarse sin tocar `SkillbotData.jsx`.

Inicio (`src/pages/HomePage.jsx`): caso del día (`src/lib/daily.js`), casos empezados, casos completados. No hay recomendaciones.

### Centro de ayuda

Tablas `help_topics` y `help_replies` (`supabase/migrations/20261027200000_help_community.sql`). La UI está en `src/pages/HelpPage.jsx` y `src/components/Community.jsx`.

Las políticas de escritura siguen exigiendo `profile_id = demo_profile_id()` (`11111111-1111-4111-8111-111111111111`). La migración de Auth borra ese perfil si no está en `auth.users`. El comentario de la migración de ayuda dice que el reemplazo por `auth.uid()` queda pendiente. `README.md` cita `20261027210000_help_community_auth.sql`, que **no está en el repositorio**.

### Los 8 casos publicados

Todos `status = 'published'`, con pasos, encuesta, herramientas, plantilla, campos y 3 desafíos en `supabase/seed.sql`:

| id | título | skill | categoría principal |
|---|---|---|---|
| ventas-sin-formulas | Entender mis ventas sin saber fórmulas | analisis | datos |
| reporte-campania | Reporte de campaña para un cliente | comunicacion | contenido |
| reunion-seguimiento | De la reunión al seguimiento | organizacion | organizacion |
| estudiar-material | Estudiar un material largo y armar un plan | investigacion | estudio |
| documento-presentacion | Del documento a la presentación | comunicacion | presentaciones |
| imagenes-redes | Imágenes para redes que no parezcan hechas con IA | creatividad | contenido |
| automatizar-tarea | Automatizar una tarea repetitiva sin saber programar | automatizacion | automatizacion |
| comparar-decidir | Comparar opciones y decidir con información confiable | investigacion | datos |

Habilidades: comunicación, investigación, organización, creatividad, análisis, automatización.

Herramientas: ChatGPT, Claude, Gemini, Copilot, NotebookLM, Google Apps Script, Canva. `tools.url` se agrega en `20261020210000_guided_resolution.sql`.

Iconos aceptados por la UI: `src/components/icons.js` (`Table2`, `ChartColumn`, `ClipboardList`, `BookOpen`, `Presentation`, `Image`, `Workflow`, `Scale`). Cualquier otro nombre cae en `Sparkles`.

Respaldo temporal si el schema remoto es viejo: `src/data/guidedCases.js` y `src/data/practiceChallenges.js`. `queries.js` avisa por consola y pide borrarlos cuando la base esté al día. `src/data.js`, citado en comentarios de migraciones viejas, **no existe**.

## 4. Problemas y deuda técnica relevantes

### Documentación adelantada al SQL

Archivos citados y ausentes:

| Archivo citado | Dónde se cita | Efecto que la doc le atribuye y que el SQL del repo no aplica |
|---|---|---|
| `supabase/migrations/20261027130000_profile_initials.sql` | README, SUPABASE_SETUP | Iniciales de una letra para un solo nombre |
| `supabase/migrations/20261027140000_secure_progress_writes.sql` | README, SUPABASE_SETUP, `PracticeRound.jsx` | `profiles` solo SELECT; RPCs `SECURITY DEFINER`; `add_xp(p_amount)`; `complete_practice_challenge` sin `p_correct` |
| `supabase/migrations/20261027150000_update_profile_name.sql` | README, SUPABASE_SETUP | RPC `update_profile_name` |
| `supabase/migrations/20261027160000_harden_update_profile_name.sql` | README, SUPABASE_SETUP | `search_path` vacío en esa RPC |
| `supabase/migrations/20261027210000_help_community_auth.sql` | README | Auth en el centro de ayuda |
| `supabase/seeds/reset_all_progress_destructive.sql` | README, SUPABASE_SETUP, comentario de `reset_progress.sql` | Reset global |

Lo que sí está en `20261027120000_supabase_auth.sql`:

- Borra `profiles` que no existen en `auth.users` (incluye el demo).
- FK `profiles.id` → `auth.users.id`.
- Políticas «own …» para el rol `authenticated`, con **UPDATE** de `profiles` y **ALL** sobre tablas de progreso.
- `add_xp(p_profile_id uuid, p_amount integer)`, `SECURITY INVOKER`.
- `complete_practice_challenge(..., p_correct boolean, ...)`, `SECURITY INVOKER`. El cliente decide la corrección.
- `resolve_use_case` reescrita para `auth.uid()`, también `SECURITY INVOKER`.

`README.md` dice que hay diecinueve tablas. Contando `CREATE TABLE` de las migraciones presentes hay **23**: las 9 iniciales, 10 del catálogo (incluye `use_case_step_progress`), `use_case_fields`, `practice_rewards`, `help_topics`, `help_replies`.

### Migraciones históricas que borran datos

No hay que reejecutarlas sobre una base con usuarios reales.

- `20261012230000_use_case_catalog.sql` hace `DELETE` de progreso, intentos, actividad, logros y skills, y pone XP en 0. En una base nueva las tablas están vacías. En una base ya poblada, destruye progreso.
- `20261027120000_supabase_auth.sql` borra perfiles huérfanos y, por `ON DELETE CASCADE`, su progreso.

### Otras deudas

- El centro de ayuda, en una instalación limpia de estos SQL, no deja publicar al usuario autenticado: la policy compara contra el UUID demo.
- La RPC de práctica que el cliente llama no coincide con la firma SQL del repo. `PracticeRound.jsx` indica aplicar una migración que no existe.
- La edición de nombre llama una RPC que no está definida en el repo.
- `is_correct` viaja al cliente en el select de `challenge_options`. Quien inspecciona la red ve la respuesta. La documentación ya lo admite para el esquema viejo; el endurecimiento que lo movería al servidor no está en los archivos.
- No hay tests automatizados.
- `ChallengePage.jsx` y `resolveUseCase` quedaron sin uso.
- Tailwind y el plugin de React están declarados y no cableados. El CSS real es `src/styles.css`.

### No comprobado: proyecto remoto

No se consultó el dashboard ni la base remota. Es posible que esas migraciones faltantes se hayan pegado a mano en Supabase y no se hayan commiteado. Hasta comprobarlo, el contrato seguro es el de los archivos del repo, no el de `SUPABASE_SETUP.md`.

Tampoco se comprobó si hay filas de usuarios reales cuyo progreso haya que preservar. El código sí está preparado para tenerlas: cada cuenta tiene su `profiles.id = auth.users.id` y progreso por `profile_id`.

## 5. Modelo de datos recomendado

**Propuesta.** Adaptar lo que existe. No crear un segundo catálogo ni una tabla `user_case_progress`.

### Reutilizar sin duplicar

| Necesidad del plan | Tabla real | Decisión |
|---|---|---|
| Ficha del caso | `use_cases` | Extender. No crear otra tabla de casos |
| Varias categorías por caso | `categories`, `use_case_categories` | Mantener para el filtro actual |
| Herramientas | `tools`, `use_case_tools` | Mantener |
| Guía, pasos, desafíos | `use_case_steps`, `use_case_fields`, `use_case_challenges`, `challenge_options` | Mantener. Un caso de catálogo puede no tenerlas |
| Progreso | `use_case_progress` | Mantener el nombre y la clave `(profile_id, use_case_slug)` |
| Perfil básico | `profiles` | Sumar estado de onboarding. No guardar ahí las seis respuestas crudas |

### Tablas nuevas, porque no hay equivalente

**`onboarding_responses`** — una fila por usuario.

`profiles.goal` es un texto y `profiles.interests` es un array de strings sin esquema. No representan problemas, herramientas, experiencia, objetivo prioritario y tiempo, ni permiten recalcular sin perder el detalle. Propuesta de columnas:

- `profile_id uuid` PK, FK a `profiles(id)` on delete cascade
- `areas text[]` — Marketing, Finanzas, Administración; puede haber más de una
- `problems text[]` — ids estables de problemas, no texto libre
- `tools text[]` — ids de herramientas que la persona dice usar
- `ai_experience text` — un valor de un conjunto cerrado
- `primary_goal text`
- `available_time text`
- `updated_at timestamptz`

Actualizar es un `upsert`. No toca `use_case_progress`.

**`profiles.onboarding_completed_at timestamptz`** nullable. `null` significa que falta el cuestionario. Usuarios ya existentes quedan en `null` sin perder XP ni casos. Completar o editar el cuestionario solo escribe esta marca y `onboarding_responses`.

**`use_case_tags`** — etiquetas de matching, distintas de las categorías de exploración.

- `use_case_id`, `kind`, `value`
- `kind` cerrado: `problem`, `goal`, `area`, `tool`, `experience`, `time`
- PK `(use_case_id, kind, value)`
- Lectura pública, igual que el resto del catálogo. Sin datos de usuario

No hace falta una tabla de recomendaciones materializada en el MVP: el ranking se calcula en el cliente a partir del catálogo y de las respuestas. Si más adelante hiciera falta auditar el ranking en el servidor, se puede agregar sin cambiar el algoritmo.

### Áreas de negocio y categorías actuales

No reemplazar las seis categorías de tarea por Marketing / Finanzas / Administración. `CaseBrowser` pinta un chip por cada fila de `categories`. Mezclar las dos taxonomías en la misma tabla cambia el filtro de Explorar.

**Propuesta:** columna `use_cases.area text` con check `('marketing', 'finanzas', 'administracion')`, nullable al principio para no romper los 8 casos actuales. El filtro nuevo del dashboard usa `area`. El filtro de Explorar puede seguir usando `categories` hasta que la Fase 5 defina si conviven.

Alternativa equivalente: tabla `areas` y `use_case_areas`, si un caso debiera pertenecer a más de un área. El plan pide 15 casos por categoría y evaluación individual, así que **un área principal por caso** alcanza. Un caso puede igual así matchear problemas de otra área vía `use_case_tags`.

### Qué no poner en la ficha todavía

La ficha uniforme del plan (título, problema, objetivo, categoría, dificultad, herramientas, datos requeridos, duración, entregable) cabe casi toda en columnas que ya existen:

| Pedido | Columna actual |
|---|---|
| Título | `title` |
| Problema / situación | `situation` + tags `problem` |
| Objetivo | tag `goal`; el texto visible puede ser `summary` |
| Categoría de negocio | `area` nueva |
| Dificultad | `difficulty` (`Fácil`, `Media`, `Avanzada`) |
| Duración | `estimated_minutes` |
| Herramientas | `use_case_tools` |
| Qué se aprende | `learning_outcome` |
| Entregable guiado | `output_template` + `use_case_fields` |

«Datos requeridos» y «entregable» de una ficha sin guía pueden ser texto en columnas nuevas (`required_inputs text`, `deliverable text`) para no obligar a crear `use_case_fields` en los 37 casos que no van a tener práctica en el MVP. **Propuesta, a confirmar en la Fase 2.**

### RLS propuesta para lo nuevo

- `onboarding_responses`: `SELECT` / `INSERT` / `UPDATE` solo si `profile_id = auth.uid()`. Sin acceso `anon`. Sin `DELETE` desde el cliente, o `DELETE` solo de la propia fila si se quiere permitir vaciar el cuestionario. No guardar respuestas de otras personas en el select del catálogo.
- `use_case_tags`: `SELECT` para `anon` y `authenticated` con `using (true)`, igual que `use_case_categories`. Sin escritura para esos roles.
- No abrir `UPDATE` nuevo sobre `profiles.xp` ni `level_id`.

Antes de escribir esas policies, la Fase 1 tiene que decidir si reconcilia el hueco de `20261027140000`. Si el remoto ya revocó el `UPDATE` de `profiles`, un `ALTER` que solo agrega `onboarding_completed_at` es seguro. Si el remoto sigue el SQL del repo, el cliente todavía puede actualizar XP. Eso es deuda previa, no un requisito del onboarding. **No mezclar el cierre de esa deuda con el modelo nuevo salvo que se autorice como alcance explícito.**

### Migraciones

Archivos nuevos, aditivos, con `add column if not exists` / `create table if not exists`. No repetir los `DELETE` de `20261012230000` ni de `20261027120000`. Deben poder correr después de las ocho migraciones que sí están en `supabase/migrations/`, sobre una base vacía (`supabase db reset`) y sobre una base que ya tiene los 8 casos y progreso de usuarios.

Semilla de tags y casos nuevos en `supabase/seed.sql`, que ya es idempotente (`on conflict do update`). `config.toml` solo carga `./seed.sql`.

## 6. Propuesta del motor de matching

**Propuesta.** Función pura en JavaScript, sin llamada a un modelo. Entrada: respuestas normalizadas + lista de casos con tags. Salida: los mismos casos con `score` (0–100) y `reasons` (textos cortos). Sin efectos y sin Supabase, para poder testearla cuando exista un runner.

Pesos del plan, aplicados por caso y no por área:

| Señal | Peso |
|---|---|
| Intersección de `problems` con tags `problem` del caso | 40 |
| `primary_goal` igual a un tag `goal` | 25 |
| `areas` contiene `use_cases.area` o un tag `area` | 20 |
| Intersección de herramientas y de experiencia | 10 |
| `available_time` compatible con el tag `time` o con `estimated_minutes` | 5 |

Reglas:

1. Un área elegida suma solo a los casos de esa área (el 20 %). No copia el puntaje al resto de la categoría. Un caso de Finanzas puede quedar arriba de uno de Marketing si el problema coincide y el área no.
2. Si el usuario no eligió un eje, ese peso se reparte en cero para todos. No se premia al caso por tener el tag vacío.
3. Empate: mayor `score`, después menor `sort_order`, después `id` ascendente. Mismo input, mismo orden.
4. Cada razón sale de un tag que efectivamente sumó. Ejemplo de forma: «Te recomendamos este caso porque marcaste dificultades para controlar tus gastos.» El texto vive junto al id del problema, no se inventa en la UI a partir del título.
5. El dashboard muestra un recorte (propuesta: 6). Explorar sigue listando los 45, con el score como dato opcional, no como filtro obligatorio.
6. Cambiar respuestas recalcula en memoria. No invalida `use_case_progress`.

Los 8 casos actuales no tienen tags. Hasta la Fase 2 su score de problema y objetivo será 0, y solo podrían sumar área si se les asigna una. No ocultarlos por eso.

**No comprobado y fuera de esta fase:** la lista cerrada de ids de problemas, objetivos, niveles de experiencia y franjas de tiempo. Hace falta definirla antes de escribir el seed de tags. Si no, el motor y el cuestionario no van a coincidir.

## 7. Plan de implementación por fases

El orden del plan se mantiene. Cada fase se abre en una conversación nueva y no empieza sin aceptar la anterior.

### Fase 1 — Modelo y migraciones

Objetivo: poder guardar respuestas y tags sin perder progreso.

Incluye: columnas y tablas de la sección 5, RLS, grants, comentario en `SUPABASE_SETUP.md` solo de esas migraciones.

No incluye: los 45 casos, la UI del cuestionario, el ranking, ni el arreglo de `update_profile_name` / `p_correct` / ayuda, salvo que se autorice aparte. Esas tres fallas ya existen y conviene registrarlas como prerrequisito conocido, no esconderlas dentro del onboarding.

Aceptación:

- `supabase db reset` aplica las migraciones viejas y las nuevas, y después el seed actual.
- Las tablas de progreso existentes no cambian de nombre ni de clave.
- Un usuario autenticado lee y escribe solo su fila de `onboarding_responses`.
- `anon` lee tags y no lee respuestas.
- No hay sentencias `DELETE` de progreso en las migraciones nuevas.

### Fase 2 — Catálogo

Objetivo: 15 fichas por área, etiquetadas, más los 8 casos guiados que ya funcionan.

Decisión que hay que cerrar al empezar, porque cambia el conteo: los 8 actuales **no** se borran y **no** cuentan solos como los 45. Se conservan como prácticas ya construidas. Los 45 son fichas nuevas de emprendedores, o un subconjunto de los 8 se reclasifica y se completa hasta 15 por área. Reclasificar `estudiar-material` o `documento-presentacion` como Marketing, Finanzas o Administración sería forzado. **Propuesta:** conservarlos publicados, fuera del cupo de 15, hasta decidir si pasan a `reserve`.

De los 45, solo una ficha por área llega con campos, plantilla y 3 desafíos. Las otras 42 quedan `published` sin práctica. La UI ya muestra el aviso de práctica no armada. La Fase 5 puede cambiar ese texto; la Fase 2 no tiene por qué generar 45 guías.

Aceptación:

- 15 ids por área, sin duplicar ids de los 8.
- Cada caso nuevo tiene tags de los mismos vocabularios que el cuestionario.
- Re-correr el seed no duplica filas ni borra `use_case_progress` de ids que siguen existiendo.
- Los 8 casos siguen teniendo 3 desafíos.

### Fase 3 — Onboarding

Objetivo: seis pasos, ida y vuelta, validación, alta y edición.

Encajarlo en `Gate` (`src/App.jsx`): con sesión y `onboarding_completed_at` nulo, mostrar el cuestionario antes de `Shell`. Un control de «ahora no» puede escribir una marca explícita si se quiere no bloquear a quienes ya usan la app. **Propuesta:** no bloquear en silencio a las cuentas existentes la primera vez que se despliegue; mostrar el cuestionario y permitir posponerlo. Posponer no borra progreso.

Edición posterior desde Perfil, reutilizando el mismo formulario. Guardar con `upsert`. Mobile: los breakpoints de 570px ya existen; las pantallas nuevas tienen que usarlos, no un layout aparte.

Aceptación:

- Se pueden elegir áreas y problemas de más de una categoría en el mismo envío.
- Recargar a mitad del cuestionario no pierde lo ya guardado, o el paso se completa solo al final y el borrador queda en `localStorage` con el uid. Elegir una de las dos en la implementación y testear esa.
- Editar respuestas no modifica `use_case_progress`, XP ni logros.
- Registro, login, recuperación y logout siguen en sus páginas actuales.

### Fase 4 — Motor

Objetivo: ranking determinista y explicable.

Agregar un runner de tests en esta fase (no hay ninguno). La función no importa `supabase`.

Aceptación:

- Dos casos de la misma área pueden quedar en posiciones distintas.
- Un caso de otra área puede superar a uno del área elegida si el problema pesa más.
- Empate de score ordena por `sort_order` y luego por `id`.
- La explicación cita un problema que está en las respuestas.
- Cambiar una respuesta cambia el orden sin tocar filas de progreso.

### Fase 5 — Dashboard y catálogo

Objetivo: del registro a abrir una guía, con recomendaciones mezcladas.

`HomePage` hoy es «caso del día» + «seguí donde quedaste». Sumar un bloque de recomendaciones. No sacar el seguimiento ni el caso del día: el plan pide conservar el progreso y la experiencia actual.

`ExplorePage` sigue mostrando todos los casos `published`, con filtro por área además del filtro por tipo de tarea, si ambas taxonomías conviven.

Aceptación:

- El inicio muestra casos de más de un área cuando las respuestas lo justifican.
- Explorar no esconde casos de áreas no elegidas.
- Abrir uno de los 8 casos sigue el flujo de práctica.
- Abrir una ficha sin guía no rompe la pantalla: se ve la ficha y no el botón de práctica.
- 570px: cuestionario, inicio y explorar se pueden recorrer sin solapar la barra lateral (el drawer ya existe en `Layout`).

### Fase 6 — QA y documentación

Objetivo: alinear `README.md` y `SUPABASE_SETUP.md` con los archivos reales, incluida la lista de migraciones que faltaban o que se decida no recuperar.

Aceptación: el checklist de 13 puntos del plan, más una nota explícita de qué se comprobó en local y qué sigue sin comprobar en el remoto.

## 8. Archivos a crear, modificar o reutilizar

### Reutilizar tal cual en las fases de producto

- `src/context/Auth.jsx`, `src/pages/Login.jsx`, `src/pages/Register.jsx`, `src/pages/ForgotPassword.jsx`, `src/pages/UpdatePassword.jsx`, `src/pages/AuthFlow.jsx`, `src/components/AuthLayout.jsx`
- `src/lib/supabase.js`
- `src/context/SkillbotData.jsx` y las escrituras de progreso en `src/lib/queries.js`
- `src/pages/UseCasePage.jsx` y componentes del flujo (`DynamicCaseForm`, `CaseGuide`, `CaseSteps`, `PracticeRound`, `CaseResult`)
- `src/pages/ProgressPage.jsx`
- `src/components/Layout.jsx`, `UseCaseCard.jsx`, `CaseBrowser.jsx`, `src/lib/search.js`
- `src/lib/storage.js` para borradores por usuario
- Tablas y RPCs de progreso ya migradas

### Modificar cuando llegue la fase indicada

| Fase | Archivos |
|---|---|
| 1 | Nueva migración en `supabase/migrations/`. Después, `SUPABASE_SETUP.md` solo en la parte de orden de migraciones |
| 2 | `supabase/seed.sql`. Si hace falta un icono nuevo, `src/components/icons.js` |
| 3 | `src/App.jsx` (`Gate`), página nueva de onboarding, `src/pages/ProfilePage.jsx`, funciones nuevas en `src/lib/queries.js`, bloques en `src/styles.css` |
| 4 | Módulo nuevo, por ejemplo `src/lib/matching.js`, y tests nuevos. `package.json` solo si se agrega el runner |
| 5 | `src/pages/HomePage.jsx`, `src/components/CaseBrowser.jsx`, `src/pages/ExplorePage.jsx`, `src/pages/UseCasePage.jsx` (texto de ficha sin práctica y razones) |
| 6 | `README.md`, `SUPABASE_SETUP.md` |

### No crear

- Una tabla `user_case_progress` paralela a `use_case_progress`
- Tres perfiles por usuario
- Un segundo catálogo en `src/data/`
- 45 guías generadas para completar cantidad
- Un cliente de IA para el ranking

### Borrar solo cuando se confirme que la base remota ya no cae al fallback

`src/data/guidedCases.js`, `src/data/practiceChallenges.js`, y el ramo `legacySchema` de `queries.js`. No en la Fase 1. Si el remoto todavía no tiene `use_case_fields`, borrarlos deja la app sin práctica.

## 9. Riesgos y medidas

| Riesgo | Medida |
|---|---|
| Tratar `SUPABASE_SETUP.md` como el esquema real y escribir una migración que asume `add_xp(integer)` o `update_profile_name` | La Fase 1 lee el SQL de `20261027120000` como contrato. Si se quiere el esquema documentado, primero hay que recuperar esas migraciones en una fase propia y comprobar el remoto |
| Una migración nueva repite los `DELETE` históricos | Revisión del diff: prohibido borrar progreso, perfiles o casos |
| Reemplazar categorías de tarea por las tres áreas y romper Explorar | Columna `area` separada de `categories` |
| Publicar 37 casos `reserve` y que no se vean | `reserve` está filtrado por RLS y por el cliente. Las fichas del catálogo van en `published` |
| Un caso sin 3 desafíos rompe el detalle | Ya está cubierto por `ready` en `UseCasePage.jsx`. No quitar esa guarda |
| El onboarding obligatorio deja afuera a cuentas con progreso | `onboarding_completed_at` nulo no borra filas. Permitir posponer |
| Editar preferencias recalcula mal porque el progreso se usó como señal | El matching no lee `use_case_progress` para puntuar |
| Empates inestables entre renders | Desempate por `sort_order` e `id`, testeado |
| El seed deja de ser idempotente y duplica tags | `on conflict` en la PK de `use_case_tags` |
| Centro de ayuda sigue roto y se lo atribuye al onboarding | Está roto respecto del SQL del repo desde `20261027200000`. No es regresión de la Fase 1. Documentarlo en el checklist |
| `npm run build` nunca se corrió en esta auditoría | La fase que toque frontend lo ejecuta y reporta el resultado real |

## 10. Criterios de aceptación del MVP, contra el repo de hoy

| # | Criterio | Hoy |
|---|---|---|
| 1 | Registro e inicio de sesión | Implementados en el cliente y en el trigger. **No comprobado** contra el proyecto remoto |
| 2 | Onboarding de usuarios nuevos | No existe |
| 3 | Necesidades de distintas categorías | No existe. El perfil no ata al usuario a una sola categoría |
| 4 | Respuestas en Supabase | No hay tabla. `goal` e `interests` no sirven como cuestionario |
| 5 | Actualizar preferencias | No hay editor. El nombre sí se edita, pero la RPC no está en el SQL del repo |
| 6 | 45 fichas, 15 por categoría | Hay 8, de otra taxonomía, con guía completa |
| 7 | Ranking reproducible | No hay motor. La búsqueda de Explorar es otro algoritmo (`src/lib/search.js`) y no se debe reutilizar como matching |
| 8 | Dashboard con varias categorías | El inicio no recomienda |
| 9 | Catálogo de todos los casos | Explorar lista todos los `published`. Hoy son 8 |
| 10 | Progreso existente | Implementado en `use_case_progress` y tablas hijas. Hay que no migrarlo de forma destructiva |
| 11 | Mobile | Hay estilos en 850px y 570px. **No comprobado** en un dispositivo en esta fase |
| 12 | Migraciones, tests y build | Ocho migraciones en disco. Cero tests. Build no ejecutado |
| 13 | README y SUPABASE_SETUP al día | Describen migraciones y un modelo de seguridad que los archivos SQL no contienen |

## Hechos, propuestas y huecos

**Hechos:** estructura de `src/`, ocho migraciones, 23 tablas, 8 casos con guía, Auth por JWT en el cliente, progreso por `profile_id`, ausencia de onboarding y de ranking, desajuste entre docs y SQL, guarda `ready` para casos sin práctica.

**Propuestas:** `onboarding_responses`, `use_case_tags`, `profiles.onboarding_completed_at`, `use_cases.area`, matching puro con los pesos 40/25/20/10/5, conservar los 8 casos fuera o dentro del cupo de 45 según se decida al abrir la Fase 2, posponer el cuestionario para cuentas viejas, no mezclar el cierre de seguridad de Auth con la Fase 1.

**No comprobado:** estado del proyecto Supabase remoto, si las migraciones ausentes se aplicaron a mano, si hay usuarios con progreso, si el build pasa, comportamiento real en un teléfono.
