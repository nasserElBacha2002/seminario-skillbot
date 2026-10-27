-- Resetea el progreso de UN perfil de producto. No toca el catálogo ni Auth.
--
-- Obligatorio: reemplazar target_profile_id con el uuid de auth.users /
-- public.profiles. El valor sentinela aborta a propósito para no resetear
-- a todos los usuarios.
--
-- No se aplica solo: el config.toml carga unicamente ./seed.sql.
--
-- Para borrar el progreso de TODAS las cuentas, usar a mano y con cuidado
-- supabase/seeds/reset_all_progress_destructive.sql.

do $$
declare
  -- Pegar acá el uuid del perfil a resetear (mismo id que en Authentication).
  target_profile_id uuid := '00000000-0000-0000-0000-000000000000';
begin
  if target_profile_id = '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'reset_progress.sql: reemplazá target_profile_id con el uuid del perfil a resetear';
  end if;

  if not exists (select 1 from public.profiles where id = target_profile_id) then
    raise exception 'reset_progress.sql: no existe public.profiles.id = %', target_profile_id;
  end if;

  delete from public.practice_rewards where profile_id = target_profile_id;
  delete from public.use_case_step_progress where profile_id = target_profile_id;
  delete from public.use_case_progress where profile_id = target_profile_id;
  delete from public.challenge_attempts where profile_id = target_profile_id;
  delete from public.activity_days where profile_id = target_profile_id;
  delete from public.user_achievements where profile_id = target_profile_id;
  delete from public.user_skills where profile_id = target_profile_id;

  update public.profiles
     set xp = 0,
         level_id = 'principiante'
   where id = target_profile_id;
end $$;
