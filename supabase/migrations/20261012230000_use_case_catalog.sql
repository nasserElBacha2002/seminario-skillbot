-- SkillBot: el catalogo de casos de uso pasa del frontend (src/data.js) a la
-- base. Cada caso tiene categorias, herramientas recomendadas con su motivo,
-- pasos con prompt de ejemplo, las tareas de la encuesta que cubre y un
-- desafio de opcion multiple. El contenido se carga en seed.sql.

create table public.categories (
  id text primary key,
  name text not null,
  sort_order integer not null
);

create table public.tools (
  id text primary key,
  name text not null,
  sort_order integer not null
);

create table public.use_cases (
  id text primary key,
  title text not null,
  summary text not null,
  situation text not null,
  skill_id text not null references public.skills (id),
  difficulty text not null check (difficulty in ('Fácil', 'Media', 'Avanzada')),
  estimated_minutes integer not null check (estimated_minutes > 0),
  icon text not null,
  color text not null,
  common_mistake text not null,
  learning_outcome text not null,
  xp_reward integer not null default 30 check (xp_reward >= 0),
  -- Los casos en reserva se cargan con la misma estructura pero la app no los muestra.
  status text not null default 'published' check (status in ('published', 'reserve')),
  sort_order integer not null
);

create table public.use_case_categories (
  use_case_id text not null references public.use_cases (id) on delete cascade,
  category_id text not null references public.categories (id) on delete cascade,
  is_primary boolean not null default false,
  primary key (use_case_id, category_id)
);

create unique index use_case_categories_one_primary
  on public.use_case_categories (use_case_id) where is_primary;

-- role: primary es la recomendada, alternative la reemplaza y complement se
-- usa junto con la recomendada para otra parte de la tarea.
create table public.use_case_tools (
  use_case_id text not null references public.use_cases (id) on delete cascade,
  tool_id text not null references public.tools (id) on delete cascade,
  role text not null check (role in ('primary', 'alternative', 'complement')),
  reason text not null,
  sort_order integer not null,
  primary key (use_case_id, tool_id)
);

-- requires_confirmation bloquea los pasos siguientes y el desafio hasta que el
-- usuario marque el paso con confirmation_label.
create table public.use_case_steps (
  use_case_id text not null references public.use_cases (id) on delete cascade,
  position integer not null check (position > 0),
  body text not null,
  example_prompt text,
  checklist text[] not null default '{}',
  requires_confirmation boolean not null default false,
  confirmation_label text,
  primary key (use_case_id, position),
  check (not requires_confirmation or confirmation_label is not null)
);

create table public.use_case_survey_tasks (
  use_case_id text not null references public.use_cases (id) on delete cascade,
  position integer not null,
  task text not null,
  mentions integer check (mentions > 0),
  primary key (use_case_id, position)
);

create table public.use_case_challenges (
  use_case_id text primary key references public.use_cases (id) on delete cascade,
  title text not null,
  scenario text not null,
  question text not null
);

create table public.challenge_options (
  use_case_id text not null references public.use_case_challenges (use_case_id) on delete cascade,
  letter text not null check (letter ~ '^[a-z]$'),
  body text not null,
  is_correct boolean not null default false,
  feedback text not null,
  primary key (use_case_id, letter)
);

create unique index challenge_options_one_correct
  on public.challenge_options (use_case_id) where is_correct;

create table public.use_case_step_progress (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  use_case_id text not null,
  position integer not null,
  completed_at timestamptz not null default now(),
  primary key (profile_id, use_case_id, position),
  foreign key (use_case_id, position)
    references public.use_case_steps (use_case_id, position) on delete cascade
);

-- El progreso guardado apunta a los casos viejos de src/data.js, que dejan de
-- existir. Se borra todo el avance del perfil demo para poder agregar las
-- foreign keys y para que XP, logros y habilidades no arrastren casos que ya
-- no estan. Es lo mismo que hace seeds/reset_progress.sql.
delete from public.use_case_progress;
delete from public.challenge_attempts;
delete from public.activity_days;
delete from public.user_achievements;
delete from public.user_skills;
update public.profiles set xp = 0, level_id = 'principiante';

alter table public.use_case_progress
  add constraint use_case_progress_use_case_fkey
  foreign key (use_case_slug) references public.use_cases (id) on delete cascade;

alter table public.challenge_attempts
  add constraint challenge_attempts_use_case_fkey
  foreign key (use_case_slug) references public.use_cases (id) on delete cascade;

alter table public.categories enable row level security;
alter table public.tools enable row level security;
alter table public.use_cases enable row level security;
alter table public.use_case_categories enable row level security;
alter table public.use_case_tools enable row level security;
alter table public.use_case_steps enable row level security;
alter table public.use_case_survey_tasks enable row level security;
alter table public.use_case_challenges enable row level security;
alter table public.challenge_options enable row level security;
alter table public.use_case_step_progress enable row level security;

create policy "categories are readable" on public.categories
  for select to anon, authenticated using (true);

create policy "tools are readable" on public.tools
  for select to anon, authenticated using (true);

create policy "published use cases are readable" on public.use_cases
  for select to anon, authenticated using (status = 'published');

create policy "use case categories are readable" on public.use_case_categories
  for select to anon, authenticated using (true);

create policy "use case tools are readable" on public.use_case_tools
  for select to anon, authenticated using (true);

create policy "use case steps are readable" on public.use_case_steps
  for select to anon, authenticated using (true);

create policy "use case survey tasks are readable" on public.use_case_survey_tasks
  for select to anon, authenticated using (true);

-- Las opciones incluyen is_correct: en la demo la correccion se hace en el
-- frontend, asi que la respuesta es visible para quien inspeccione la red.
create policy "use case challenges are readable" on public.use_case_challenges
  for select to anon, authenticated using (true);

create policy "challenge options are readable" on public.challenge_options
  for select to anon, authenticated using (true);

create policy "demo step progress is manageable" on public.use_case_step_progress
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

grant select on
  public.categories,
  public.tools,
  public.use_cases,
  public.use_case_categories,
  public.use_case_tools,
  public.use_case_steps,
  public.use_case_survey_tasks,
  public.use_case_challenges,
  public.challenge_options
to anon, authenticated;
grant select, insert, update, delete on public.use_case_step_progress to anon, authenticated;
