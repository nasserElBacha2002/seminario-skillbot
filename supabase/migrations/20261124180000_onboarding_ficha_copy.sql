-- Ajusta textos del onboarding (dificultades vs objetivos) y no cambia ids de matching.

insert into public.onboarding_options (kind, value, label, area, sort_order) values
  ('problem', 'atraer_clientes', 'Pocas consultas o clientes nuevos', 'marketing', 1),
  ('problem', 'ahorrar_tiempo_repetitivo', 'Repito las mismas tareas a mano', null, 19),
  ('problem', 'decidir_con_informacion', 'Decido sin datos claros', null, 20),
  ('problem', 'empezar_sin_experiencia', 'Me trabo sin saber usar la herramienta', null, 21)
on conflict (kind, value) do update
  set label = excluded.label,
      area = excluded.area,
      sort_order = excluded.sort_order;