-- Esqueleto minimo: solo lo estructural que la app necesita para arrancar.
--
-- A proposito NO siembra nada atado a casos de uso concretos (progreso,
-- actividad, logros desbloqueados, XP), porque el catalogo de casos y sus
-- desafios van a cambiar y esas filas quedarian huerfanas apuntando a slugs
-- inexistentes. El perfil arranca en cero y se llena practicando.
--
-- Idempotente: se puede volver a correr sin duplicar nada.

-- Umbrales del sistema de niveles. Es configuracion, no contenido.
insert into public.levels (id, name, min_xp, next_xp, sort_order) values
  ('principiante', 'Principiante', 0, 200, 1),
  ('intermedio', 'Intermedio', 200, 500, 2),
  ('avanzado', 'Avanzado', 500, 1000, 3),
  ('experto', 'Experto', 1000, null, 4)
on conflict (id) do update
  set name = excluded.name,
      min_xp = excluded.min_xp,
      next_xp = excluded.next_xp,
      sort_order = excluded.sort_order;

-- Unico perfil de la demo. Tiene que existir: el frontend lo lee por el id
-- fijo de demo_profile_id().
insert into public.profiles (id, display_name, initials, goal, interests, xp, level_id) values (
  public.demo_profile_id(),
  'Martín',
  'MR',
  'Aprender a elegir y utilizar herramientas de IA para resolver tareas cotidianas.',
  array['Productividad', 'Generación de contenido', 'Investigación'],
  0,
  'principiante'
)
on conflict (id) do nothing;

-- Taxonomia de habilidades. Cada caso de uso en src/data.js apunta a uno de
-- estos ids mediante su campo skill. Los valores por usuario no se siembran:
-- user_skills arranca vacia y la app trata la ausencia de fila como 0%.
insert into public.skills (id, name, color, sort_order) values
  ('comunicacion', 'Comunicación', 'violet', 1),
  ('investigacion', 'Investigación', 'blue', 2),
  ('organizacion', 'Organización', 'orange', 3),
  ('creatividad', 'Creatividad', 'pink', 4),
  ('analisis', 'Análisis', 'green', 5)
on conflict (id) do update
  set name = excluded.name,
      color = excluded.color,
      sort_order = excluded.sort_order;

-- Catalogo de logros. Son hitos genericos, no dependen de ningun caso puntual.
-- Los ids los usa el desbloqueo automatico en src/context/SkillbotData.jsx.
insert into public.achievements (id, title, description, icon, sort_order) values
  ('primer-caso', 'Primer caso resuelto', 'Completá tu primer caso.', 'Trophy', 1),
  ('racha-3', '3 días practicando', 'Practicá tres días seguidos.', 'Flame', 2),
  ('explorador', 'Explorador de IA', 'Probá tres casos de uso distintos.', 'Search', 3),
  ('cinco-casos', '5 problemas resueltos', 'Llegá a cinco casos resueltos.', 'Medal', 4)
on conflict (id) do update
  set title = excluded.title,
      description = excluded.description,
      icon = excluded.icon,
      sort_order = excluded.sort_order;
