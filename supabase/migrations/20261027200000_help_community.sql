-- Centro de ayuda como comunidad: cualquier usuario abre un tópico con su duda
-- y el resto responde. El autor del tópico puede marcar una respuesta como solución.
--
-- Igual que el resto de las tablas de usuario, la escritura cuelga de
-- demo_profile_id(). Cuando se migre a Supabase Auth hay que reemplazarlo por
-- auth.uid() en las políticas de abajo.

create table if not exists public.help_topics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null default '',
  author_initials text not null default '',
  title text not null check (char_length(btrim(title)) between 5 and 140),
  body text not null check (char_length(btrim(body)) between 1 and 4000),
  use_case_id text references public.use_cases(id) on delete set null,
  solved_reply_id uuid,
  created_at timestamptz not null default now(),
  last_activity_at timestamptz not null default now()
);

create table if not exists public.help_replies (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.help_topics(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null default '',
  author_initials text not null default '',
  body text not null check (char_length(btrim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'help_topics_solved_reply_fkey') then
    alter table public.help_topics
      add constraint help_topics_solved_reply_fkey
      foreign key (solved_reply_id) references public.help_replies(id) on delete set null;
  end if;
end $$;

create index if not exists help_topics_activity_idx on public.help_topics (last_activity_at desc);
create index if not exists help_replies_topic_idx on public.help_replies (topic_id, created_at);

-- El nombre del autor se copia del perfil en el servidor, así no se puede
-- publicar con el nombre de otro. Queda guardado en la fila para que se pueda
-- leer aunque las políticas de profiles solo dejen ver el perfil propio.
create or replace function public.help_set_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.display_name, p.initials
    into new.author_name, new.author_initials
    from public.profiles p
   where p.id = new.profile_id;
  new.author_name := coalesce(new.author_name, '');
  new.author_initials := coalesce(new.author_initials, '');
  new.created_at := now();
  return new;
end;
$$;

drop trigger if exists help_topics_set_author on public.help_topics;
create trigger help_topics_set_author
  before insert on public.help_topics
  for each row execute function public.help_set_author();

drop trigger if exists help_replies_set_author on public.help_replies;
create trigger help_replies_set_author
  before insert on public.help_replies
  for each row execute function public.help_set_author();

-- Una respuesta nueva sube el tópico al principio del listado.
create or replace function public.help_touch_topic()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.help_topics set last_activity_at = now() where id = new.topic_id;
  return new;
end;
$$;

drop trigger if exists help_replies_touch_topic on public.help_replies;
create trigger help_replies_touch_topic
  after insert on public.help_replies
  for each row execute function public.help_touch_topic();

-- La solución tiene que ser una respuesta del mismo tópico.
create or replace function public.help_check_solution()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.solved_reply_id is not null and not exists (
    select 1 from public.help_replies r where r.id = new.solved_reply_id and r.topic_id = new.id
  ) then
    raise exception 'the solution must be a reply of the same topic';
  end if;
  return new;
end;
$$;

drop trigger if exists help_topics_check_solution on public.help_topics;
create trigger help_topics_check_solution
  before update of solved_reply_id on public.help_topics
  for each row execute function public.help_check_solution();

alter table public.help_topics enable row level security;
alter table public.help_replies enable row level security;

drop policy if exists "help topics are readable" on public.help_topics;
create policy "help topics are readable" on public.help_topics
  for select to anon, authenticated using (true);

drop policy if exists "help replies are readable" on public.help_replies;
create policy "help replies are readable" on public.help_replies
  for select to anon, authenticated using (true);

drop policy if exists "demo profile creates topics" on public.help_topics;
create policy "demo profile creates topics" on public.help_topics
  for insert to anon, authenticated
  with check (profile_id = public.demo_profile_id());

drop policy if exists "topic author marks the solution" on public.help_topics;
create policy "topic author marks the solution" on public.help_topics
  for update to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

drop policy if exists "demo profile replies" on public.help_replies;
create policy "demo profile replies" on public.help_replies
  for insert to anon, authenticated
  with check (profile_id = public.demo_profile_id());

grant select on public.help_topics, public.help_replies to anon, authenticated;
grant insert (profile_id, title, body, use_case_id) on public.help_topics to anon, authenticated;
grant update (solved_reply_id) on public.help_topics to anon, authenticated;
grant insert (topic_id, profile_id, body) on public.help_replies to anon, authenticated;
