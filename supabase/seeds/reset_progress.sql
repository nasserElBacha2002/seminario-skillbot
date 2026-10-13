-- Devuelve el perfil demo a cero sin tocar el esqueleto, el catalogo ni el
-- schema. Sirve para volver a probar la app desde el principio.
--
-- No se aplica solo: config.toml carga únicamente ./seed.sql.

delete from public.use_case_step_progress where profile_id = public.demo_profile_id();
delete from public.use_case_progress where profile_id = public.demo_profile_id();
delete from public.challenge_attempts where profile_id = public.demo_profile_id();
delete from public.activity_days where profile_id = public.demo_profile_id();
delete from public.user_achievements where profile_id = public.demo_profile_id();
delete from public.user_skills where profile_id = public.demo_profile_id();

update public.profiles
   set xp = 0,
       level_id = 'principiante'
 where id = public.demo_profile_id();
