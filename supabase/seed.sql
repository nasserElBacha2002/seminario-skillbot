-- Esqueleto y catalogo: niveles, perfil demo, habilidades, logros y los casos
-- de uso con sus pasos, herramientas y desafios.
--
-- A proposito NO siembra progreso del usuario (avance, actividad, logros
-- desbloqueados, XP). El perfil arranca en cero y se llena practicando.
--
-- Idempotente: se puede volver a correr sin duplicar nada. Las filas hijas
-- (pasos, opciones, herramientas) se actualizan por clave, asi que si se saca
-- un paso o una opcion de este archivo hay que borrarla a mano.

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

-- Taxonomia de habilidades. Cada caso de uso apunta a una mediante
-- use_cases.skill_id. Los valores por usuario no se siembran:
-- user_skills arranca vacia y la app trata la ausencia de fila como 0%.
insert into public.skills (id, name, color, sort_order) values
  ('comunicacion', 'Comunicación', 'violet', 1),
  ('investigacion', 'Investigación', 'blue', 2),
  ('organizacion', 'Organización', 'orange', 3),
  ('creatividad', 'Creatividad', 'pink', 4),
  ('analisis', 'Análisis', 'green', 5),
  ('automatizacion', 'Automatización', 'yellow', 6)
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

-- Categorias del filtro de Explorar.
insert into public.categories (id, name, sort_order) values
  ('administracion', 'Administración de tareas', 1),
  ('vinculacion', 'Vinculación con herramientas', 2),
  ('explicacion-ia', 'Explicación de IA', 3),
  ('diseno', 'Diseño', 4),
  ('programacion', 'Programación', 5)
on conflict (id) do update
  set name = excluded.name,
      sort_order = excluded.sort_order;

insert into public.tools (id, name, sort_order) values
  ('chatgpt', 'ChatGPT', 1),
  ('claude', 'Claude', 2),
  ('gemini', 'Gemini', 3),
  ('copilot', 'Copilot', 4),
  ('notebooklm', 'NotebookLM', 5),
  ('apps-script', 'Google Apps Script', 6),
  ('diseno', 'Herramienta de diseño', 7)
on conflict (id) do update
  set name = excluded.name,
      sort_order = excluded.sort_order;

-- Casos de uso del Sprint 2, salidos de las tareas mas pedidas en la encuesta.
-- icon es el nombre de un componente de lucide-react (ver caseIcons en App.jsx).
insert into public.use_cases (id, title, summary, situation, skill_id, difficulty, estimated_minutes, icon, color, common_mistake, learning_outcome, xp_reward, status, sort_order) values
  (
    'ventas-sin-formulas',
    'Entender mis ventas sin saber fórmulas',
    'Sacá totales por vendedor y marcá a los clientes que deben describiendo lo que querés, sin escribir fórmulas.',
    'Tenés una planilla con 600 ventas del mes y necesitás saber cuánto vendió cada vendedor, qué producto cayó y marcar los clientes que deben más de 30 días.',
    'analisis', 'Media', 20, 'Table2', 'blue',
    'Pedir "analizá este Excel" sin contexto, o copiar una fórmula con comas cuando la planilla en español exige punto y coma.',
    'Describir los datos antes de pedir, verificar siempre con un caso conocido y elegir entre la IA integrada en la planilla y un chatbot.',
    40, 'published', 1
  ),
  (
    'reporte-campania',
    'Reporte de campaña para un cliente',
    'Convertí el export de una campaña en un informe de una página que un cliente sin conocimientos técnicos entienda.',
    'Tenés un export de la campaña con impresiones, clics, gasto y conversiones, y tenés que entregarle al cliente un informe de una página con qué funcionó, qué no y qué hacer después.',
    'comunicacion', 'Media', 25, 'ChartColumn', 'orange',
    'Mezclar análisis y redacción en un solo pedido: la IA inventa conclusiones para que el texto suene redondo.',
    'Dividir una tarea grande en pasos, definir quién lee y pedir una estructura fija.',
    40, 'published', 2
  ),
  (
    'reunion-seguimiento',
    'De la reunión al seguimiento',
    'Con una sola fuente, sacá la minuta, la tabla de tareas y el mail de seguimiento al cliente.',
    'Después de una reunión de 40 minutos con un cliente hay que mandar la minuta, repartir las tareas y enviar un mail de seguimiento.',
    'organizacion', 'Media', 20, 'ClipboardList', 'violet',
    'Que la IA invente un responsable o una fecha que nadie dijo.',
    'Reutilizar el contexto del mismo chat, pedir formatos de salida y evitar que la IA rellene huecos.',
    40, 'published', 3
  ),
  (
    'estudiar-material',
    'Estudiar un material largo y armar un plan',
    'Usá una IA que trabaja con tus propios documentos para entender el material y armar un plan de estudio.',
    'Tenés que preparar un examen o una certificación con tres PDF de 40 páginas y dos semanas por delante.',
    'investigacion', 'Media', 30, 'BookOpen', 'yellow',
    'Pedir "resumime todo" en un solo mensaje, o consultar a un chatbot sin fuentes y recibir datos inventados.',
    'La diferencia entre una IA con fuentes propias y un chatbot general, y cómo estudiar con IA sin dejar de verificar.',
    40, 'published', 4
  ),
  (
    'documento-presentacion',
    'Del documento a la presentación',
    'Pasá un informe largo a diapositivas trabajando primero el contenido y después el diseño.',
    'Tenés un informe de 8 páginas y mañana hay que presentarlo en 10 minutos con diapositivas.',
    'comunicacion', 'Media', 25, 'Presentation', 'orange',
    'Pedir la presentación completa de una sola vez: sale vistosa pero con texto de más y cifras mal copiadas.',
    'Trabajar primero el contenido y después el formato, y combinar dos herramientas.',
    40, 'published', 5
  ),
  (
    'imagenes-redes',
    'Imágenes para redes que no parezcan hechas con IA',
    'Escribí un pedido visual completo y terminá la pieza en una herramienta de diseño.',
    'Necesitás 3 imágenes para promocionar un producto y el cliente rechaza lo que "se nota que es IA".',
    'creatividad', 'Media', 25, 'Image', 'pink',
    'Pedir "una imagen linda de miel" y aceptar la primera: resulta genérica y brillante en exceso.',
    'La estructura de un buen pedido visual, iterar con cambios chicos y completar con otra herramienta.',
    40, 'published', 6
  ),
  (
    'automatizar-tarea',
    'Automatizar una tarea repetitiva sin saber programar',
    'Pedile a la IA un script que haga la tarea por vos y probalo sin poner en riesgo tus datos.',
    'Cada lunes copiás datos de una planilla de pedidos a otra de control y les agregás la fecha y el estado. Querés que se haga solo.',
    'automatizacion', 'Avanzada', 40, 'Workflow', 'violet',
    'Correr el código directo sobre los datos reales, sin hacer una copia antes.',
    'Que no hace falta saber programar para pedir código, pero sí probar en una copia y pedir que te lo expliquen.',
    50, 'published', 7
  ),
  (
    'comparar-decidir',
    'Comparar opciones y decidir con información confiable',
    'Juntá datos actuales con fuentes, armá una comparación y contrastá la recomendación con una segunda IA.',
    'Tenés que elegir entre tres proveedores o tres sistemas de gestión y justificar la decisión.',
    'investigacion', 'Media', 30, 'Scale', 'blue',
    'Usar un chatbot sin búsqueda y confiar en precios o funciones desactualizados.',
    'Cuándo activar la búsqueda, cómo pedir fuentes y por qué conviene contrastar dos IA.',
    40, 'published', 8
  )
on conflict (id) do update
  set title = excluded.title,
      summary = excluded.summary,
      situation = excluded.situation,
      skill_id = excluded.skill_id,
      difficulty = excluded.difficulty,
      estimated_minutes = excluded.estimated_minutes,
      icon = excluded.icon,
      color = excluded.color,
      common_mistake = excluded.common_mistake,
      learning_outcome = excluded.learning_outcome,
      xp_reward = excluded.xp_reward,
      status = excluded.status,
      sort_order = excluded.sort_order;

insert into public.use_case_categories (use_case_id, category_id, is_primary) values
  ('ventas-sin-formulas', 'administracion', true),
  ('reporte-campania', 'administracion', true),
  ('reporte-campania', 'vinculacion', false),
  ('reunion-seguimiento', 'administracion', true),
  ('estudiar-material', 'explicacion-ia', true),
  ('documento-presentacion', 'vinculacion', true),
  ('imagenes-redes', 'diseno', true),
  ('automatizar-tarea', 'programacion', true),
  ('comparar-decidir', 'explicacion-ia', true)
on conflict (use_case_id, category_id) do update
  set is_primary = excluded.is_primary;

insert into public.use_case_tools (use_case_id, tool_id, role, reason, sort_order) values
  ('ventas-sin-formulas', 'gemini', 'primary', 'Integrado en Google Sheets, si el archivo ya está ahí.', 1),
  ('ventas-sin-formulas', 'copilot', 'primary', 'Integrado en Excel, si el archivo ya está ahí.', 2),
  ('ventas-sin-formulas', 'chatgpt', 'alternative', 'Si preferís pegar un recorte de la planilla.', 3),
  ('ventas-sin-formulas', 'claude', 'alternative', 'Si preferís pegar un recorte de la planilla.', 4),

  ('reporte-campania', 'claude', 'primary', 'Para el análisis y la redacción. La planilla queda como fuente.', 1),
  ('reporte-campania', 'chatgpt', 'primary', 'Para el análisis y la redacción. La planilla queda como fuente.', 2),

  ('reunion-seguimiento', 'gemini', 'primary', 'Si la reunión fue en Google Meet y tiene transcripción.', 1),
  ('reunion-seguimiento', 'copilot', 'primary', 'Si la reunión fue en Teams y tiene transcripción.', 2),
  ('reunion-seguimiento', 'chatgpt', 'primary', 'Si la plataforma de la reunión lo tiene integrado, o si pegás tus apuntes.', 3),
  ('reunion-seguimiento', 'claude', 'alternative', 'Si pegás tus propios apuntes.', 4),

  ('estudiar-material', 'notebooklm', 'primary', 'Responde solo con los documentos que subís y cita de dónde sale cada dato.', 1),
  ('estudiar-material', 'chatgpt', 'complement', 'Para armar el plan de estudio y las preguntas de práctica.', 2),
  ('estudiar-material', 'claude', 'complement', 'Para armar el plan de estudio y las preguntas de práctica.', 3),

  ('documento-presentacion', 'gemini', 'primary', 'Integrado en Google Slides, para armar el borrador visual.', 1),
  ('documento-presentacion', 'copilot', 'primary', 'Integrado en PowerPoint, para armar el borrador visual.', 2),
  ('documento-presentacion', 'chatgpt', 'complement', 'Para ordenar el contenido antes de pasar al diseño.', 3),
  ('documento-presentacion', 'claude', 'complement', 'Para ordenar el contenido antes de pasar al diseño.', 4),

  ('imagenes-redes', 'chatgpt', 'primary', 'Para generar las imágenes.', 1),
  ('imagenes-redes', 'gemini', 'primary', 'Para generar las imágenes.', 2),
  ('imagenes-redes', 'diseno', 'complement', 'Para agregar el texto y el logo fuera de la imagen generada.', 3),

  ('automatizar-tarea', 'claude', 'primary', 'Para escribir el script y explicarlo paso a paso.', 1),
  ('automatizar-tarea', 'chatgpt', 'primary', 'Para escribir el script y explicarlo paso a paso.', 2),
  ('automatizar-tarea', 'apps-script', 'complement', 'Para ejecutarlo dentro de Google Sheets sin instalar nada.', 3),

  ('comparar-decidir', 'chatgpt', 'primary', 'Con búsqueda web o modo de investigación activado, para juntar datos actuales.', 1),
  ('comparar-decidir', 'gemini', 'primary', 'Con búsqueda web o modo de investigación activado, para juntar datos actuales.', 2),
  ('comparar-decidir', 'claude', 'primary', 'Con búsqueda web activada. Sin búsqueda, sirve para armar la tabla y la recomendación.', 3)
on conflict (use_case_id, tool_id) do update
  set role = excluded.role,
      reason = excluded.reason,
      sort_order = excluded.sort_order;

insert into public.use_case_steps (use_case_id, position, body, example_prompt, checklist, requires_confirmation, confirmation_label) values
  ('ventas-sin-formulas', 1, 'Sacá o reemplazá los datos sensibles antes de compartir nada.', null,
    array['Nombres y apellidos de clientes', 'CUIT o DNI', 'Mails y teléfonos', 'Direcciones', 'Datos bancarios'], false, null),
  ('ventas-sin-formulas', 2, 'Copiá solo los encabezados y 10 filas de ejemplo, no las 600. Ahorra tokens y alcanza para que la IA entienda.', null, '{}', false, null),
  ('ventas-sin-formulas', 3, 'Escribí el objetivo, no la fórmula.',
    'Tengo una planilla con las columnas Fecha, Vendedor, Producto, Monto y Días de deuda. Quiero el total por vendedor y marcar en rojo los que superan 30 días. Usá Google Sheets en español.', '{}', false, null),
  ('ventas-sin-formulas', 4, 'Pedile que explique la fórmula en una línea y que te diga dónde pegarla.', null, '{}', false, null),
  ('ventas-sin-formulas', 5, 'Probala con 3 filas cuyo resultado ya conocés. Si no coincide, devolvele a la IA el error textual.', null, '{}', false, null),
  ('ventas-sin-formulas', 6, 'Hacé un segundo pedido para sacar conclusiones.', 'Dame 3 hallazgos y un gráfico recomendado.', '{}', false, null),

  ('reporte-campania', 1, 'Exportá la campaña a CSV o planilla y borrá las columnas que no hacen falta.', null, '{}', false, null),
  ('reporte-campania', 2, 'Pedí primero el análisis, sin redactar todavía.',
    'Sos analista de marketing. Con estos datos, calculá el costo por conversión de cada anuncio y decime los 3 mejores y los 3 peores.', '{}', false, null),
  ('reporte-campania', 3, 'Revisá los números contra la planilla haciendo dos o tres cálculos a mano.', null, '{}', false, null),
  ('reporte-campania', 4, 'Definí quién lee el informe.', 'El lector es el dueño de una pyme, no sabe qué es CTR. Explicá sin siglas.', '{}', false, null),
  ('reporte-campania', 5, 'Pedí una estructura fija: resumen en 3 líneas, qué funcionó, qué no y 3 acciones para el mes que viene.', null, '{}', false, null),
  ('reporte-campania', 6, 'Pedí una tabla resumen para pegar en el documento de control.', null, '{}', false, null),
  ('reporte-campania', 7, 'Ajustá el tono y exportá a Word o PDF.', null, '{}', false, null),

  ('reunion-seguimiento', 1, 'Reuní la fuente: la transcripción automática o tus propios apuntes. Si la reunión se grabó, avisá a los participantes.', null, '{}', false, null),
  ('reunion-seguimiento', 2, 'Quitá los datos que no hacen falta, como precios internos o datos personales.', null, '{}', false, null),
  ('reunion-seguimiento', 3, 'Pedí la minuta con un formato fijo y aclarale que no invente.',
    'Armá una minuta con fecha, asistentes, decisiones tomadas, tareas (quién, qué, para cuándo) y temas pendientes. No inventes: si falta un dato, escribí A CONFIRMAR.', '{}', false, null),
  ('reunion-seguimiento', 4, 'Verificá que cada tarea tenga responsable y fecha. Las que no tengan, marcalas como "a confirmar".', null, '{}', false, null),
  ('reunion-seguimiento', 5, 'En el mismo chat, pedí el mail de seguimiento.',
    'Con esa minuta, redactá un mail al cliente confirmando lo acordado, en tono cordial, de 120 palabras.', '{}', false, null),
  ('reunion-seguimiento', 6, 'Pedí las tareas en una tabla para pegar en la planilla de seguimiento.', null, '{}', false, null),
  ('reunion-seguimiento', 7, 'Leé todo antes de enviar.', null, '{}', false, null),

  ('estudiar-material', 1, 'Subí los PDF como fuentes en NotebookLM, en vez de pegar texto suelto.', null, '{}', false, null),
  ('estudiar-material', 2, 'Pedí un mapa del material.', 'Dame los 8 temas principales de este material, ordenados de lo básico a lo complejo.', '{}', false, null),
  ('estudiar-material', 3, 'Pedí los resúmenes de a un tema por vez.', 'Explicame este tema como si no supiera nada, con un ejemplo.', '{}', false, null),
  ('estudiar-material', 4, 'Pedí 10 preguntas de práctica y respondelas sin mirar.', null, '{}', false, null),
  ('estudiar-material', 5, 'Pasale la lista de temas y la fecha del examen a un chatbot para armar el plan.',
    'Tengo 14 días y 1 hora por día. Armá un plan de estudio día por día con repaso.', '{}', false, null),
  ('estudiar-material', 6, 'Controlá al menos una respuesta en la fuente original usando la cita.', null, '{}', false, null),

  ('documento-presentacion', 1, 'Definí la audiencia y el tiempo: por ejemplo, 10 minutos frente a directivos que tienen que aprobar un presupuesto.', null, '{}', false, null),
  ('documento-presentacion', 2, 'Pedí primero el esquema en texto.',
    'Convertí este informe en 8 diapositivas: título, 3 ideas máximo por diapositiva y una frase de cierre.', '{}', false, null),
  ('documento-presentacion', 3, 'Corregí el esquema (sacá, juntá, reordená) antes de tocar el diseño.', null, '{}', false, null),
  ('documento-presentacion', 4, 'Llevá el esquema ajustado al asistente de Google Slides o PowerPoint y pedile el diseño.', null, '{}', false, null),
  ('documento-presentacion', 5, 'Pedí notas del orador para cada diapositiva.', null, '{}', false, null),
  ('documento-presentacion', 6, 'Revisá cifras y nombres contra el informe original.', null, '{}', false, null),

  ('imagenes-redes', 1, 'Definí el uso: formato (cuadrado o vertical), dónde se publica y qué tiene que transmitir.', null, '{}', false, null),
  ('imagenes-redes', 2, 'Escribí el pedido con seis datos: sujeto, escenario, luz, estilo fotográfico, colores de la marca y qué evitar.',
    'Foto de producto de un frasco de miel sobre una mesa de madera, luz natural de mañana, estilo fotografía de revista, sin texto ni personas.', '{}', false, null),
  ('imagenes-redes', 3, 'Si la herramienta lo permite, subí una foto real del producto o una de referencia.', null, '{}', false, null),
  ('imagenes-redes', 4, 'Pedí tres variantes y elegí una. Después cambiá de a una cosa por vez.', null, '{}', false, null),
  ('imagenes-redes', 5, 'Revisá manos, texto y detalles raros: es lo que delata a la IA.', null, '{}', false, null),
  ('imagenes-redes', 6, 'Agregá el texto y el logo en una herramienta de diseño, no dentro de la imagen generada.', null, '{}', false, null),

  ('automatizar-tarea', 1, 'Describí la tarea como se la explicarías a un compañero nuevo: qué planilla, qué columnas, qué se copia, a dónde y cuándo.', null, '{}', false, null),
  ('automatizar-tarea', 2, 'Pedí el script aclarando que no sabés programar.',
    'No sé programar. Escribí un script de Google Apps Script que haga esto y explicame dónde pegarlo, paso a paso.', '{}', false, null),
  ('automatizar-tarea', 3, 'Hacé una copia de la planilla y probá ahí, nunca en el archivo real.', null, '{}', true,
    'Hice una copia de la planilla y voy a probar ahí'),
  ('automatizar-tarea', 4, 'Si aparece un error, copialo completo y pegalo en el mismo chat.', null, '{}', false, null),
  ('automatizar-tarea', 5, 'Pedile a la IA que explique en tres líneas qué hace el script, para saber qué estás autorizando.', null, '{}', false, null),
  ('automatizar-tarea', 6, 'Pedí que se ejecute solo los lunes con un disparador de tiempo y comprobá la primera ejecución.', null, '{}', false, null),

  ('comparar-decidir', 1, 'Escribí qué decisión tenés que tomar y con qué criterios: precio, soporte, facilidad, integraciones.', null, '{}', false, null),
  ('comparar-decidir', 2, 'Activá la búsqueda web y pedí datos actuales con enlaces.', 'Compará estas tres opciones. Citá la fuente de cada dato.', '{}', false, null),
  ('comparar-decidir', 3, 'Abrí al menos dos de los enlaces y comprobá que el dato está.', null, '{}', false, null),
  ('comparar-decidir', 4, 'Pedí una tabla comparativa con los criterios del paso 1.', null, '{}', false, null),
  ('comparar-decidir', 5, 'Pedí una recomendación con riesgos.', 'Recomendá una y decime qué podría salir mal.', '{}', false, null),
  ('comparar-decidir', 6, 'Hacé el mismo pedido en una segunda IA y compará. Si difieren, investigá ese punto.', null, '{}', false, null)
on conflict (use_case_id, position) do update
  set body = excluded.body,
      example_prompt = excluded.example_prompt,
      checklist = excluded.checklist,
      requires_confirmation = excluded.requires_confirmation,
      confirmation_label = excluded.confirmation_label;

-- Tareas de la encuesta (319 respuestas) que cubre cada caso, con sus menciones.
insert into public.use_case_survey_tasks (use_case_id, position, task, mentions) values
  ('ventas-sin-formulas', 1, 'Analizar datos de Excel', 8),
  ('ventas-sin-formulas', 2, 'Crear fórmulas y automatizaciones', 6),
  ('ventas-sin-formulas', 3, 'Análisis contables básicos', 3),
  ('reporte-campania', 1, 'Analizar campañas', 6),
  ('reporte-campania', 2, 'Armar reportes', 3),
  ('reporte-campania', 3, 'Bajar información a documentos de control', null),
  ('reunion-seguimiento', 1, 'Preparar reuniones y minutas', 6),
  ('reunion-seguimiento', 2, 'Seguimiento de clientes', 3),
  ('reunion-seguimiento', 3, 'Redactar mails', 3),
  ('estudiar-material', 1, 'Investigar y resumir material', 11),
  ('estudiar-material', 2, 'Plan de estudio', 7),
  ('documento-presentacion', 1, 'Crear presentaciones a partir de información', 3),
  ('documento-presentacion', 2, 'Documentos más profesionales', 4),
  ('imagenes-redes', 1, 'Planificar contenido para redes', 5),
  ('imagenes-redes', 2, 'Mejores imágenes', 2),
  ('imagenes-redes', 3, 'Imágenes que no parezcan "demasiado IA"', null),
  ('automatizar-tarea', 1, 'Automatizar tareas repetitivas', 5),
  ('automatizar-tarea', 2, 'Programar sin saber código', 2),
  ('automatizar-tarea', 3, 'Carga de datos', 2),
  ('comparar-decidir', 1, 'Comparar información y decidir', 5),
  ('comparar-decidir', 2, 'Buscar información confiable', 2)
on conflict (use_case_id, position) do update
  set task = excluded.task,
      mentions = excluded.mentions;

-- Cada desafio pone al error tipico del caso como opcion incorrecta.
insert into public.use_case_challenges (use_case_id, title, scenario, question) values
  ('ventas-sin-formulas', 'Pedir una fórmula que funcione',
    'Tenés una planilla de Google Sheets en español con 600 ventas y querés el total por vendedor. Ya sacaste los datos sensibles.',
    '¿Qué pedido le harías a la IA?'),
  ('reporte-campania', 'Analizar antes de redactar',
    'Tenés el export de la campaña y el cliente, dueño de una pyme, espera un informe de una página.',
    '¿Cuál es el mejor primer pedido?'),
  ('reunion-seguimiento', 'Que la IA no invente datos',
    'Pegaste la transcripción de una reunión de 40 minutos. Algunas tareas se mencionaron sin responsable ni fecha.',
    '¿Qué pedido evita que la minuta tenga datos inventados?'),
  ('estudiar-material', 'Estudiar con fuentes',
    'Tenés tres PDF de 40 páginas y dos semanas para preparar un examen.',
    '¿Cuál es la mejor forma de empezar?'),
  ('documento-presentacion', 'Contenido primero, diseño después',
    'Tenés un informe de 8 páginas y mañana lo presentás en 10 minutos a directivos que tienen que aprobar un presupuesto.',
    '¿Qué pedido harías primero?'),
  ('imagenes-redes', 'Un pedido visual completo',
    'Necesitás una imagen cuadrada para Instagram de un frasco de miel artesanal, y al cliente no le gusta lo que "se nota que es IA".',
    '¿Qué pedido da un resultado más creíble?'),
  ('automatizar-tarea', 'Probar sin riesgo',
    'La IA te dio un script de Google Apps Script que copia los pedidos a la planilla de control cada lunes.',
    '¿Qué hacés antes de ejecutarlo?'),
  ('comparar-decidir', 'Datos actuales y verificables',
    'Tenés que elegir entre tres sistemas de gestión y justificar la decisión con precio, soporte e integraciones.',
    '¿Cómo arrancás?')
on conflict (use_case_id) do update
  set title = excluded.title,
      scenario = excluded.scenario,
      question = excluded.question;

insert into public.challenge_options (use_case_id, letter, body, is_correct, feedback) values
  ('ventas-sin-formulas', 'a', 'Analizá este Excel. [Y pegás las 600 filas]', false,
    'Sin contexto la IA tiene que adivinar qué querés, y pegar las 600 filas gasta tokens sin necesidad. Con los encabezados y 10 filas de ejemplo alcanza.'),
  ('ventas-sin-formulas', 'b', 'Tengo una planilla con las columnas Fecha, Vendedor, Producto, Monto y Días de deuda (te paso 10 filas de ejemplo). Quiero el total por vendedor. Uso Google Sheets en español: dame la fórmula, explicámela en una línea y decime dónde pegarla.', true,
    'Describe los datos, plantea el objetivo en vez de la fórmula y aclara que la planilla está en español, así la IA usa punto y coma como separador. Después probala con 3 filas cuyo resultado ya conocés.'),
  ('ventas-sin-formulas', 'c', 'Dame la fórmula SUMAR.SI para sumar por vendedor.', false,
    'Pedís la fórmula en vez del objetivo y no decís que la planilla está en español: es probable que venga con comas como separador y Sheets te dé error. Contá qué querés lograr y en qué idioma está la planilla.'),

  ('reporte-campania', 'a', 'Sos analista de marketing. Con estos datos, calculá el costo por conversión de cada anuncio y decime los 3 mejores y los 3 peores. Todavía no redactes el informe.', true,
    'Separa el análisis de la redacción. Primero tenés números que podés verificar contra la planilla, y recién después pedís el texto para un lector que no sabe qué es CTR.'),
  ('reporte-campania', 'b', 'Con estos datos, escribí el informe para el cliente con qué funcionó, qué no y qué hacer el mes que viene.', false,
    'Mezcla análisis y redacción en un solo pedido. Para que el texto suene redondo, la IA puede inventar conclusiones que los datos no sostienen. Pedí primero los números y verificalos.'),
  ('reporte-campania', 'c', 'Hacé un informe profesional de la campaña, con mucho detalle y gráficos.', false,
    'No dice quién lo lee ni qué estructura necesita, y también mezcla análisis con redacción. "Profesional" y "con detalle" no le dan a la IA nada concreto.'),

  ('reunion-seguimiento', 'a', 'Resumime la reunión.', false,
    'Sin un formato fijo vas a recibir un resumen corrido, y la IA puede completar responsables o fechas que nadie dijo.'),
  ('reunion-seguimiento', 'b', 'Armá una minuta completa, con todas las tareas asignadas a alguien y con su fecha.', false,
    'Exigir que todas las tareas tengan responsable y fecha empuja a la IA a rellenar los huecos con datos inventados.'),
  ('reunion-seguimiento', 'c', 'Armá una minuta con fecha, asistentes, decisiones, tareas (quién, qué, para cuándo) y temas pendientes. No inventes: si falta un dato, escribí A CONFIRMAR.', true,
    'Da un formato fijo y le dice qué hacer con los datos que faltan. Lo que nadie dijo queda marcado como A CONFIRMAR en vez de aparecer como un dato inventado.'),

  ('estudiar-material', 'a', 'Pegar los tres PDF en un chatbot y pedir "resumime todo".', false,
    'Un solo pedido gigante da un resumen superficial y te deja sin forma de verificar de dónde sale cada dato.'),
  ('estudiar-material', 'b', 'Subir los PDF como fuentes en NotebookLM y pedir los 8 temas principales, ordenados de lo básico a lo complejo.', true,
    'NotebookLM responde solo con tus documentos y cita de dónde sale cada dato. Empezar por el mapa de temas te deja estudiar de a un tema y después armar el plan.'),
  ('estudiar-material', 'c', 'Preguntarle a un chatbot, sin subir nada, qué temas entran en el examen.', false,
    'Sin fuentes, el chatbot responde con lo que cree saber y puede inventar temas o datos. Para estudiar un material concreto, la IA tiene que trabajar sobre ese material.'),

  ('documento-presentacion', 'a', 'Hacé una presentación completa y linda con este informe.', false,
    'Pedir todo junto da diapositivas vistosas pero con texto de más y cifras mal copiadas. Primero trabajá el contenido.'),
  ('documento-presentacion', 'b', 'Diseñá 20 diapositivas con todo el contenido del informe para no dejar nada afuera.', false,
    'Veinte diapositivas para 10 minutos es demasiado, y querer meter todo es justo lo que hay que evitar.'),
  ('documento-presentacion', 'c', 'Convertí este informe en un esquema de 8 diapositivas para directivos que tienen que aprobar un presupuesto en 10 minutos: título, 3 ideas máximo por diapositiva y una frase de cierre.', true,
    'Define audiencia, tiempo y límites, y pide un esquema en texto que podés corregir antes de pasar al diseño en Slides o PowerPoint.'),

  ('imagenes-redes', 'a', 'Foto de producto de un frasco de miel sobre una mesa de madera, luz natural de mañana, estilo fotografía de revista, tonos dorados y cálidos, formato cuadrado, sin texto ni personas.', true,
    'Incluye los seis datos: sujeto, escenario, luz, estilo fotográfico, colores y qué evitar. El texto y el logo los agregás después en una herramienta de diseño.'),
  ('imagenes-redes', 'b', 'Una imagen linda de miel.', false,
    'Sin datos concretos la IA elige por vos y el resultado sale genérico y brillante de más: el típico "se nota que es IA".'),
  ('imagenes-redes', 'c', 'Imagen de un frasco de miel con el logo de la marca y el texto "50% OFF" en letras doradas.', false,
    'Pedirle a la IA que escriba texto o ponga el logo dentro de la imagen suele dar letras deformes. Generá la imagen sin texto y agregalo en una herramienta de diseño.'),

  ('automatizar-tarea', 'a', 'Lo pego en la planilla real y lo ejecuto: si falla, le pido a la IA que lo arregle.', false,
    'Si el script tiene un error puede borrar o pisar datos reales, y no siempre se puede volver atrás. Probalo siempre en una copia.'),
  ('automatizar-tarea', 'b', 'Hago una copia de la planilla, lo pruebo ahí y le pido a la IA que me explique en tres líneas qué hace.', true,
    'Probar en una copia protege los datos reales, y la explicación te dice qué estás autorizando cuando Google te pide permisos.'),
  ('automatizar-tarea', 'c', 'Lo programo directamente con el disparador de los lunes para ver si anda.', false,
    'Programar el disparador sin probar antes es correr el código sobre los datos reales sin mirar. Primero probalo a mano en una copia.'),

  ('comparar-decidir', 'a', 'Le pregunto a un chatbot sin búsqueda cuál es el mejor de los tres y uso esa respuesta.', false,
    'Sin búsqueda web el chatbot puede darte precios o funciones desactualizados, y "el mejor" no dice con qué criterios.'),
  ('comparar-decidir', 'b', 'Activo la búsqueda y pido: "Decime cuál conviene".', false,
    'La búsqueda ayuda, pero sin criterios ni fuentes no podés comprobar ni justificar la recomendación.'),
  ('comparar-decidir', 'c', 'Activo la búsqueda web y pido: "Compará estas tres opciones por precio, soporte, facilidad e integraciones. Citá la fuente de cada dato".', true,
    'Con la búsqueda activada los datos son actuales, los criterios están claros y cada dato trae su fuente para que abras los enlaces y lo compruebes. Después podés contrastar con una segunda IA.')
on conflict (use_case_id, letter) do update
  set body = excluded.body,
      is_correct = excluded.is_correct,
      feedback = excluded.feedback;
