-- SkillBot 2.0 — Fase 1: onboarding, area de negocio y etiquetas de matching.
--
-- Aditiva. No borra perfiles, progreso, casos ni XP. No depende de las
-- migraciones citadas en la documentacion que no estan en este repositorio
-- (update_profile_name, secure_progress_writes, help_community_auth).
-- No modifica el trigger handle_new_user ni las RPC de progreso.
--
-- use_cases.id es text (20261012230000_use_case_catalog.sql). La FK de
-- use_case_tags usa ese tipo.
--
-- Consistencia: toda escritura de onboarding_responses, incluida
-- complete_onboarding, corre en una transaccion. Un trigger AFTER escribe
-- profiles.onboarding_completed_at en la misma transaccion. Si la marca no se
-- puede guardar, la respuesta tampoco queda confirmada. Un trigger BEFORE
-- impide que el rol de la app cambie esa marca por fuera de ese camino.
-- La primera respuesta valida fija la marca. Una edicion posterior actualiza
-- las respuestas y conserva la marca original.
--
-- No hay borrador en la base: una fila valida significa cuestionario completo.
-- El borrador de la Fase 3 puede vivir en el cliente hasta esta escritura.

-- ---------------------------------------------------------------------------
-- Vocabulario
-- Una opcion nueva de problema, objetivo, herramienta, experiencia o tiempo
-- es un INSERT en onboarding_options. kind y value no se renombran: son la
-- clave que van a compartir el cuestionario, las etiquetas y el matching.
-- ---------------------------------------------------------------------------

create or replace function public.text_array_is_set(p_values text[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_values is not null
     and cardinality(p_values) between 1 and 64
     and not exists (
       select 1 from pg_catalog.unnest(p_values) as item(value) where item.value is null
     )
     and cardinality(p_values) = (
       select count(distinct item.value) from pg_catalog.unnest(p_values) as item(value)
     );
$$;

create table if not exists public.onboarding_options (
  kind text not null check (kind in ('area', 'problem', 'goal', 'tool', 'experience', 'time')),
  value text not null check (value ~ '^[a-z][a-z0-9]*(?:[_-][a-z0-9]+)*$' and char_length(value) <= 64),
  label text not null check (char_length(btrim(label)) > 0),
  -- Agrupacion visual de un problema. Null en opciones transversales.
  -- No obliga a que la respuesta elija una sola area.
  area text check (area is null or area ~ '^[a-z][a-z0-9]*(?:[_-][a-z0-9]+)*$'),
  sort_order integer not null check (sort_order > 0),
  primary key (kind, value)
);

create index if not exists onboarding_options_kind_sort_idx
  on public.onboarding_options (kind, sort_order);

create or replace function public.onboarding_options_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if tg_op = 'UPDATE'
     and (new.kind is distinct from old.kind or new.value is distinct from old.value) then
    raise exception 'kind y value de onboarding_options son identificadores estables'
      using errcode = '23514';
  end if;

  if new.area is not null and not exists (
    select 1
      from public.onboarding_options as option
     where option.kind = 'area'
       and option.value = new.area
  ) then
    raise exception 'area de agrupacion invalida: %', new.area
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists onboarding_options_guard on public.onboarding_options;
create trigger onboarding_options_guard
  before insert or update on public.onboarding_options
  for each row execute function public.onboarding_options_guard();

create or replace function public.onboarding_options_prevent_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if exists (
    select 1
      from public.use_case_tags as tag
     where tag.kind = old.kind
       and tag.value = old.value
  ) then
    raise exception 'la opcion %/% esta usada como etiqueta', old.kind, old.value
      using errcode = '23503';
  end if;

  if old.kind = 'area' and (
    exists (select 1 from public.use_cases as use_case where use_case.area = old.value)
    or exists (
      select 1 from public.onboarding_responses as response
       where old.value = any (response.areas)
    )
    or exists (
      select 1 from public.onboarding_options as option
       where option.area = old.value
    )
  ) then
    raise exception 'el area % esta en uso', old.value using errcode = '23503';
  elsif old.kind = 'problem' and exists (
    select 1 from public.onboarding_responses as response
     where old.value = any (response.problems)
  ) then
    raise exception 'el problema % esta en uso', old.value using errcode = '23503';
  elsif old.kind = 'tool' and exists (
    select 1 from public.onboarding_responses as response
     where old.value = any (response.tools)
  ) then
    raise exception 'la herramienta % esta en uso', old.value using errcode = '23503';
  elsif old.kind = 'experience' and exists (
    select 1 from public.onboarding_responses as response
     where response.ai_experience = old.value
  ) then
    raise exception 'la experiencia % esta en uso', old.value using errcode = '23503';
  elsif old.kind = 'goal' and exists (
    select 1 from public.onboarding_responses as response
     where response.primary_goal = old.value
  ) then
    raise exception 'el objetivo % esta en uso', old.value using errcode = '23503';
  elsif old.kind = 'time' and exists (
    select 1 from public.onboarding_responses as response
     where response.available_time = old.value
  ) then
    raise exception 'el tiempo % esta en uso', old.value using errcode = '23503';
  end if;

  return old;
end;
$$;

drop trigger if exists onboarding_options_prevent_delete on public.onboarding_options;
create trigger onboarding_options_prevent_delete
  before delete on public.onboarding_options
  for each row execute function public.onboarding_options_prevent_delete();

insert into public.onboarding_options (kind, value, label, area, sort_order) values
  ('area', 'marketing', 'Marketing', null, 1),
  ('area', 'finanzas', 'Finanzas', null, 2),
  ('area', 'administracion', 'Administración', null, 3)
on conflict (kind, value) do update
  set label = excluded.label,
      area = excluded.area,
      sort_order = excluded.sort_order;

insert into public.onboarding_options (kind, value, label, area, sort_order) values
  ('problem', 'atraer_clientes', 'Conseguir clientes', 'marketing', 1),
  ('problem', 'explicar_oferta', 'Explicar mi oferta', 'marketing', 2),
  ('problem', 'publicar_en_redes', 'Publicar en redes', 'marketing', 3),
  ('problem', 'crear_contenido', 'Crear contenido', 'marketing', 4),
  ('problem', 'medir_resultados', 'Medir si funciona', 'marketing', 5),
  ('problem', 'responder_consultas', 'Responder consultas', 'marketing', 6),
  ('problem', 'controlar_gastos', 'Controlar gastos', 'finanzas', 7),
  ('problem', 'armar_precios', 'Armar precios', 'finanzas', 8),
  ('problem', 'cobrar_a_tiempo', 'Cobrar a tiempo', 'finanzas', 9),
  ('problem', 'proyectar_caja', 'Proyectar la caja', 'finanzas', 10),
  ('problem', 'entender_ventas', 'Entender las ventas', 'finanzas', 11),
  ('problem', 'ordenar_comprobantes', 'Ordenar comprobantes', 'finanzas', 12),
  ('problem', 'organizar_tareas', 'Organizar tareas', 'administracion', 13),
  ('problem', 'hacer_seguimiento', 'Hacer seguimiento', 'administracion', 14),
  ('problem', 'documentar_procesos', 'Documentar procesos', 'administracion', 15),
  ('problem', 'coordinar_pendientes', 'Coordinar pendientes', 'administracion', 16),
  ('problem', 'atender_clientes', 'Atender clientes', 'administracion', 17),
  ('problem', 'preparar_reuniones', 'Preparar reuniones', 'administracion', 18),
  ('problem', 'ahorrar_tiempo_repetitivo', 'Dejar de repetir tareas a mano', null, 19),
  ('problem', 'decidir_con_informacion', 'Decidir con información', null, 20),
  ('problem', 'empezar_sin_experiencia', 'Avanzar sin saber la herramienta', null, 21),
  ('goal', 'conseguir_clientes', 'Conseguir clientes', null, 1),
  ('goal', 'ordenar_finanzas', 'Ordenar las finanzas', null, 2),
  ('goal', 'ahorrar_tiempo', 'Ahorrar tiempo', null, 3),
  ('goal', 'mejorar_comunicacion', 'Mejorar la comunicación', null, 4),
  ('goal', 'tomar_decisiones', 'Tomar mejores decisiones', null, 5),
  ('goal', 'ordenar_operacion', 'Ordenar la operación', null, 6),
  ('tool', 'chatgpt', 'ChatGPT', null, 1),
  ('tool', 'claude', 'Claude', null, 2),
  ('tool', 'gemini', 'Gemini', null, 3),
  ('tool', 'copilot', 'Copilot', null, 4),
  ('tool', 'notebooklm', 'NotebookLM', null, 5),
  ('tool', 'canva', 'Canva', null, 6),
  ('tool', 'excel', 'Excel', null, 7),
  ('tool', 'google_sheets', 'Google Sheets', null, 8),
  ('tool', 'whatsapp', 'WhatsApp', null, 9),
  ('tool', 'instagram', 'Instagram', null, 10),
  ('tool', 'calendario', 'Calendario', null, 11),
  ('tool', 'ninguna', 'Ninguna por ahora', null, 12),
  ('experience', 'nunca', 'Nunca usé IA', null, 1),
  ('experience', 'alguna_vez', 'La probé alguna vez', null, 2),
  ('experience', 'seguido', 'La uso seguido', null, 3),
  ('experience', 'en_el_negocio', 'La uso en el negocio', null, 4),
  ('time', 'menos_15', 'Menos de 15 minutos', null, 1),
  ('time', 'de_15_a_30', 'De 15 a 30 minutos', null, 2),
  ('time', 'de_30_a_60', 'De 30 a 60 minutos', null, 3),
  ('time', 'mas_de_60', 'Más de 60 minutos', null, 4)
on conflict (kind, value) do update
  set label = excluded.label,
      area = excluded.area,
      sort_order = excluded.sort_order;

alter table public.onboarding_options enable row level security;

drop policy if exists "onboarding options are readable" on public.onboarding_options;
create policy "onboarding options are readable" on public.onboarding_options
  for select to anon, authenticated
  using (true);

revoke all on table public.onboarding_options from public, anon, authenticated;
grant select on table public.onboarding_options to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Marca de onboarding en el perfil
-- Null en las cuentas que ya existen y en las que cree handle_new_user.
-- No se abre un UPDATE nuevo sobre profiles: la marca solo cambia dentro de
-- sync_onboarding_completed_at, que es security definer.
-- current_user, no session_user: dentro de esa funcion el usuario efectivo es
-- el dueno, aunque la sesion haya entrado como authenticator.
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists onboarding_completed_at timestamptz;

comment on column public.profiles.onboarding_completed_at is
  'Primera vez que se guardo una fila valida en onboarding_responses. Null si el cuestionario no esta completo.';

create or replace function public.protect_onboarding_completed_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if new.onboarding_completed_at is distinct from old.onboarding_completed_at
     and current_user in ('anon', 'authenticated', 'authenticator') then
    raise exception 'onboarding_completed_at solo se actualiza al guardar el cuestionario'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_protect_onboarding_completed_at on public.profiles;
create trigger profiles_protect_onboarding_completed_at
  before update of onboarding_completed_at on public.profiles
  for each row execute function public.protect_onboarding_completed_at();

-- ---------------------------------------------------------------------------
-- Respuestas: una fila por perfil, varias areas y varios problemas
-- ---------------------------------------------------------------------------

create table if not exists public.onboarding_responses (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  areas text[] not null,
  problems text[] not null,
  tools text[] not null,
  ai_experience text not null,
  primary_goal text not null,
  available_time text not null,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  constraint onboarding_responses_areas_set check (public.text_array_is_set(areas)),
  constraint onboarding_responses_problems_set check (public.text_array_is_set(problems)),
  constraint onboarding_responses_tools_set check (public.text_array_is_set(tools)),
  constraint onboarding_responses_experience_present check (char_length(btrim(ai_experience)) > 0),
  constraint onboarding_responses_goal_present check (char_length(btrim(primary_goal)) > 0),
  constraint onboarding_responses_time_present check (char_length(btrim(available_time)) > 0)
);

create or replace function public.assert_onboarding_value(p_kind text, p_value text)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_value is null or p_value !~ '^[a-z][a-z0-9]*(?:[_-][a-z0-9]+)*$' then
    raise exception 'identificador invalido para %', p_kind using errcode = '23514';
  end if;

  if not exists (
    select 1
      from public.onboarding_options as option
     where option.kind = p_kind
       and option.value = p_value
  ) then
    raise exception '% no pertenece al vocabulario: %', p_kind, p_value
      using errcode = '23514';
  end if;
end;
$$;

create or replace function public.onboarding_responses_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  item text;
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if tg_op = 'UPDATE' then
    new.profile_id := old.profile_id;
    new.created_at := old.created_at;
    new.updated_at := pg_catalog.now();
  end if;

  if new.areas is null or not public.text_array_is_set(new.areas) then
    raise exception 'areas debe tener identificadores distintos' using errcode = '23514';
  end if;
  if new.problems is null or not public.text_array_is_set(new.problems) then
    raise exception 'problems debe tener identificadores distintos' using errcode = '23514';
  end if;
  if new.tools is null or not public.text_array_is_set(new.tools) then
    raise exception 'tools debe tener identificadores distintos' using errcode = '23514';
  end if;

  foreach item in array new.areas loop
    perform public.assert_onboarding_value('area', item);
  end loop;
  foreach item in array new.problems loop
    perform public.assert_onboarding_value('problem', item);
  end loop;
  foreach item in array new.tools loop
    perform public.assert_onboarding_value('tool', item);
  end loop;

  if 'ninguna' = any (new.tools) and cardinality(new.tools) > 1 then
    raise exception 'ninguna no se combina con otras herramientas' using errcode = '23514';
  end if;

  perform public.assert_onboarding_value('experience', new.ai_experience);
  perform public.assert_onboarding_value('goal', new.primary_goal);
  perform public.assert_onboarding_value('time', new.available_time);

  return new;
end;
$$;

create or replace function public.sync_onboarding_completed_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if tg_op = 'DELETE' then
    begin
      update public.profiles
         set onboarding_completed_at = null
       where id = old.profile_id;
    exception
      when sqlstate '27000' then
        -- La cuenta se esta borrando y la respuesta cae por ON DELETE CASCADE.
        -- 27000 = triggered_data_change; plpgsql no acepta ese nombre de condicion.
        null;
    end;
    return old;
  end if;

  update public.profiles
     set onboarding_completed_at = coalesce(onboarding_completed_at, pg_catalog.now())
   where id = new.profile_id;

  if not found then
    raise exception 'profile % not found', new.profile_id using errcode = 'P0002';
  end if;

  return new;
end;
$$;

drop trigger if exists onboarding_responses_before_write on public.onboarding_responses;
create trigger onboarding_responses_before_write
  before insert or update on public.onboarding_responses
  for each row execute function public.onboarding_responses_before_write();

drop trigger if exists onboarding_responses_sync_completed_at on public.onboarding_responses;
create trigger onboarding_responses_sync_completed_at
  after insert or update or delete on public.onboarding_responses
  for each row execute function public.sync_onboarding_completed_at();

alter table public.onboarding_responses enable row level security;

drop policy if exists "own onboarding responses are readable" on public.onboarding_responses;
create policy "own onboarding responses are readable" on public.onboarding_responses
  for select to authenticated
  using (profile_id = (select auth.uid()));

drop policy if exists "own onboarding responses are insertable" on public.onboarding_responses;
create policy "own onboarding responses are insertable" on public.onboarding_responses
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

drop policy if exists "own onboarding responses are updatable" on public.onboarding_responses;
create policy "own onboarding responses are updatable" on public.onboarding_responses
  for update to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

revoke all on table public.onboarding_responses from public, anon, authenticated;
grant select on table public.onboarding_responses to authenticated;
grant insert (
  profile_id,
  areas,
  problems,
  tools,
  ai_experience,
  primary_goal,
  available_time
) on table public.onboarding_responses to authenticated;
grant update (
  areas,
  problems,
  tools,
  ai_experience,
  primary_goal,
  available_time
) on table public.onboarding_responses to authenticated;

-- ---------------------------------------------------------------------------
-- Area de negocio del caso. Nullable: los ocho casos actuales quedan sin area.
-- Un valor nuevo se habilita insertando kind = area; no hace falta otro check.
-- La taxonomia de categories / use_case_categories no se toca.
-- ---------------------------------------------------------------------------

alter table public.use_cases
  add column if not exists area text;

comment on column public.use_cases.area is
  'Area de negocio principal: marketing, finanzas o administracion. Null en los casos anteriores a SkillBot 2.0. Distinta de categories.';

create or replace function public.use_cases_area_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if new.area is not null then
    perform public.assert_onboarding_value('area', new.area);
  end if;

  return new;
end;
$$;

drop trigger if exists use_cases_area_validate on public.use_cases;
create trigger use_cases_area_validate
  before insert or update of area on public.use_cases
  for each row execute function public.use_cases_area_validate();

-- ---------------------------------------------------------------------------
-- Etiquetas de matching. PK (use_case_id, kind, value): un caso puede tener
-- varias de la misma clase y no puede repetir la misma combinacion.
-- ---------------------------------------------------------------------------

create table if not exists public.use_case_tags (
  use_case_id text not null references public.use_cases (id) on delete cascade,
  kind text not null check (kind in ('problem', 'goal', 'area', 'tool', 'experience', 'time')),
  value text not null check (value ~ '^[a-z][a-z0-9]*(?:[_-][a-z0-9]+)*$' and char_length(value) <= 64),
  primary key (use_case_id, kind, value)
);

create index if not exists use_case_tags_kind_value_idx
  on public.use_case_tags (kind, value);

create or replace function public.use_case_tags_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  perform public.assert_onboarding_value(new.kind, new.value);
  return new;
end;
$$;

drop trigger if exists use_case_tags_validate on public.use_case_tags;
create trigger use_case_tags_validate
  before insert or update on public.use_case_tags
  for each row execute function public.use_case_tags_validate();

alter table public.use_case_tags enable row level security;

drop policy if exists "use case tags are readable" on public.use_case_tags;
create policy "use case tags are readable" on public.use_case_tags
  for select to anon, authenticated
  using (true);

revoke all on table public.use_case_tags from public, anon, authenticated;
grant select on table public.use_case_tags to anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPC de cierre. No recibe profile_id: la fila es siempre auth.uid().
-- El upsert y la marca ocurren en la misma transaccion por el trigger AFTER.
-- ---------------------------------------------------------------------------

create or replace function public.complete_onboarding(
  p_areas text[],
  p_problems text[],
  p_tools text[],
  p_ai_experience text,
  p_primary_goal text,
  p_available_time text
)
returns public.onboarding_responses
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.onboarding_responses;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if not exists (select 1 from public.profiles where id = v_uid) then
    raise exception 'profile % not found', v_uid using errcode = 'P0002';
  end if;

  insert into public.onboarding_responses (
    profile_id,
    areas,
    problems,
    tools,
    ai_experience,
    primary_goal,
    available_time
  ) values (
    v_uid,
    p_areas,
    p_problems,
    p_tools,
    p_ai_experience,
    p_primary_goal,
    p_available_time
  )
  on conflict (profile_id) do update
    set areas = excluded.areas,
        problems = excluded.problems,
        tools = excluded.tools,
        ai_experience = excluded.ai_experience,
        primary_goal = excluded.primary_goal,
        available_time = excluded.available_time
  returning * into v_row;

  return v_row;
end;
$$;

comment on function public.complete_onboarding(text[], text[], text[], text, text, text) is
  'Guarda las seis respuestas del usuario autenticado y fija onboarding_completed_at si todavia era null. Falla entero si la respuesta o la marca no se pueden escribir.';

revoke all on function public.text_array_is_set(text[]) from public;
revoke all on function public.onboarding_options_guard() from public;
revoke all on function public.onboarding_options_prevent_delete() from public;
revoke all on function public.protect_onboarding_completed_at() from public;
revoke all on function public.assert_onboarding_value(text, text) from public;
revoke all on function public.onboarding_responses_before_write() from public;
revoke all on function public.sync_onboarding_completed_at() from public;
revoke all on function public.use_cases_area_validate() from public;
revoke all on function public.use_case_tags_validate() from public;
revoke all on function public.complete_onboarding(text[], text[], text[], text, text, text) from public;

grant execute on function public.text_array_is_set(text[]) to authenticated;
grant execute on function public.onboarding_options_guard() to authenticated;
grant execute on function public.protect_onboarding_completed_at() to authenticated;
grant execute on function public.assert_onboarding_value(text, text) to authenticated;
grant execute on function public.onboarding_responses_before_write() to authenticated;
grant execute on function public.sync_onboarding_completed_at() to authenticated;
grant execute on function public.use_cases_area_validate() to authenticated;
grant execute on function public.use_case_tags_validate() to authenticated;
grant execute on function public.complete_onboarding(text[], text[], text[], text, text, text) to authenticated;

revoke all on function public.complete_onboarding(text[], text[], text[], text, text, text) from anon;
revoke all on function public.sync_onboarding_completed_at() from anon;
revoke all on function public.assert_onboarding_value(text, text) from anon;
