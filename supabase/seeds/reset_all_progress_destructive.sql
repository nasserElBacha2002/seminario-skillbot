-- DESTRUCTIVO. Resetea el progreso de TODOS los perfiles de producto.
-- No toca el catálogo, el esqueleto ni las cuentas de Auth.
--
-- No es el script estándar. Preferí reset_progress.sql (un uuid explícito).
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
