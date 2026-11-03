-- Tres desafíos por caso. El XP se otorga una vez por desafío y una vez el bonus,
-- dentro de la misma transacción. Completar el caso es terminar los tres.

alter table public.use_case_fields
  add column if not exists in_practice boolean not null default false;

alter table public.use_case_challenges
  add column if not exists position integer,
  add column if not exists type text,
  add column if not exists instruction text,
  add column if not exists feedback_correct text,
  add column if not exists feedback_incorrect text,
  add column if not exists xp integer not null default 10;

update public.use_case_challenges
   set position = 1,
       type = 'detect_error',
       instruction = coalesce(instruction, question),
       feedback_correct = coalesce(feedback_correct, ''),
       feedback_incorrect = coalesce(feedback_incorrect, '')
 where position is null;

alter table public.challenge_options
  add column if not exists position integer;

update public.challenge_options
   set position = 1
 where position is null;

do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
      from pg_constraint con
      join pg_class rel on rel.oid = con.conrelid
      join pg_namespace nsp on nsp.oid = rel.relnamespace
     where nsp.nspname = 'public'
       and rel.relname = 'challenge_options'
       and con.contype = 'f'
  loop
    execute format('alter table public.challenge_options drop constraint %I', constraint_name);
  end loop;
end $$;

alter table public.use_case_challenges drop constraint if exists use_case_challenges_pkey;
alter table public.use_case_challenges alter column position set not null;
alter table public.use_case_challenges alter column type set not null;
alter table public.use_case_challenges alter column instruction set not null;
alter table public.use_case_challenges alter column feedback_correct set not null;
alter table public.use_case_challenges alter column feedback_incorrect set not null;
alter table public.use_case_challenges add primary key (use_case_id, position);
alter table public.use_case_challenges drop constraint if exists use_case_challenges_type_check;
alter table public.use_case_challenges
  add constraint use_case_challenges_type_check
  check (type in ('detect_error', 'missing_information', 'judge_result'));
alter table public.use_case_challenges drop constraint if exists use_case_challenges_position_check;
alter table public.use_case_challenges
  add constraint use_case_challenges_position_check
  check (position between 1 and 3);

alter table public.challenge_options drop constraint if exists challenge_options_pkey;
alter table public.challenge_options alter column position set not null;
alter table public.challenge_options add primary key (use_case_id, position, letter);
alter table public.challenge_options
  add constraint challenge_options_challenge_fkey
  foreign key (use_case_id, position)
  references public.use_case_challenges (use_case_id, position)
  on delete cascade;

drop index if exists public.challenge_options_one_correct;
create unique index challenge_options_one_correct
  on public.challenge_options (use_case_id, position)
  where is_correct;

create table if not exists public.practice_rewards (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  use_case_id text not null references public.use_cases (id) on delete cascade,
  position integer not null check (position between 0 and 3),
  xp integer not null check (xp >= 0),
  created_at timestamptz not null default now(),
  primary key (profile_id, use_case_id, position)
);

alter table public.practice_rewards enable row level security;

drop policy if exists "demo practice rewards are manageable" on public.practice_rewards;
create policy "demo practice rewards are manageable" on public.practice_rewards
  for all to anon, authenticated
  using (profile_id = public.demo_profile_id())
  with check (profile_id = public.demo_profile_id());

grant select, insert, update, delete on public.practice_rewards to anon, authenticated;

-- position 1-3: un desafío. position 0: bonus por terminar los tres.
-- Si el caso ya estaba completado por resolve_use_case, no se vuelve a pagar.
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
  v_profile uuid := public.demo_profile_id();
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
  else
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

grant execute on function public.complete_practice_challenge(text, integer, text, boolean, date) to anon, authenticated;
