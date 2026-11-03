-- SkillBot: perfil, progreso y gamificacion.
-- El catalogo de casos de uso vive en el frontend (src/data.js) porque va a ser
-- reemplazado por casos avanzados, por eso las tablas lo referencian por slug
-- en una columna text sin foreign key.

-- El login es una demo sin Supabase Auth, asi que todo cuelga de un unico
-- perfil con id fijo compartido con el frontend.
create or replace function public.demo_profile_id()
returns uuid
language sql
immutable
as $$ select '11111111-1111-4111-8111-111111111111'::uuid $$;

create table public.levels (
  id text primary key,
  name text not null,
  min_xp integer not null,
  next_xp integer,
  sort_order integer not null
);

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  initials text not null,
  goal text,
  interests text[] not null default '{}',
  xp integer not null default 0 check (xp >= 0),
  level_id text not null references public.levels (id),
  created_at timestamptz not null default now()
);

create table public.skills (
  id text primary key,
  name text not null,
  color text not null,
  sort_order integer not null
);

create table public.user_skills (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  skill_id text not null references public.skills (id) on delete cascade,
  value integer not null default 0 check (value between 0 and 100),
  updated_at timestamptz not null default now(),
  primary key (profile_id, skill_id)
);

create table public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  icon text not null,
  sort_order integer not null
);

create table public.user_achievements (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievements (id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  primary key (profile_id, achievement_id)
);

create table public.use_case_progress (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  use_case_slug text not null,
  progress integer not null default 0 check (progress between 0 and 100),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (profile_id, use_case_slug)
);

create table public.challenge_attempts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  use_case_slug text not null,
  selected_option text not null,
  is_correct boolean not null,
  xp_earned integer not null default 0,
  created_at timestamptz not null default now()
);

create index challenge_attempts_profile_idx
  on public.challenge_attempts (profile_id, created_at desc);

-- Una fila por dia practicado: de aca se derivan la racha y la grilla semanal.
create table public.activity_days (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  day date not null,
  primary key (profile_id, day)
);

-- Suma XP y reajusta el nivel segun los umbrales de levels.
create or replace function public.add_xp(p_profile_id uuid, p_amount integer)
returns public.profiles
language plpgsql
as $$
declare
  updated public.profiles;
begin
  update public.profiles
     set xp = xp + p_amount
   where id = p_profile_id
  returning * into updated;

  if not found then
    raise exception 'profile % not found', p_profile_id;
  end if;

  update public.profiles
     set level_id = (
       select id
         from public.levels
        where min_xp <= updated.xp
        order by min_xp desc
        limit 1
     )
   where id = p_profile_id
  returning * into updated;

  return updated;
end;
$$;

alter table public.levels enable row level security;
alter table public.profiles enable row level security;
alter table public.skills enable row level security;
alter table public.user_skills enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.use_case_progress enable row level security;
alter table public.challenge_attempts enable row level security;
alter table public.activity_days enable row level security;

-- Catalogos: solo lectura publica.
create policy "levels are readable" on public.levels
  for select to anon, authenticated using (true);

create policy "skills are readable" on public.skills
  for select to anon, authenticated using (true);

create policy "achievements are readable" on public.achievements
  for select to anon, authenticated using (true);

-- Datos de usuario: el rol anon solo puede tocar el perfil demo. Es
-- deliberadamente abierto porque el login es una demo academica y no hay JWT
-- de usuario; si se migra a Supabase Auth hay que reemplazar demo_profile_id()
-- por auth.uid().
create policy "demo profile is readable" on public.profiles
  for select to anon, authenticated using (id = public.demo_profile_id());

create policy "demo profile is writable" on public.profiles
  for update to anon, authenticated
  using (id = public.demo_profile_id())
  with check (id = public.demo_profile_id());

create policy "demo skills are manageable" on public.user_skills
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

create policy "demo achievements are manageable" on public.user_achievements
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

create policy "demo progress is manageable" on public.use_case_progress
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

create policy "demo attempts are manageable" on public.challenge_attempts
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

create policy "demo activity is manageable" on public.activity_days
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

grant select on public.levels, public.skills, public.achievements to anon, authenticated;
grant select, update on public.profiles to anon, authenticated;
grant select, insert, update, delete on
  public.user_skills,
  public.user_achievements,
  public.use_case_progress,
  public.challenge_attempts,
  public.activity_days
to anon, authenticated;
grant execute on function public.demo_profile_id() to anon, authenticated;
grant execute on function public.add_xp(uuid, integer) to anon, authenticated;
