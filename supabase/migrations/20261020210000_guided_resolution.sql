-- Resolución guiada: cada caso pide datos y arma un prompt con una plantilla.
-- No toca el progreso del perfil demo.

alter table public.use_cases
  add column if not exists output_template text;

alter table public.tools
  add column if not exists url text;

create table if not exists public.use_case_fields (
  id text primary key,
  use_case_id text not null references public.use_cases (id) on delete cascade,
  "key" text not null,
  label text not null,
  type text not null check (type in ('text', 'textarea', 'select')),
  placeholder text,
  required boolean not null default true,
  position integer not null check (position > 0),
  options text[] not null default '{}',
  helper_text text,
  unique (use_case_id, "key"),
  unique (use_case_id, position),
  check (type <> 'select' or cardinality(options) > 0)
);

alter table public.use_case_fields enable row level security;

drop policy if exists "use case fields are readable" on public.use_case_fields;

create policy "use case fields are readable"
  on public.use_case_fields
  for select to anon, authenticated
  using (true);

grant select on public.use_case_fields to anon, authenticated;
