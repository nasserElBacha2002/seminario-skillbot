-- Fase 4: el cliente puede cambiar display_name. initials las calcula SQL.
-- No se otorga UPDATE de tabla sobre profiles: xp y level_id siguen solo por add_xp.

create or replace function public.update_profile_name(p_display_name text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid := public.require_auth_uid();
  v_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  updated public.profiles;
begin
  if v_name is null then
    raise exception 'display name is required' using errcode = '22023';
  end if;

  update public.profiles
     set display_name = v_name,
         initials = public.profile_initials(v_name)
   where id = v_profile
  returning * into updated;

  if not found then
    raise exception 'profile % not found', v_profile;
  end if;

  return updated;
end;
$$;

revoke execute on function public.update_profile_name(text) from public, anon;
grant execute on function public.update_profile_name(text) to authenticated;
