-- Devuelve el progreso de TODOS los perfiles de producto a cero, sin tocar
-- el esqueleto, el catalogo ni las cuentas de Auth.
--
-- Ya no existe el perfil demo. Cada usuario autenticado tiene su propia fila
-- en public.profiles, creada por el trigger handle_new_user().
--
-- No se aplica solo: el config.toml carga unicamente ./seed.sql.

delete from public.practice_rewards;
delete from public.use_case_step_progress;
delete from public.use_case_progress;
delete from public.challenge_attempts;
delete from public.activity_days;
delete from public.user_achievements;
delete from public.user_skills;

update public.profiles
   set xp = 0,
       level_id = 'principiante';
