-- Resolver un caso es una sola transacción: progreso, XP, habilidad y actividad.
-- La recompensa se otorga una vez por perfil y caso, aunque lleguen dos pedidos juntos.

create or replace function public.resolve_use_case(p_use_case_id text, p_day date)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_profile uuid := public.demo_profile_id();
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

  -- Serializa las dos primeras resoluciones del mismo caso. El unique de
  -- progreso no alcanza: las dos pueden no ver la fila todavía.
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

grant execute on function public.resolve_use_case(text, date) to anon, authenticated;
