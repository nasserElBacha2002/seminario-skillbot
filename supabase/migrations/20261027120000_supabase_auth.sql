-- SkillBot: de perfil demo a Supabase Auth.
-- profiles.id pasa a ser auth.users.id. RLS y RPCs resuelven al usuario por JWT.

-- El perfil demo (Martín) no existe en auth.users y no puede satisfacer la FK.
-- Su progreso compartido se borra a propósito: cada cuenta Auth arranca en cero.
delete from public.profiles
 where not exists (select 1 from auth.users u where u.id = profiles.id);

alter table public.profiles
  drop constraint if exists profiles_id_fkey;

alter table public.profiles
  add constraint profiles_id_fkey
  foreign key (id) references auth.users (id) on delete cascade;

create or replace function public.require_auth_uid()
returns uuid
language plpgsql
stable
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  return uid;
end;
$$;

create or replace function public.profile_display_name(p_email text, p_metadata jsonb)
returns text
language sql
immutable
as $$
  select coalesce(
    nullif(btrim(coalesce(
      p_metadata->>'display_name',
      p_metadata->>'full_name',
      p_metadata->>'name',
      ''
    )), ''),
    nullif(split_part(coalesce(p_email, ''), '@', 1), ''),
    'Usuario'
  );
$$;

create or replace function public.profile_initials(p_name text)
returns text
language sql
immutable
as $$
  select case
    when coalesce(words[2], '') <> '' then upper(left(words[1], 1) || left(words[2], 1))
    when coalesce(words[1], '') <> '' then upper(left(words[1], 2))
    else 'SB'
  end
  from (
    select regexp_split_to_array(btrim(coalesce(p_name, '')), '[^[:alnum:]]+') as words
  ) parsed;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
begin
  v_name := public.profile_display_name(new.email, new.raw_user_meta_data);
  insert into public.profiles (id, display_name, initials, goal, interests, xp, level_id)
  values (
    new.id,
    v_name,
    public.profile_initials(v_name),
    'Resolver tareas concretas usando IA, sin tener que saber de antemano qué herramienta elegir.',
    '{}',
    0,
    'principiante'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

insert into public.profiles (id, display_name, initials, goal, interests, xp, level_id)
select
  u.id,
  public.profile_display_name(u.email, u.raw_user_meta_data),
  public.profile_initials(public.profile_display_name(u.email, u.raw_user_meta_data)),
  'Resolver tareas concretas usando IA, sin tener que saber de antemano qué herramienta elegir.',
  '{}',
  0,
  'principiante'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- Policies de runtime: el usuario solo ve y escribe su fila.
drop policy if exists "demo profile is readable" on public.profiles;
drop policy if exists "demo profile is writable" on public.profiles;
drop policy if exists "demo skills are manageable" on public.user_skills;
drop policy if exists "demo achievements are manageable" on public.user_achievements;
drop policy if exists "demo progress is manageable" on public.use_case_progress;
drop policy if exists "demo attempts are manageable" on public.challenge_attempts;
drop policy if exists "demo activity is manageable" on public.activity_days;
drop policy if exists "demo step progress is manageable" on public.use_case_step_progress;
drop policy if exists "demo practice rewards are manageable" on public.practice_rewards;

create policy "own profile is readable" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy "own profile is writable" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "own skills are manageable" on public.user_skills
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own achievements are manageable" on public.user_achievements
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own progress is manageable" on public.use_case_progress
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own attempts are manageable" on public.challenge_attempts
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own activity is manageable" on public.activity_days
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own step progress is manageable" on public.use_case_step_progress
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own practice rewards are manageable" on public.practice_rewards
  for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

revoke all on public.profiles from anon;
revoke all on public.user_skills from anon;
revoke all on public.user_achievements from anon;
revoke all on public.use_case_progress from anon;
revoke all on public.challenge_attempts from anon;
revoke all on public.activity_days from anon;
revoke all on public.use_case_step_progress from anon;
revoke all on public.practice_rewards from anon;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on
  public.user_skills,
  public.user_achievements,
  public.use_case_progress,
  public.challenge_attempts,
  public.activity_days,
  public.use_case_step_progress,
  public.practice_rewards
to authenticated;

revoke execute on function public.demo_profile_id() from public, anon, authenticated;
revoke execute on function public.add_xp(uuid, integer) from public, anon;
revoke execute on function public.resolve_use_case(text, date) from public, anon;
revoke execute on function public.complete_practice_challenge(text, integer, text, boolean, date) from public, anon;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.profile_display_name(text, jsonb) from public, anon, authenticated;
revoke execute on function public.profile_initials(text) from public, anon, authenticated;

grant execute on function public.require_auth_uid() to authenticated;
grant execute on function public.add_xp(uuid, integer) to authenticated;
grant execute on function public.resolve_use_case(text, date) to authenticated;
grant execute on function public.complete_practice_challenge(text, integer, text, boolean, date) to authenticated;

create or replace function public.add_xp(p_profile_id uuid, p_amount integer)
returns public.profiles
language plpgsql
security invoker
set search_path = public
as $$
declare
  updated public.profiles;
begin
  if public.require_auth_uid() is distinct from p_profile_id then
    raise exception 'not allowed' using errcode = '42501';
  end if;

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

create or replace function public.resolve_use_case(p_use_case_id text, p_day date)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_profile uuid := public.require_auth_uid();
  v_status text;
  v_xp integer;
  v_skill text;
  v_awarded integer := 0;
begin
  if p_use_case_id is null or btrim(p_use_case_id) = '' then
    raise exception 'use case id is required';
  end if;

  if p_day is null then
    raise exception 'activity day is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_profile::text), hashtext(p_use_case_id));

  select status
    into v_status
    from public.use_case_progress
   where profile_id = v_profile
     and use_case_slug = p_use_case_id
   for update;

  if v_status is distinct from 'completed' then
    select xp_reward, skill_id
      into v_xp, v_skill
      from public.use_cases
     where id = p_use_case_id
       and status = 'published';

    if not found then
      raise exception 'use case % is not published', p_use_case_id;
    end if;

    insert into public.use_case_progress (
      profile_id, use_case_slug, progress, status, completed_at, updated_at
    ) values (
      v_profile, p_use_case_id, 100, 'completed', now(), now()
    )
    on conflict (profile_id, use_case_slug) do update
      set progress = 100,
          status = 'completed',
          completed_at = coalesce(public.use_case_progress.completed_at, now()),
          updated_at = now()
    where public.use_case_progress.status is distinct from 'completed';

    if coalesce(v_xp, 0) > 0 then
      perform public.add_xp(v_profile, v_xp);
      v_awarded := v_xp;
    end if;

    if v_skill is not null then
      insert into public.user_skills (profile_id, skill_id, value, updated_at)
      values (v_profile, v_skill, least(100, 5), now())
      on conflict (profile_id, skill_id) do update
        set value = least(100, public.user_skills.value + 5),
            updated_at = now();
    end if;
  end if;

  insert into public.activity_days (profile_id, day)
  values (v_profile, p_day)
  on conflict (profile_id, day) do nothing;

  return v_awarded;
end;
$$;

create or replace function public.complete_practice_challenge(
  p_use_case_id text,
  p_position integer,
  p_selected text,
  p_correct boolean,
  p_day date
) returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_profile uuid := public.require_auth_uid();
  v_status text;
  v_xp integer := 0;
  v_reward integer := 0;
  v_bonus integer := 0;
  v_skill text;
  v_done integer := 0;
  v_awarded integer := 0;
  v_inserted integer := 0;
begin
  if p_use_case_id is null or btrim(p_use_case_id) = '' then
    raise exception 'use case id is required';
  end if;
  if p_position is null or p_position not between 1 and 3 then
    raise exception 'practice position must be between 1 and 3';
  end if;
  if p_day is null then
    raise exception 'activity day is required';
  end if;
  if not exists (
    select 1 from public.use_case_challenges
     where use_case_id = p_use_case_id and position = p_position
  ) then
    raise exception 'practice challenge % of % does not exist', p_position, p_use_case_id;
  end if;

  perform pg_advisory_xact_lock(hashtext(v_profile::text), hashtext(p_use_case_id));

  select status
    into v_status
    from public.use_case_progress
   where profile_id = v_profile
     and use_case_slug = p_use_case_id
   for update;

  if v_status = 'completed' and not exists (
    select 1 from public.practice_rewards
     where profile_id = v_profile and use_case_id = p_use_case_id
  ) then
    insert into public.practice_rewards (profile_id, use_case_id, position, xp)
    select v_profile, p_use_case_id, reward_position, 0
      from (values (0), (1), (2), (3)) as rewards(reward_position)
    on conflict (profile_id, use_case_id, position) do nothing;
  elsif coalesce(p_correct, false) then
    select xp
      into v_xp
      from public.use_case_challenges
     where use_case_id = p_use_case_id
       and position = p_position;

    insert into public.practice_rewards (profile_id, use_case_id, position, xp)
    values (v_profile, p_use_case_id, p_position, coalesce(v_xp, 0))
    on conflict (profile_id, use_case_id, position) do nothing;

    get diagnostics v_inserted = row_count;
    if v_inserted = 1 and coalesce(v_xp, 0) > 0 then
      perform public.add_xp(v_profile, v_xp);
      v_awarded := v_xp;
    end if;

    select count(*)
      into v_done
      from public.practice_rewards
     where profile_id = v_profile
       and use_case_id = p_use_case_id
       and position between 1 and 3;

    if v_done >= 3 then
      select xp_reward, skill_id
        into v_reward, v_skill
        from public.use_cases
       where id = p_use_case_id
         and status = 'published';

      v_bonus := greatest(coalesce(v_reward, 0) - coalesce((
        select sum(xp) from public.use_case_challenges where use_case_id = p_use_case_id
      ), 0), 0);

      insert into public.practice_rewards (profile_id, use_case_id, position, xp)
      values (v_profile, p_use_case_id, 0, v_bonus)
      on conflict (profile_id, use_case_id, position) do nothing;

      get diagnostics v_inserted = row_count;
      if v_inserted = 1 then
        if v_bonus > 0 then
          perform public.add_xp(v_profile, v_bonus);
          v_awarded := v_awarded + v_bonus;
        end if;
        if v_skill is not null then
          insert into public.user_skills (profile_id, skill_id, value, updated_at)
          values (v_profile, v_skill, least(100, 5), now())
          on conflict (profile_id, skill_id) do update
            set value = least(100, public.user_skills.value + 5),
                updated_at = now();
        end if;
      end if;

      insert into public.use_case_progress (
        profile_id, use_case_slug, progress, status, completed_at, updated_at
      ) values (
        v_profile, p_use_case_id, 100, 'completed', now(), now()
      )
      on conflict (profile_id, use_case_slug) do update
        set progress = 100,
            status = 'completed',
            completed_at = coalesce(public.use_case_progress.completed_at, now()),
            updated_at = now();
    else
      insert into public.use_case_progress (
        profile_id, use_case_slug, progress, status, updated_at
      ) values (
        v_profile, p_use_case_id, round(v_done * 100.0 / 3)::integer, 'in_progress', now()
      )
      on conflict (profile_id, use_case_slug) do update
        set progress = case
              when public.use_case_progress.status = 'completed' then public.use_case_progress.progress
              else greatest(public.use_case_progress.progress, round(v_done * 100.0 / 3)::integer)
            end,
            status = case
              when public.use_case_progress.status = 'completed' then public.use_case_progress.status
              else 'in_progress'
            end,
            updated_at = now()
      where public.use_case_progress.status is distinct from 'completed';
    end if;
  end if;

  insert into public.activity_days (profile_id, day)
  values (v_profile, p_day)
  on conflict (profile_id, day) do nothing;

  insert into public.challenge_attempts (
    profile_id, use_case_slug, selected_option, is_correct, xp_earned
  ) values (
    v_profile, p_use_case_id, coalesce(p_selected, '?'), coalesce(p_correct, false), v_awarded
  );

  return v_awarded;
end;
$$;
