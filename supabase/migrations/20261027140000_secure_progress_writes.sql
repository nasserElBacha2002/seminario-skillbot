-- Correcciones de seguridad post code-review (Fase 1 + 2).
--
-- Objetivo:
--   * profiles: authenticated solo SELECT. xp y level_id se cambian por RPC.
--   * Tablas de progreso: SELECT propio; escrituras de negocio por RPC DEFINER.
--   * Escrituras de UI que ya existían (pasos, arranque de práctica, racha, logros)
--     quedan con la operación mínima.
--   * add_xp(p_amount): el receptor es siempre auth.uid(). Sin execute para clientes.
--   * complete_practice_challenge: el servidor lee challenge_options.is_correct.
--
-- RPCs SECURITY DEFINER:
--   Tras revocar INSERT/UPDATE/DELETE de authenticated, INVOKER no podría escribir.
--   Las tres funciones validan require_auth_uid(), no aceptan un profile ajeno,
--   search_path queda fijo y execute de anon queda revocado.

-- 20261027120000 ya ejecutó:
--   delete from public.profiles
--    where not exists (select 1 from auth.users u where u.id = profiles.id);
-- Eso cubre el perfil demo Martín (11111111-1111-4111-8111-111111111111)
-- y cualquier profile sin auth.users. No toca cuentas Auth válidas.
--
-- Hijas con ON DELETE CASCADE hacia profiles(id), que se fueron con ese delete:
--   user_skills, user_achievements, use_case_progress, use_case_step_progress,
--   challenge_attempts, activity_days, practice_rewards.
-- El catálogo público no se toca.
--
-- Con la FK profiles.id → auth.users(id) no deberían quedar restos.
-- Esta aserción documenta el invariante; si falla, no seguir.
do $$
begin
  if exists (
    select 1
      from public.profiles p
     where not exists (select 1 from auth.users u where u.id = p.id)
  ) then
    raise exception 'orphan profiles remain; apply 20261027120000 before this migration';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Policies: una operación por policy. Sin FOR ALL.
-- ---------------------------------------------------------------------------

drop policy if exists "own profile is writable" on public.profiles;
drop policy if exists "own skills are manageable" on public.user_skills;
drop policy if exists "own achievements are manageable" on public.user_achievements;
drop policy if exists "own progress is manageable" on public.use_case_progress;
drop policy if exists "own attempts are manageable" on public.challenge_attempts;
drop policy if exists "own activity is manageable" on public.activity_days;
drop policy if exists "own step progress is manageable" on public.use_case_step_progress;
drop policy if exists "own practice rewards are manageable" on public.practice_rewards;

drop policy if exists "own skills are readable" on public.user_skills;
drop policy if exists "own achievements are readable" on public.user_achievements;
drop policy if exists "own achievements are insertable" on public.user_achievements;
drop policy if exists "own progress is readable" on public.use_case_progress;
drop policy if exists "own progress is insertable" on public.use_case_progress;
drop policy if exists "own progress is updatable" on public.use_case_progress;
drop policy if exists "own attempts are readable" on public.challenge_attempts;
drop policy if exists "own activity is readable" on public.activity_days;
drop policy if exists "own activity is insertable" on public.activity_days;
drop policy if exists "own activity is updatable" on public.activity_days;
drop policy if exists "own step progress is readable" on public.use_case_step_progress;
drop policy if exists "own step progress is insertable" on public.use_case_step_progress;
drop policy if exists "own step progress is deletable" on public.use_case_step_progress;
drop policy if exists "own practice rewards are readable" on public.practice_rewards;

create policy "own skills are readable" on public.user_skills
  for select to authenticated
  using (profile_id = (select auth.uid()));

create policy "own achievements are readable" on public.user_achievements
  for select to authenticated
  using (profile_id = (select auth.uid()));

-- Desbloqueo de logros: loadWithAchievements en el frontend. No hay RPC.
create policy "own achievements are insertable" on public.user_achievements
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy "own progress is readable" on public.use_case_progress
  for select to authenticated
  using (profile_id = (select auth.uid()));

-- Pasos / beginPractice / restartPractice. Completado (100) solo por RPC.
create policy "own progress is insertable" on public.use_case_progress
  for insert to authenticated
  with check (
    profile_id = (select auth.uid())
    and status = 'in_progress'
    and progress between 0 and 80
  );

create policy "own progress is updatable" on public.use_case_progress
  for update to authenticated
  using (profile_id = (select auth.uid()))
  with check (
    profile_id = (select auth.uid())
    and status = 'in_progress'
    and progress between 0 and 80
  );

create policy "own attempts are readable" on public.challenge_attempts
  for select to authenticated
  using (profile_id = (select auth.uid()));

create policy "own activity is readable" on public.activity_days
  for select to authenticated
  using (profile_id = (select auth.uid()));

-- markActivityToday() hace upsert (INSERT ON CONFLICT DO UPDATE).
create policy "own activity is insertable" on public.activity_days
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy "own activity is updatable" on public.activity_days
  for update to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own step progress is readable" on public.use_case_step_progress
  for select to authenticated
  using (profile_id = (select auth.uid()));

create policy "own step progress is insertable" on public.use_case_step_progress
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy "own step progress is deletable" on public.use_case_step_progress
  for delete to authenticated
  using (profile_id = (select auth.uid()));

create policy "own practice rewards are readable" on public.practice_rewards
  for select to authenticated
  using (profile_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Grants: authenticated no escribe xp/level ni rewards/skills/attempts.
-- ---------------------------------------------------------------------------

revoke all on public.profiles from anon, authenticated;
revoke all on public.user_skills from anon, authenticated;
revoke all on public.user_achievements from anon, authenticated;
revoke all on public.use_case_progress from anon, authenticated;
revoke all on public.challenge_attempts from anon, authenticated;
revoke all on public.activity_days from anon, authenticated;
revoke all on public.use_case_step_progress from anon, authenticated;
revoke all on public.practice_rewards from anon, authenticated;

grant select on public.profiles to authenticated;
grant select on public.user_skills to authenticated;
grant select, insert on public.user_achievements to authenticated;
grant select, insert, update on public.use_case_progress to authenticated;
grant select on public.challenge_attempts to authenticated;
grant select, insert, update on public.activity_days to authenticated;
grant select, insert, delete on public.use_case_step_progress to authenticated;
grant select on public.practice_rewards to authenticated;

-- ---------------------------------------------------------------------------
-- add_xp(p_amount): receptor = JWT. Sin execute para el cliente.
-- ---------------------------------------------------------------------------

create or replace function public.add_xp(p_amount integer)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid := public.require_auth_uid();
  updated public.profiles;
begin
  update public.profiles
     set xp = xp + p_amount
   where id = v_profile
  returning * into updated;

  if not found then
    raise exception 'profile % not found', v_profile;
  end if;

  update public.profiles
     set level_id = (
       select id
         from public.levels
        where min_xp <= updated.xp
        order by min_xp desc
        limit 1
     )
   where id = v_profile
  returning * into updated;

  return updated;
end;
$$;

create or replace function public.resolve_use_case(p_use_case_id text, p_day date)
returns integer
language plpgsql
security definer
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
      perform public.add_xp(v_xp);
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

drop function if exists public.complete_practice_challenge(text, integer, text, boolean, date);

create or replace function public.complete_practice_challenge(
  p_use_case_id text,
  p_position integer,
  p_selected text,
  p_day date
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid := public.require_auth_uid();
  v_status text;
  v_correct boolean;
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
  if p_selected is null or btrim(p_selected) = '' then
    raise exception 'selected option is required';
  end if;

  select o.is_correct
    into v_correct
    from public.use_case_challenges c
    join public.challenge_options o
      on o.use_case_id = c.use_case_id
     and o.position = c.position
   where c.use_case_id = p_use_case_id
     and c.position = p_position
     and o.letter = p_selected;

  if not found then
    raise exception 'practice option % of %/% does not exist', p_selected, p_position, p_use_case_id;
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
  elsif v_correct then
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
      perform public.add_xp(v_xp);
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
          perform public.add_xp(v_bonus);
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
    v_profile, p_use_case_id, p_selected, v_correct, v_awarded
  );

  return v_awarded;
end;
$$;

drop function if exists public.add_xp(uuid, integer);

revoke execute on function public.add_xp(integer) from public, anon, authenticated;
revoke execute on function public.resolve_use_case(text, date) from public, anon;
revoke execute on function public.complete_practice_challenge(text, integer, text, date) from public, anon;

grant execute on function public.resolve_use_case(text, date) to authenticated;
grant execute on function public.complete_practice_challenge(text, integer, text, date) to authenticated;
