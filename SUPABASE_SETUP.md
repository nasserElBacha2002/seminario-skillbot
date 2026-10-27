# Setup de Supabase Auth — SkillBot

## 1. Objetivo

Esta branch reemplaza el login de demo (`skillbot-demo` en `localStorage` + perfil Martín compartido) por **Supabase Auth real**.

El frontend autentica con `signInWithPassword` / `signUp` / `signInWithOAuth({ provider: 'google' })`, persiste la sesión JWT y asocia el progreso a `auth.uid()`. Para que eso funcione en un proyecto de Supabase hay que aplicar las migraciones de Auth, confirmar Email Auth (incluido **Allow new users to sign up**), Site URL y, para Google, el provider OAuth en el dashboard.

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

## 5.1 Google (Fase 5)

Dashboard → **Authentication → Providers → Google**.

Pasos imprescindibles (no hay acceso al dashboard desde este repo):

1. Crear credenciales OAuth en Google Cloud Console (tipo **Web application**).
2. En el proveedor Google de Supabase: habilitarlo, pegar **Client ID** y **Client Secret**. Esos secretos quedan en el dashboard, no en el frontend ni en `.env.local`.
3. Callback URL que pide Supabase (Authorized redirect URI en Google Cloud):

   `https://<project-ref>.supabase.co/auth/v1/callback`

   En local con `supabase start`, el callback es el de esa instancia (lo muestra Studio / Auth), no una URL de producción inventada.
4. En **Authentication → URL Configuration**, Site URL y Redirect URLs de la app tienen que incluir los orígenes reales (`http://localhost:5173` y `http://127.0.0.1:5173` en desarrollo). El cliente usa `redirectTo: window.location.origin`.
5. Prueba con **usuario nuevo** (cuenta que no exista): Continuar con Google → callback → sesión → app y fila en `public.profiles`.
6. Prueba con **usuario existente** que ya tenga identidad Google.
7. Prueba con email/password previo y el mismo email en Google: el resultado depende del dashboard remoto (confirmación de email / linking automático). `enable_manual_linking` sigue en `false`. No se implementó linking manual. Dejar esa combinación como prueba remota.

`handle_new_user` ya toma `display_name` / `full_name` / `name` / email. `profiles` no tiene columna de avatar: se siguen usando initials.

## 6. Site URL y Redirect URLs

La app de desarrollo corre con Vite en el puerto **5173**, no 3000.

### Local (`supabase/config.toml`)

Ya quedó así en esta branch:

```
site_url = "http://localhost:5173"
additional_redirect_urls = ["http://localhost:5173", "http://127.0.0.1:5173"]
```

Aplica a `supabase start`. Login con password, recovery y Google OAuth usan esos orígenes (`redirectTo: window.location.origin`).

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
- Continuar con Google llama `signInWithOAuth({ provider: 'google', redirectTo: origin })`. La sesión entra por `onAuthStateChange`.
- Mi cuenta oculta cambiar contraseña si la sesión no tiene identidad `email`.
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
- Habilitar el provider Google, Client ID/Secret y callback real.
- Callback OAuth: Google → Supabase → SPA → sesión.
- Creación real de `auth.users` + `public.profiles` con metadata de Google.
- Account linking de un email/password existente con el mismo email de Google.

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

- [ ] Abrí el proyecto correcto de Supabase.
- [ ] Confirmé URL y anon key.
- [ ] Apliqué las migraciones nuevas (`20261027120000`, `20261027130000`, `20261027140000`, `20261027150000`, `20261027160000`).
- [ ] Apliqué la migration correctiva y verifiqué profile read-only / RPC / A vs B (checklist de Correcciones de seguridad).
- [ ] Verifiqué Email Auth.
- [ ] Configuré Site URL.
- [ ] Configuré Redirect URLs.
- [ ] Creé usuario A.
- [ ] Creé usuario B.
- [ ] Probé login.
- [ ] Probé refresh.
- [ ] Probé logout.
- [ ] Confirmé aislamiento A/B.
- [ ] Confirmé RLS.
- [ ] Confirmé RPCs.
- [ ] Confirmé creación automática de profile.
- [ ] Confirmé que el catálogo público sigue funcionando.
- [ ] Verifiqué Allow new users to sign up.
- [ ] Registré un usuario desde la app y coinciden los UUID.
- [ ] Confirmé display_name e initials del registro.
- [ ] Si hay confirmación de email, vi “Revisá tu correo”.
- [ ] Si no hay confirmación, el registro entra solo a Home.
- [ ] Logout y login posterior de esa cuenta funcionan.
- [ ] Habilité Google (Client ID, Client Secret, callback de Supabase).
- [ ] Site URL / Redirect URLs cubren el origen de la app.
- [ ] Probé Continuar con Google con usuario nuevo.
- [ ] Probé Continuar con Google con usuario Google existente.
- [ ] Probé el mismo email email/password + Google (linking automático del dashboard; no hay linking manual).
