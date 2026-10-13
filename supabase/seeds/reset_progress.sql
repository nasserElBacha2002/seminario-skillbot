-- Devuelve el perfil demo a cero sin tocar el esqueleto ni el schema.
--
-- Corré esto antes de reemplazar el catálogo de casos de uso en src/data.js:
-- las filas de use_case_progress y challenge_attempts referencian cada caso
-- por su slug sin foreign key, así que si el catálogo cambia quedan huérfanas
-- y la app las sigue contando en "casos resueltos" y en el progreso general.
--
-- No se aplica solo: config.toml carga únicamente ./seed.sql.

delete from public.use_case_progress where profile_id = public.demo_profile_id();
delete from public.challenge_attempts where profile_id = public.demo_profile_id();
delete from public.activity_days where profile_id = public.demo_profile_id();
delete from public.user_achievements where profile_id = public.demo_profile_id();
delete from public.user_skills where profile_id = public.demo_profile_id();

update public.profiles
   set xp = 0,
       level_id = 'principiante'
 where id = public.demo_profile_id();
