# Setup de Supabase Auth — SkillBot

## 1. Objetivo

Esta branch reemplaza el login de demo (`skillbot-demo` en `localStorage` + perfil Martín compartido) por **Supabase Auth real**.

El frontend autentica con `signInWithPassword` / `signUp`, persiste la sesión JWT y asocia el progreso a `auth.uid()`. Para que eso funcione en un proyecto de Supabase hay que aplicar las migraciones de Auth, confirmar Email Auth (incluido **Allow new users to sign up**) y Site URL.

## 2. Requisitos

La persona que active el entorno remoto necesita:

- acceso al **proyecto correcto** de Supabase (el que usa la app en `.env.local`);
- permiso para ejecutar migraciones (SQL Editor o CLI con `db push`);
- permiso para administrar **Authentication** (Email provider, usuarios);
- permiso para editar **URL Configuration** (Site URL y Redirect URLs).

La app frontend **solo** usa la anon key. No poner la `service_role` en el cliente ni en `.env.local`.

## 3. Variables de entorno

Copiar `.env.example` a `.env.local`:

```env
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Origen en el dashboard: **Project Settings → API**.

- `VITE_SUPABASE_URL`: Project URL.
- `VITE_SUPABASE_ANON_KEY`: la clave `anon` / `public`. Es pública por diseño; la protección real es RLS.

Reiniciar `npm run dev` después de cambiar `.env.local`. Vite lee las variables al arrancar.

## 4. Aplicar migraciones

### Migración nueva de esta fase

| Archivo | Qué hace |
|---|---|
| `supabase/migrations/20261027120000_supabase_auth.sql` | Borra el perfil demo (no puede vivir en `auth.users`). Vincula `profiles.id` a `auth.users(id)`. Crea trigger `handle_new_user`. Reemplaza RLS de datos privados para usar `auth.uid()`. Reescribe `add_xp`, `resolve_use_case` y `complete_practice_challenge` para resolver al usuario por JWT. Revoca writes de `anon` sobre datos privados. |
| `supabase/migrations/20261027130000_profile_initials.sql` | Ajusta `profile_initials`: un nombre → una letra (`Luciano` → `L`); dos palabras → dos iniciales (`Martín Rodríguez` → `MR`). |
| `supabase/migrations/20261027140000_secure_progress_writes.sql` | Post code-review: `profiles` queda SELECT-only para `authenticated`. Tablas de progreso sin escritura amplia. RPCs `SECURITY DEFINER`. `add_xp(p_amount)`. `complete_practice_challenge` sin `p_correct`. |
| `supabase/migrations/20261027150000_update_profile_name.sql` | Fase 4: RPC `update_profile_name` para `display_name` + `initials`. No otorga `UPDATE` de tabla sobre `profiles`. |
| `supabase/migrations/20261027160000_harden_update_profile_name.sql` | Post review Fase 4: `update_profile_name` queda con `search_path = ''` y referencias calificadas. |

La infraestructura de onboarding está en `supabase/migrations/20261103120000_onboarding_model.sql`. El procedimiento para aplicarla, el vocabulario y las políticas están en la sección 15. Esa migración no usa `update_profile_name` ni `complete_practice_challenge`, y no da por cerrada la deuda de Auth descrita en el resto de este archivo.

Las migraciones anteriores siguen siendo necesarias si el proyecto se levanta desde cero. Orden:

1. `20261006232500_init_skillbot.sql`
2. `20261012230000_use_case_catalog.sql`
3. `20261020210000_guided_resolution.sql`
4. `20261020223000_resolve_use_case.sql`
5. `20261021010000_practice_challenges.sql`
6. `20261021020000_award_xp_on_correct.sql`
7. **`20261027120000_supabase_auth.sql`**
8. **`20261027130000_profile_initials.sql`**
9. **`20261027140000_secure_progress_writes.sql`**
10. **`20261027150000_update_profile_name.sql`**
11. **`20261027160000_harden_update_profile_name.sql`**
12. `supabase/seed.sql` (catálogo; ya no inserta un perfil demo)

### Opción A: SQL Editor

Si las migraciones 1–6 ya estaban aplicadas, pegar y ejecutar `20261027120000`, `20261027130000`, `20261027140000`, `20261027150000` y `20261027160000` en ese orden.

Después, si el catálogo no está, ejecutar `supabase/seed.sql`.

Si más adelante se usa el CLI, registrar las que se aplicaron a mano:

```bash
supabase migration repair --status applied 20261006232500 20261012230000 20261020210000 20261020223000 20261021010000 20261021020000 20261027120000 20261027130000 20261027140000 20261027150000 20261027160000
```

### Opción B: Supabase CLI (proyecto ya linkeado)

```bash
supabase db push
```

Eso aplica las migraciones pendientes, incluidas `20261027120000`, `20261027130000`, `20261027140000`, `20261027150000` y `20261027160000`. No incluye el seed; el seed se carga en `db reset` o se pega a mano.

### Opción C: desarrollo local

```bash
supabase start
# o, si la base local ya existía:
supabase db reset
```

`db reset` aplica todas las migraciones y después `supabase/seed.sql`.

**Efecto sobre datos:** `20261027120000` borra `public.profiles` sin fila en `auth.users`. Eso incluye el perfil demo Martín (`11111111-1111-4111-8111-111111111111`) y huérfanos de desarrollo. No toca cuentas Auth válidas.

Tablas hijas con `ON DELETE CASCADE` hacia `profiles(id)`:

- `user_skills`
- `user_achievements`
- `use_case_progress`
- `use_case_step_progress`
- `challenge_attempts`
- `activity_days`
- `practice_rewards`

Al borrar esos profiles se va su XP, skills, logros, racha, intentos y rewards. El catálogo público no se toca. `20261027140000` aborta si todavía quedara un perfil huérfano.

## 5. Verificación de Authentication

Dashboard → **Authentication → Providers → Email**.

Confirmar:

- Email provider **habilitado**.
- Login con email y contraseña disponible.
- **Allow new users to sign up** habilitado (la app ya tiene pantalla de registro).
- Confirmación de email: para este MVP puede quedar **deshabilitada** (en local, `supabase/config.toml` ya tiene `enable_confirmations = false`). No cambiarlo en silencio. Si el remoto exige confirmar el mail, el registro muestra “Revisá tu correo” y no entra hasta confirmar.
- Política de contraseña: el cliente pide **mínimo 8 caracteres**. En local, `minimum_password_length = 8`. Si el dashboard remoto tiene 6, igual vale el piso de 8 de la app.

`handle_new_user` toma `display_name` / `full_name` / `name` / email para `display_name` e `initials`. `profiles` no tiene columna de avatar.

## 6. Site URL y Redirect URLs

La app de desarrollo corre con Vite en el puerto **5173**, no 3000.

### Local (`supabase/config.toml`)

Ya quedó así en esta branch:

```
site_url = "http://localhost:5173"
additional_redirect_urls = ["http://localhost:5173", "http://127.0.0.1:5173"]
```

Aplica a `supabase start`. Login con password y recovery usan esos orígenes (`redirectTo: window.location.origin`).

### Proyecto remoto

Dashboard → **Authentication → URL Configuration**:

- **Site URL:** `http://localhost:5173` mientras se pruebe en local contra el proyecto remoto.
- **Redirect URLs:** agregar `http://localhost:5173` y `http://127.0.0.1:5173`.

La recuperación de contraseña usa `supabase.auth.resetPasswordForEmail` con `redirectTo = window.location.origin` (en desarrollo `http://localhost:5173` o `http://127.0.0.1:5173`). El cliente ya tiene `detectSessionInUrl: true` y muestra la pantalla de nueva contraseña cuando llega el evento `PASSWORD_RECOVERY`. Esas origins tienen que estar en Site URL / Redirect URLs; no se puede aplicar el dashboard desde este repo.

No hay URL de producción definida en el repositorio. No inventar una. Cuando exista un deploy, hay que sumar esa origin a Site URL / Redirect URLs.

## 7. Crear usuarios de prueba

Preferido: registrarlos desde la app (Login → Crear cuenta).

También se pueden crear a mano: Dashboard → **Authentication → Users → Add user**.

Recomendado para aislamiento:

- Usuario A y usuario B, emails distintos, contraseñas no commiteadas.
- Marcar “Auto Confirm User” si el proyecto exige confirmación de email.

Al crear cada usuario (app o dashboard), el trigger `public.handle_new_user` inserta `public.profiles` con el mismo `id`. Si el trigger todavía no está aplicado, la app va a mostrar “No encontramos tu perfil”.

## 8. Prueba de login

Checklist:

1. `npm run dev` y abrir `http://localhost:5173`.
2. Sin sesión se ve Login (no Home).
3. Enviar el form vacío → error de validación.
4. Credenciales inválidas → “Email o contraseña incorrectos.”
5. Entrar con usuario A → Home, nombre e iniciales de A (no Martín).
6. Completar o avanzar una práctica.
7. Cerrar sesión desde Perfil → Login.
8. Refresh en Login → sigue Login.
9. Entrar con usuario B → no ve el progreso de A.
10. Refresh autenticado → sigue dentro, mismo usuario.
11. Cerrar pestaña y volver a abrir → sesión persistida mientras el JWT/refresh sea válido.
12. Logout de B → Login.

## 9. Verificación de RLS

En SQL Editor, como prueba conceptual (ajustar emails):

```sql
-- El perfil demo ya no debería existir
select id, display_name from public.profiles
where id = '11111111-1111-4111-8111-111111111111';

-- Cada auth.user tiene perfil con el mismo id
select u.id, u.email, p.display_name, p.initials, p.xp, p.level_id
from auth.users u
left join public.profiles p on p.id = u.id;
```

Checklist:

- [ ] `anon` no puede `update`/`insert`/`delete` en `profiles`.
- [ ] `anon` no puede modificar `use_case_progress`, `user_skills`, `user_achievements`, `use_case_step_progress`, `challenge_attempts`, `activity_days`, `practice_rewards`.
- [ ] `authenticated` solo ve/escribe filas con `profile_id = auth.uid()` (o `profiles.id = auth.uid()`).
- [ ] El catálogo público (`use_cases` published, `categories`, `tools`, pasos, desafíos) sigue siendo `select` para `anon` y `authenticated`.
- [ ] Las RPCs de práctica no se pueden ejecutar sin JWT.

Desde la app: usuario B no debe ver XP, racha ni casos completados de A.

## 10. Verificación de RPCs

RPCs que dejaron de usar `demo_profile_id()`:

| Función | Qué verificar |
|---|---|
| `public.require_auth_uid()` | Falla con `not authenticated` si no hay JWT. |
| `public.add_xp(p_amount)` | Receptor = `auth.uid()`. `execute` revocado a `anon` y `authenticated`; solo la llaman otras RPCs. |
| `public.resolve_use_case(p_use_case_id, p_day)` | `SECURITY DEFINER`. Escribe progreso del JWT. Sin sesión, no escribe. |
| `public.complete_practice_challenge(p_use_case_id, p_position, p_selected, p_day)` | `SECURITY DEFINER`. Correctness sale de `challenge_options.is_correct`. |

```sql
select proname
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and pg_get_functiondef(p.oid) ilike '%demo_profile_id%';
```

En runtime no debería devolver `add_xp`, `resolve_use_case` ni `complete_practice_challenge`. `demo_profile_id()` puede seguir existiendo como función histórica, sin grants para `anon`/`authenticated`.

## 11. Verificación del perfil

Después de crear un usuario Auth:

```sql
select id, display_name, initials, goal, interests, xp, level_id, created_at
from public.profiles
where id = '<uuid del usuario en Authentication>';
```

Esperado:

- `id` = uuid de `auth.users`.
- `display_name`: metadata `display_name` (la envía el registro), o `full_name` / `name`, o la parte local del email.
- `initials`: una letra si hay un solo nombre (`Luciano` → `L`); dos si hay dos palabras (`Martín Rodríguez` → `MR`). Requiere `20261027130000_profile_initials.sql`.
- `goal`: texto default de práctica.
- `interests`: `{}`.
- `xp`: `0`.
- `level_id`: `principiante`.

## Fase 2 — Registro

La app ya tiene pantalla **Crear cuenta** (Login → Crear cuenta). El frontend llama `supabase.auth.signUp` con metadata `display_name`. **No inserta** en `public.profiles`: eso lo hace el trigger.

### Email signup

Dashboard → **Authentication → Providers → Email**

Verificar:

- Email provider enabled.
- **Allow new users to sign up** enabled.
- Política de contraseña: mínimo recomendado **8** (la UI no deja enviar menos).

En local (`supabase/config.toml`):

- `[auth] enable_signup = true`
- `[auth.email] enable_signup = true`
- `minimum_password_length = 8`

### Email confirmation

Configuración actual del repo (local):

- `[auth.email] enable_confirmations = false`

No cambiarlo en silencio. Efecto en la app:

| Confirmación | Qué pasa al registrarse |
|---|---|
| Desactivada (MVP académico, default local) | Supabase entrega sesión → el usuario entra a Home solo. |
| Activada en el proyecto remoto | `session` queda null → la app muestra “Revisá tu correo” y un botón para volver al login. No hay bypass. |

Si el remoto tiene confirmación activa, hay que configurar Site URL para que el link del mail vuelva a `http://localhost:5173`.

### Usuarios

Después de un registro exitoso:

1. Authentication → Users: aparece la cuenta.
2. `public.profiles`: una fila con el mismo UUID.

```sql
select u.id, u.email, u.raw_user_meta_data->>'display_name' as meta_name,
       p.id as profile_id, p.display_name, p.initials, p.xp, p.level_id
from auth.users u
join public.profiles p on p.id = u.id
order by u.created_at desc
limit 5;
```

Esperado: `u.id = p.id`, `display_name` = el nombre del formulario, `xp = 0`, `level_id = principiante`.

### Trigger

| Pieza | Nombre | Dónde |
|---|---|---|
| Función | `public.handle_new_user()` | `20261027120000_supabase_auth.sql` |
| Trigger | `on_auth_user_created` (`AFTER INSERT ON auth.users`) | misma migración |
| Nombre / fallback | `public.profile_display_name(email, metadata)` | misma migración |
| Initials | `public.profile_initials(name)` | ajustada en `20261027130000_profile_initials.sql` |

### Metadata

El registro envía:

```js
options: { data: { display_name: nombreTrimmed } }
```

Eso llega a `auth.users.raw_user_meta_data->>'display_name'`. El trigger la usa primero; si falta, prueba `full_name` / `name`; si no hay metadata, usa la parte local del email.

No crear perfiles desde el frontend.

## Correcciones de seguridad post code-review

Migración: `supabase/migrations/20261027140000_secure_progress_writes.sql` (después de `20261027120000` y `20261027130000`).

### Permisos de profiles

`authenticated` solo tiene `SELECT` sobre su fila (`id = auth.uid()`). No hay `UPDATE` de tabla. `display_name` e `initials` se cambian con `public.update_profile_name` (`20261027150000`, endurecida en `20261027160000` con `search_path = ''`), que recalcula initials en SQL.

`xp` y `level_id` los cambia únicamente `public.add_xp` (la llaman `resolve_use_case` y `complete_practice_challenge`). El trigger `handle_new_user` inserta el perfil inicial.

### Permisos de tablas de progreso

| Tabla | SELECT | INSERT | UPDATE | DELETE | Escritura |
|---|---|---|---|---|---|
| `user_skills` | propio | no | no | no | RPC |
| `user_achievements` | propio | propio | no | no | frontend `unlockAchievement` (no hay RPC de logros) |
| `use_case_progress` | propio | propio, `in_progress` y `progress <= 80` | igual | no | pasos / begin / restart; el 100% lo pone la RPC |
| `challenge_attempts` | propio | no | no | no | RPC |
| `activity_days` | propio | propio | propio (upsert) | no | `markActivityToday` y RPC |
| `use_case_step_progress` | propio | propio | no | propio | `setStepDone` / `clearCaseSteps` |
| `practice_rewards` | propio | no | no | no | RPC |

El catálogo público (`use_cases` published, categorías, tools, steps, challenges, options, skills, levels, achievements) no se modifica en esta migración.

### Estrategia de RPCs

`add_xp`, `resolve_use_case` y `complete_practice_challenge` pasan a `SECURITY DEFINER` con `SET search_path = public`. Motivo: al revocar INSERT/UPDATE/DELETE de `authenticated`, un `SECURITY INVOKER` no podría escribir.

Siguen validando `require_auth_uid()`. `add_xp` ya no recibe `profile_id`. `execute` de `add_xp` está revocado a `anon` y `authenticated` (solo la usan las otras RPCs). `resolve_use_case` y `complete_practice_challenge` tienen `execute` solo para `authenticated`.

### Firma de add_xp

Antes: `add_xp(p_profile_id uuid, p_amount integer)` (validaba `p_profile_id = auth.uid()`).

Ahora: `add_xp(p_amount integer)`. El receptor es `auth.uid()`. La firma vieja se elimina.

### Eliminación de p_correct

`complete_practice_challenge(p_use_case_id, p_position, p_selected, p_day)` lee `challenge_options.is_correct` para la letra enviada. Si la opción no existe, falla. El frontend ya no manda `p_correct`. El feedback visual sigue usando `is_correct` del catálogo; el XP lo decide SQL.

### Datos demo legacy

`20261027120000` borra `public.profiles` sin fila en `auth.users` (Martín `11111111-1111-4111-8111-111111111111` y huérfanos). Las tablas hijas se van por `ON DELETE CASCADE`. No toca usuarios Auth. `20261027140000` documenta ese impacto y aborta si todavía hubiera un huérfano.

### reset_progress.sql

El script estándar exige un uuid en `target_profile_id`. El sentinela `00000000-0000-0000-0000-000000000000` aborta. No resetea a todos.

El reset global está en `supabase/seeds/reset_all_progress_destructive.sql`. No es el script estándar y no lo carga `config.toml`.

### Checklist remoto (esta corrección)

- [ ] aplicar migration correctiva (`20261027140000_secure_progress_writes.sql`).
- [ ] verificar profile read-only desde frontend.
- [ ] intentar modificar xp manualmente y confirmar fallo.
- [ ] intentar insertar reward manual y confirmar fallo.
- [ ] completar un caso normalmente y confirmar que RPC sí escribe.
- [ ] completar challenge correctamente.
- [ ] responder challenge incorrectamente.
- [ ] comprobar que servidor determina correctness.
- [ ] comprobar usuario A vs B.
- [ ] revisar datos demo eliminados/migrados.
- [ ] verificar catálogo público.

## 12. Problemas conocidos

### Probado en código / build local

- Cliente con `persistSession` y `autoRefreshToken`.
- Gate de `App` por sesión, sin `skillbot-demo`.
- Login controlado, logout con `signOut`.
- Registro: validación local, `signUp` con `display_name`, switch Login ↔ Crear cuenta.
- Queries y storage namespaced por uid.
- Migraciones escritas; no aplicadas al proyecto remoto desde esta branch.
- `npm run build` del frontend.

### Pendiente de probar en remoto

- Aplicar `20261027120000_supabase_auth.sql`, `20261027130000_profile_initials.sql`, `20261027140000_secure_progress_writes.sql`, `20261027150000_update_profile_name.sql` y `20261027160000_harden_update_profile_name.sql` en el proyecto de Supabase.
- Habilitar signup por email y alinear la política de contraseña a 8+ caracteres.
- Registrar un usuario desde la app y comprobar Auth + `profiles`.
- Crear usuarios A y B (app o dashboard) para aislamiento.
- Login / refresh / logout contra ese proyecto.
- Aislamiento A/B de progreso.
- Que el trigger cree `profiles` al usar **Add user** del dashboard.
- Site URL / Redirect URLs del dashboard (el `config.toml` solo afecta a `supabase start`).

### Local con Docker

Si hay Docker: `supabase start` o `supabase db reset` aplica la migración y el seed. Después hay que crear usuarios en Auth local (Studio en el puerto que imprima `supabase start`) y apuntar `.env.local` a esa URL y anon key.

## 13. Rollback

No hay rollback automático ni destructivo extra.

Si la migración **falla a mitad de camino** en SQL Editor, no reejecutar a ciegas: revisar si ya se borró el perfil demo, si existe la FK `profiles_id_fkey` y si están las policies nuevas.

Si hace falta volver al estado anterior:

1. Dejar de usar esta branch del frontend (el login demo ya no existe en este código).
2. La migración `20261027120000` **elimina** el perfil demo y su progreso (hijas primero, después `profiles`). Eso no se recupera salvo backup del proyecto.
3. Revertir policies a `demo_profile_id()` solo tiene sentido junto con el frontend viejo y un perfil demo recreado. No se recomienda.

Datos afectados al aplicar la migración:

- borra `profiles` huérfanos (incluye Martín);
- el `on delete cascade` de las tablas de progreso se lleva XP, skills, logros, racha y rewards de esos perfiles;
- no toca el catálogo (`use_cases`, categorías, herramientas, desafíos).

## 14. Checklist final

- [ ] Proyecto correcto de Supabase (el de `.env.local`).
- [ ] `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` (sin `service_role`).
- [ ] Migraciones aplicadas hasta `20261027160000`.
- [ ] Email Auth habilitado y **Allow new users to sign up**.
- [ ] Site URL: `http://localhost:5173`.
- [ ] Redirect URLs: `http://localhost:5173` y `http://127.0.0.1:5173`.
- [ ] Registrar un usuario: sesión → app.
- [ ] Fila en `auth.users`.
- [ ] `public.profiles.id = auth.users.id`.
- [ ] `display_name` / `initials` desde metadata o email.
- [ ] Logout y volver a entrar con email y contraseña.
- [ ] Progreso de esa cuenta persiste tras refresh / re-login.
- [ ] Dos usuarios (A y B) y aislamiento de progreso.
- [ ] Recovery de contraseña (email/password).
- [ ] Edición de nombre (`update_profile_name`).
- [ ] Bloqueo de UPDATE directo de XP en `profiles`.
- [ ] Bloqueo de escrituras directas de progreso fuera de RPC.
- [ ] Progreso normal (resolver caso / challenge) vía RPC.

## 15. Fase 1 — Onboarding, áreas y etiquetas

Migración nueva, aditiva: `supabase/migrations/20261103120000_onboarding_model.sql`.

No modifica migraciones anteriores ni las funciones de Auth. La Fase 0 informó cinco archivos ausentes. En esta copia de trabajo están trackeados por git y el arranque local los aplica; no se editaron en esta fase y no se consultó si el proyecto remoto ya los corrió:

- `20261027130000_profile_initials.sql`
- `20261027140000_secure_progress_writes.sql`
- `20261027150000_update_profile_name.sql`
- `20261027160000_harden_update_profile_name.sql`
- `20261027210000_help_community_auth.sql`

`20261103120000` no llama a `update_profile_name` ni a `complete_practice_challenge`. Si el remoto no tiene `20261027140000`, `authenticated` sigue con `UPDATE` sobre `profiles`: el trigger de esta migración igual impide cambiar `onboarding_completed_at`. Si el remoto ya revocó ese `UPDATE`, la RPC sigue pudiendo escribir la marca porque es `security definer`.

### Orden local

1. `20261006232500_init_skillbot.sql`
2. `20261012230000_use_case_catalog.sql`
3. `20261020210000_guided_resolution.sql`
4. `20261020223000_resolve_use_case.sql`
5. `20261021010000_practice_challenges.sql`
6. `20261021020000_award_xp_on_correct.sql`
7. `20261027120000_supabase_auth.sql`
8. `20261027130000_profile_initials.sql`
9. `20261027140000_secure_progress_writes.sql`
10. `20261027150000_update_profile_name.sql`
11. `20261027160000_harden_update_profile_name.sql`
12. `20261027200000_help_community.sql`
13. `20261027210000_help_community_auth.sql`
14. `20261103120000_onboarding_model.sql`
15. `supabase/seed.sql`

`20261012230000` y `20261027120000` borran progreso o perfiles huérfanos. No hay que volver a ejecutarlas a mano sobre una base con usuarios. La migración de onboarding no las invoca y no repite esos `DELETE`.

### Cómo aplicarla

Instalación local limpia, sin cuentas que haya que conservar:

```bash
supabase start
supabase db reset
```

`db reset` sin `--linked` recrea solo la base local de Docker y después corre `supabase/seed.sql`.

Base remota, o cualquier base que ya tenga usuarios:

```bash
supabase db push
```

Eso aplica únicamente las migraciones pendientes. No usar `supabase db reset` ni `supabase db reset --linked` contra el proyecto remoto. No pegar en el SQL Editor las migraciones históricas que borran perfiles. Si la base remota no tiene el esquema de las ocho migraciones presentes, esta migración no lo reconstruye: hay que revisar ese entorno aparte, sin inventar las cinco migraciones ausentes.

Si `20261103120000_onboarding_model.sql` se pega a mano en el SQL Editor, se puede volver a ejecutar: no dropea tablas de usuario y el vocabulario se actualiza con `on conflict`. No reejecutar por eso el resto del historial.

### Tablas y columnas

`public.onboarding_options` guarda el vocabulario. Lectura pública. Sin `INSERT`, `UPDATE` ni `DELETE` para `anon` ni `authenticated`. Una opción nueva de las clases ya previstas se agrega con un `INSERT` en una migración posterior. `kind` y `value` no se pueden renombrar. No se puede borrar una opción que ya esté en una respuesta, en un caso o en una etiqueta.

`public.onboarding_responses` guarda una fila por usuario:

| Columna | Tipo | Vocabulario |
|---|---|---|
| `profile_id` | `uuid` PK, FK a `profiles(id)` `on delete cascade` | — |
| `areas` | `text[]` | `area` |
| `problems` | `text[]` | `problem` |
| `tools` | `text[]` | `tool` |
| `ai_experience` | `text` | `experience` |
| `primary_goal` | `text` | `goal` |
| `available_time` | `text` | `time` |
| `created_at`, `updated_at` | `timestamptz` | — |

Los tres arrays tienen al menos un identificador, no repiten valores, no superan 64 elementos y no aceptan `null`. `ninguna` no se combina con otra herramienta. Una respuesta puede mezclar áreas y problemas de Marketing, Finanzas y Administración: no hay un perfil por categoría ni una regla que ate cada problema al área elegida.

`profiles.onboarding_completed_at` queda `null` en los usuarios que ya existen y en los que crea `handle_new_user`. El trigger de alta no se modificó.

`use_cases.area` es `text null`. Los valores iniciales son `marketing`, `finanzas` y `administracion`. `null` conserva los ocho casos actuales. `categories` y `use_case_categories` siguen siendo la clasificación por tipo de tarea.

`use_case_tags` tiene clave primaria `(use_case_id, kind, value)`. `use_case_id` es `text` porque esa es la clave de `use_cases`. `kind` admite `problem`, `goal`, `area`, `tool`, `experience` y `time`. El valor tiene que existir en `onboarding_options` para esa clase. Un caso puede tener varias etiquetas de la misma clase.

### Consistencia de la marca

La escritura prevista es la RPC `complete_onboarding(p_areas, p_problems, p_tools, p_ai_experience, p_primary_goal, p_available_time)`. No recibe un id de perfil: usa `auth.uid()`. Es `security definer` con `search_path` vacío.

Un `insert` o `update` directo de la propia fila también es válido y pasa por el mismo trigger. En los dos caminos ocurre esto, dentro de una sola transacción:

1. Se rechaza la fila si algún valor no está en el vocabulario.
2. Se hace el `upsert` de `onboarding_responses`.
3. Si `onboarding_completed_at` era `null`, pasa a `now()`. Si ya tenía valor, se conserva: es la primera finalización, no la última edición. `updated_at` de la respuesta sí cambia.

Si el paso 3 no encuentra el perfil, la transacción entera vuelve atrás. No queda una respuesta sin marca ni una marca nueva sin respuesta. No hay estado de borrador en la base: hasta que las seis respuestas son válidas, no se guarda nada. Un borrador de interfaz, si la Fase 3 lo necesita, queda en el cliente.

`anon` y `authenticated` no pueden cambiar `onboarding_completed_at` con un `update` directo de `profiles`. Esta migración no agrega `UPDATE` sobre esa tabla. Donde `20261027140000` ya corrió, `authenticated` solo tiene `SELECT` sobre `profiles`. Donde no corrió, el `UPDATE` de `20261027120000` sigue activo y el trigger nuevo igual rechaza un cambio de esta columna.

Borrar la fila de respuestas, algo que el cliente no puede hacer, limpia la marca. Si el perfil se borra y la respuesta cae por `on delete cascade`, esa limpieza no impide el borrado de la cuenta.

### RLS y permisos

| Objeto | `anon` | `authenticated` |
|---|---|---|
| `onboarding_options` | `SELECT` | `SELECT` |
| `onboarding_responses` | sin acceso | `SELECT`, `INSERT` y `UPDATE` solo si `profile_id = auth.uid()`. Sin `DELETE` |
| `use_case_tags` | `SELECT` | `SELECT` |
| `complete_onboarding` | sin `EXECUTE` | `EXECUTE` |
| `profiles.onboarding_completed_at` | no escribe | no la puede cambiar por `UPDATE` directo |

No se agregaron políticas sobre `use_case_progress` ni sobre el resto de las tablas de progreso. Las etiquetas no contienen datos de usuario. El rol de servicio y el SQL Editor siguen pasando por encima de RLS, igual que en el resto del proyecto; la app no usa la `service_role`.

### Vocabulario

Los identificadores son la clave estable. `label` es el texto para mostrar.

Áreas: `marketing`, `finanzas`, `administracion`.

Problemas de Marketing: `atraer_clientes`, `explicar_oferta`, `publicar_en_redes`, `crear_contenido`, `medir_resultados`, `responder_consultas`.

Problemas de Finanzas: `controlar_gastos`, `armar_precios`, `cobrar_a_tiempo`, `proyectar_caja`, `entender_ventas`, `ordenar_comprobantes`.

Problemas de Administración: `organizar_tareas`, `hacer_seguimiento`, `documentar_procesos`, `coordinar_pendientes`, `atender_clientes`, `preparar_reuniones`.

Problemas que no pertenecen a una sola área: `ahorrar_tiempo_repetitivo`, `decidir_con_informacion`, `empezar_sin_experiencia`.

Objetivos: `conseguir_clientes`, `ordenar_finanzas`, `ahorrar_tiempo`, `mejorar_comunicacion`, `tomar_decisiones`, `ordenar_operacion`.

Herramientas: `chatgpt`, `claude`, `gemini`, `copilot`, `notebooklm`, `canva`, `excel`, `google_sheets`, `whatsapp`, `instagram`, `calendario`, `ninguna`.

Canva en el catálogo de `tools` sigue siendo `diseno`. En el onboarding el identificador es `canva`. Las etiquetas de matching tienen que usar `canva`, no `diseno`.

Experiencia: `nunca`, `alguna_vez`, `seguido`, `en_el_negocio`.

Tiempo: `menos_15`, `de_15_a_30`, `de_30_a_60`, `mas_de_60`. Esas franjas quedan definidas para compararlas después con `use_cases.estimated_minutes` (`<= 15`, `<= 30`, `<= 60` y cualquier duración). Esta migración no hace esa comparación.

Para leer las opciones desde el cliente, cuando exista la pantalla:

```sql
select kind, value, label, area, sort_order
from public.onboarding_options
order by kind, sort_order;
```

### Verificación

Después de aplicar la migración, en la base local:

```sql
select id, area from public.use_cases order by sort_order;
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name = 'onboarding_completed_at';
select kind, count(*) from public.onboarding_options group by kind order by kind;
```

Esperado: los ocho casos siguen publicados y con `area` nula; la columna nueva existe; el vocabulario tiene 3 áreas, 21 problemas, 6 objetivos, 12 herramientas, 4 experiencias y 4 tiempos.

Con dos usuarios de Auth, como cada uno:

- `complete_onboarding` guarda su fila y deja `onboarding_completed_at` distinta de `null`.
- El otro usuario no puede leer esa fila.
- `anon` puede leer `onboarding_options` y `use_case_tags`, y no puede leer `onboarding_responses`.
- Un valor fuera del vocabulario rechaza la operación y no mueve la marca.
- Volver a guardar cambia `updated_at` y conserva la marca original.
- Un `update` directo de `onboarding_completed_at` falla.
- `use_case_progress` de esa cuenta queda igual.

### Limitaciones

- No se comprobó el proyecto remoto. No asumir que allí existen las cinco migraciones ausentes.
- La app todavía no llama `complete_onboarding` ni lee `area`. Los selects actuales de perfil y catálogo nombran columnas y no incluyen estos campos.
- Los ocho casos no tienen área ni etiquetas. Entran en el esquema, pero el matching todavía no tiene con qué puntuarlos. Definir los 45 casos y esas etiquetas es la Fase 2. Los ocho quedan fuera de ese cupo hasta que se decida cuáles siguen en el catálogo principal.
- No hay tests automatizados en el repositorio. La comprobación de esta fase es SQL sobre la base local, si Docker está disponible.
- Agregar una quinta clase de etiqueta exige cambiar el `check` de `kind`. Agregar un valor de una clase existente no.
- No se modificó Auth, progreso ni el centro de ayuda. En esta copia los SQL de esa deuda están trackeados; no se comprobó el remoto.
