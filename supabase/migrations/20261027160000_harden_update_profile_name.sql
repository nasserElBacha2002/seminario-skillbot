-- search_path vacío en update_profile_name: las referencias van calificadas.
-- Sigue sin GRANT UPDATE sobre public.profiles.

create or replace function public.update_profile_name(p_display_name text)
returns public.profiles
language plpgsql
security definer
set search_path = ''
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
