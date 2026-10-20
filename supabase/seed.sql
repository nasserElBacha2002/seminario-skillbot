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

-- Categorías por necesidad. Un caso puede tener más de una.
insert into public.categories (id, name, sort_order) values
  ('presentaciones', 'Presentaciones', 1),
  ('datos', 'Datos y análisis', 2),
  ('estudio', 'Estudio', 3),
  ('organizacion', 'Organización y productividad', 4),
  ('contenido', 'Contenido y redacción', 5),
  ('automatizacion', 'Automatización', 6)
on conflict (id) do update
  set name = excluded.name,
      sort_order = excluded.sort_order;

insert into public.tools (id, name, sort_order, url) values
  ('chatgpt', 'ChatGPT', 1, 'https://chatgpt.com/'),
  ('claude', 'Claude', 2, 'https://claude.ai/new'),
  ('gemini', 'Gemini', 3, 'https://gemini.google.com/app'),
  ('copilot', 'Copilot', 4, 'https://copilot.microsoft.com/'),
  ('notebooklm', 'NotebookLM', 5, 'https://notebooklm.google.com/'),
  ('apps-script', 'Google Apps Script', 6, 'https://script.google.com/home'),
  ('diseno', 'Canva', 7, 'https://www.canva.com/')
on conflict (id) do update
  set name = excluded.name,
      sort_order = excluded.sort_order,
      url = excluded.url;

-- Casos de uso del Sprint 2, salidos de las tareas mas pedidas en la encuesta.
-- icon es el nombre de un componente de lucide-react (ver caseIcons en src/components/icons.js).
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

delete from public.use_case_categories
where use_case_id in (
  'ventas-sin-formulas',
  'reporte-campania',
  'reunion-seguimiento',
  'estudiar-material',
  'documento-presentacion',
  'imagenes-redes',
  'automatizar-tarea',
  'comparar-decidir'
);

insert into public.use_case_categories (use_case_id, category_id, is_primary) values
  ('ventas-sin-formulas', 'datos', true),
  ('reporte-campania', 'contenido', true),
  ('reporte-campania', 'datos', false),
  ('reunion-seguimiento', 'organizacion', true),
  ('estudiar-material', 'estudio', true),
  ('documento-presentacion', 'presentaciones', true),
  ('imagenes-redes', 'contenido', true),
  ('automatizar-tarea', 'automatizacion', true),
  ('comparar-decidir', 'datos', true)
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

  ('documento-presentacion', 'chatgpt', 'primary', 'Para pegar el pedido y armar primero el esquema de la presentación.', 1),
  ('documento-presentacion', 'claude', 'primary', 'Para pegar el pedido y armar primero el esquema de la presentación.', 2),
  ('documento-presentacion', 'gemini', 'complement', 'Después, para pasar el esquema a diapositivas en Google Slides.', 3),
  ('documento-presentacion', 'copilot', 'complement', 'Después, para pasar el esquema a diapositivas en PowerPoint.', 4),

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
  ('ventas-sin-formulas', 2, 'Copiá solo los encabezados y 10 filas de ejemplo, no las 600. Ahorra tokens y alcanza para que la IA entienda.', null, array['Solo encabezados','Hasta 10 filas de ejemplo','Sin datos sensibles'], false, null),
  ('ventas-sin-formulas', 3, 'Escribí el objetivo, no la fórmula.',
    'Tengo una planilla con las columnas Fecha, Vendedor, Producto, Monto y Días de deuda. Quiero el total por vendedor y marcar en rojo los que superan 30 días. Usá Google Sheets en español.', array['Objetivo en castellano','Columnas nombradas','Herramienta (Sheets o Excel)'], false, null),
  ('ventas-sin-formulas', 4, 'Pedile que explique la fórmula en una línea y que te diga dónde pegarla.', null, array['Explicación en una línea','Dónde pegar la fórmula'], false, null),
  ('ventas-sin-formulas', 5, 'Probala con 3 filas cuyo resultado ya conocés. Si no coincide, devolvele a la IA el error textual.', null, array['3 filas cuyo resultado ya conocés','Si no coincide, devolvê el error textual'], false, null),
  ('ventas-sin-formulas', 6, 'Hacé un segundo pedido para sacar conclusiones.', 'Dame 3 hallazgos y un gráfico recomendado.', array['3 hallazgos','Un gráfico recomendado'], false, null),

  ('reporte-campania', 1, 'Exportá la campaña a CSV o planilla y borrá las columnas que no hacen falta.', null, array['CSV o planilla exportada','Columnas que no hacen falta, afuera'], false, null),
  ('reporte-campania', 2, 'Pedí primero el análisis, sin redactar todavía.',
    'Sos analista de marketing. Con estos datos, calculá el costo por conversión de cada anuncio y decime los 3 mejores y los 3 peores.', array['Pedí análisis, no el texto final','Costo por conversión de cada anuncio'], false, null),
  ('reporte-campania', 3, 'Revisá los números contra la planilla haciendo dos o tres cálculos a mano.', null, array['2 o 3 cuentas a mano','Compará contra la planilla'], false, null),
  ('reporte-campania', 4, 'Definí quién lee el informe.', 'El lector es el dueño de una pyme, no sabe qué es CTR. Explicá sin siglas.', array['Quién lee el informe','Sin siglas si no las conoce'], false, null),
  ('reporte-campania', 5, 'Pedí una estructura fija: resumen en 3 líneas, qué funcionó, qué no y 3 acciones para el mes que viene.', null, array['Resumen en 3 líneas','Qué funcionó y qué no','3 acciones para el mes que viene'], false, null),
  ('reporte-campania', 6, 'Pedí una tabla resumen para pegar en el documento de control.', null, array['Tabla para pegar en el control'], false, null),
  ('reporte-campania', 7, 'Ajustá el tono y exportá a Word o PDF.', null, array['Tono del lector','Exportar a Word o PDF'], false, null),

  ('reunion-seguimiento', 1, 'Reuní la fuente: la transcripción automática o tus propios apuntes. Si la reunión se grabó, avisá a los participantes.', null, array['Una sola fuente','Si hay grabación, avisá a los participantes'], false, null),
  ('reunion-seguimiento', 2, 'Quitá los datos que no hacen falta, como precios internos o datos personales.', null, array['Precios internos afuera','Datos personales afuera'], false, null),
  ('reunion-seguimiento', 3, 'Pedí la minuta con un formato fijo y aclarale que no invente.',
    'Armá una minuta con fecha, asistentes, decisiones tomadas, tareas (quién, qué, para cuándo) y temas pendientes. No inventes: si falta un dato, escribí A CONFIRMAR.', array['Decisiones','Tareas con quién y para cuándo','Si falta un dato: A CONFIRMAR'], false, null),
  ('reunion-seguimiento', 4, 'Verificá que cada tarea tenga responsable y fecha. Las que no tengan, marcalas como "a confirmar".', null, array['Cada tarea con responsable','Cada tarea con fecha'], false, null),
  ('reunion-seguimiento', 5, 'En el mismo chat, pedí el mail de seguimiento.',
    'Con esa minuta, redactá un mail al cliente confirmando lo acordado, en tono cordial, de 120 palabras.', array['Mail cordial','Alrededor de 120 palabras'], false, null),
  ('reunion-seguimiento', 6, 'Pedí las tareas en una tabla para pegar en la planilla de seguimiento.', null, array['Tabla lista para la planilla de seguimiento'], false, null),
  ('reunion-seguimiento', 7, 'Leé todo antes de enviar.', null, array['Leé todo antes de enviar'], false, null),

  ('estudiar-material', 1, 'Subí los PDF como fuentes en NotebookLM, en vez de pegar texto suelto.', null, array['PDF como fuente','No pegues texto suelto'], false, null),
  ('estudiar-material', 2, 'Pedí un mapa del material.', 'Dame los 8 temas principales de este material, ordenados de lo básico a lo complejo.', array['8 temas principales','De lo básico a lo complejo'], false, null),
  ('estudiar-material', 3, 'Pedí los resúmenes de a un tema por vez.', 'Explicame este tema como si no supiera nada, con un ejemplo.', array['Un tema por vez','Un ejemplo concreto'], false, null),
  ('estudiar-material', 4, 'Pedí 10 preguntas de práctica y respondelas sin mirar.', null, array['10 preguntas','Respondelas sin mirar'], false, null),
  ('estudiar-material', 5, 'Pasale la lista de temas y la fecha del examen a un chatbot para armar el plan.',
    'Tengo 14 días y 1 hora por día. Armá un plan de estudio día por día con repaso.', array['Plazo del examen','Horas por día','Repaso incluido'], false, null),
  ('estudiar-material', 6, 'Controlá al menos una respuesta en la fuente original usando la cita.', null, array['Al menos una cita contra la fuente'], false, null),

  ('documento-presentacion', 1, 'Definí la audiencia y el tiempo: por ejemplo, 10 minutos frente a directivos que tienen que aprobar un presupuesto.', null, array['Quién escucha','Cuántos minutos hay'], false, null),
  ('documento-presentacion', 2, 'Pedí primero el esquema en texto.',
    'Convertí este informe en 8 diapositivas: título, 3 ideas máximo por diapositiva y una frase de cierre.', array['Esquema en texto','Máximo 3 ideas por diapositiva'], false, null),
  ('documento-presentacion', 3, 'Corregí el esquema (sacá, juntá, reordená) antes de tocar el diseño.', null, array['Sacá, juntá o reordená','Todavía no diseñes'], false, null),
  ('documento-presentacion', 4, 'Llevá el esquema ajustado al asistente de Google Slides o PowerPoint y pedile el diseño.', null, array['Usá el esquema ya corregido'], false, null),
  ('documento-presentacion', 5, 'Pedí notas del orador para cada diapositiva.', null, array['Notas del orador por diapositiva'], false, null),
  ('documento-presentacion', 6, 'Revisá cifras y nombres contra el informe original.', null, array['Cifras contra el informe','Nombres contra el informe'], false, null),

  ('imagenes-redes', 1, 'Definí el uso: formato (cuadrado o vertical), dónde se publica y qué tiene que transmitir.', null, array['Formato (cuadrado o vertical)','Dónde se publica','Qué tiene que transmitir'], false, null),
  ('imagenes-redes', 2, 'Escribí el pedido con seis datos: sujeto, escenario, luz, estilo fotográfico, colores de la marca y qué evitar.',
    'Foto de producto de un frasco de miel sobre una mesa de madera, luz natural de mañana, estilo fotografía de revista, sin texto ni personas.', array['Sujeto','Escenario y luz','Estilo y colores','Qué evitar'], false, null),
  ('imagenes-redes', 3, 'Si la herramienta lo permite, subí una foto real del producto o una de referencia.', null, array['Foto real del producto o una referencia'], false, null),
  ('imagenes-redes', 4, 'Pedí tres variantes y elegí una. Después cambiá de a una cosa por vez.', null, array['Tres variantes','Cambiá una sola cosa por vez'], false, null),
  ('imagenes-redes', 5, 'Revisá manos, texto y detalles raros: es lo que delata a la IA.', null, array['Manos','Texto raro','Detalles que delatan a la IA'], false, null),
  ('imagenes-redes', 6, 'Agregá el texto y el logo en una herramienta de diseño, no dentro de la imagen generada.', null, array['Texto y logo en la herramienta de diseño'], false, null),

  ('automatizar-tarea', 1, 'Describí la tarea como se la explicarías a un compañero nuevo: qué planilla, qué columnas, qué se copia, a dónde y cuándo.', null, array['Qué planilla','Qué se copia','A dónde y cuándo'], false, null),
  ('automatizar-tarea', 2, 'Pedí el script aclarando que no sabés programar.',
    'No sé programar. Escribí un script de Google Apps Script que haga esto y explicame dónde pegarlo, paso a paso.', array['Aclará que no sabés programar','Pedí dónde pegarlo, paso a paso'], false, null),
  ('automatizar-tarea', 3, 'Hacé una copia de la planilla y probá ahí, nunca en el archivo real.', null, array['Copia de la planilla','Nunca el archivo real'], true,
    'Hice una copia de la planilla y voy a probar ahí'),
  ('automatizar-tarea', 4, 'Si aparece un error, copialo completo y pegalo en el mismo chat.', null, array['Error completo, sin recortar'], false, null),
  ('automatizar-tarea', 5, 'Pedile a la IA que explique en tres líneas qué hace el script, para saber qué estás autorizando.', null, array['Qué hace el script en 3 líneas','Qué permisos pide'], false, null),
  ('automatizar-tarea', 6, 'Pedí que se ejecute solo los lunes con un disparador de tiempo y comprobá la primera ejecución.', null, array['Disparador de tiempo','Comprobá la primera ejecución'], false, null),

  ('comparar-decidir', 1, 'Escribí qué decisión tenés que tomar y con qué criterios: precio, soporte, facilidad, integraciones.', null, array['Qué decisión','Criterios: precio, soporte, facilidad, integraciones'], false, null),
  ('comparar-decidir', 2, 'Activá la búsqueda web y pedí datos actuales con enlaces.', 'Compará estas tres opciones. Citá la fuente de cada dato.', array['Búsqueda web activada','Fuente de cada dato'], false, null),
  ('comparar-decidir', 3, 'Abrí al menos dos de los enlaces y comprobá que el dato está.', null, array['Abrí al menos dos enlaces','Comprobá que el dato esté'], false, null),
  ('comparar-decidir', 4, 'Pedí una tabla comparativa con los criterios del paso 1.', null, array['Misma tabla, mismos criterios del paso 1'], false, null),
  ('comparar-decidir', 5, 'Pedí una recomendación con riesgos.', 'Recomendá una y decime qué podría salir mal.', array['Una recomendación','Qué podría salir mal'], false, null),
  ('comparar-decidir', 6, 'Hacé el mismo pedido en una segunda IA y compará. Si difieren, investigá ese punto.', null, array['Segunda IA','Si difieren, investigá ese punto'], false, null)
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

-- Práctica: tres desafíos por caso. Reemplaza el desafío único anterior.
insert into public.use_case_challenges (
  use_case_id, position, type, title, instruction, scenario, question, feedback_correct, feedback_incorrect, xp
) values
  ('ventas-sin-formulas', 1, 'detect_error', 'Detectá el error', 'Mirá este pedido y encontrá qué lo hace difícil de responder.', 'Analizá este Excel y decime quién debe.', '¿Cuál es el principal problema de este pedido?', 'Bien. El pedido explica la intención, pero no aclara qué datos existen ni qué significa “debe”.', 'No exactamente. El problema principal es que falta contexto para que la IA pueda interpretar la planilla.', 10),
  ('ventas-sin-formulas', 2, 'missing_information', 'Qué información falta', 'Este pedido ya tiene algo de contexto, pero todavía no se puede resolver bien.', 'Tengo una planilla de ventas con columnas Cliente y Monto. Quiero saber quién debe.', '¿Qué información importante falta?', 'Exacto. Sin una regla clara, la IA no sabe cómo decidir qué cliente está en deuda.', 'No es eso. Lo que falta es una regla para decidir la deuda, por ejemplo más de 30 días.', 10),
  ('ventas-sin-formulas', 3, 'judge_result', 'Juzgá el resultado', 'Leíste el pedido y la respuesta. No alcanza con que suene convincente.', 'Pedido: Identificá clientes con más de 30 días de deuda.

Respuesta de la IA: Juan Pérez debe $150.000 y María Gómez $90.000.', '¿Qué problema tiene este resultado?', 'Bien. Una respuesta puede sonar convincente y aun así contener información inventada. Siempre hay que verificarla contra la fuente original.', 'No exactamente. Esos nombres y montos no estaban en los datos. La IA los inventó, aunque suene segura.', 10),
  ('reporte-campania', 1, 'detect_error', 'Detectá el error', 'Este pedido pide el informe de una sola vez.', 'Hacé un informe profesional de la campaña, con mucho detalle.', '¿Cuál es el principal problema de este pedido?', 'Bien. No dice quién lo lee ni pide primero los números. Para que el texto suene redondo, la IA puede inventar conclusiones.', 'No exactamente. El problema es que mezcla todo y no define al lector ni qué hay que verificar.', 10),
  ('reporte-campania', 2, 'missing_information', 'Qué información falta', 'Ya hay datos, pero el pedido sigue incompleto.', 'Con estos números de impresiones, clics y gasto, escribí el informe de la campaña.', '¿Qué información importante falta?', 'Exacto. Sin saber quién decide y qué tiene que poder hacer después de leer, el informe queda genérico.', 'No es el tono. Falta decir quién lee y qué decisión tiene que tomar.', 10),
  ('reporte-campania', 3, 'judge_result', 'Juzgá el resultado', 'Compará el pedido con lo que respondió la IA.', 'Pedido: Calculá el costo por conversión y listá los 3 mejores y los 3 peores anuncios. No redactes conclusiones todavía.

Respuesta de la IA: La campaña fue un éxito y conviene duplicar el presupuesto del anuncio principal.', '¿Qué problema tiene este resultado?', 'Bien. No mostró los números pedidos y cerró con una conclusión que los datos todavía no sostienen.', 'No es la longitud. El problema es que ignoró el pedido y sacó una conclusión sin mostrar las cifras.', 10),
  ('reunion-seguimiento', 1, 'detect_error', 'Detectá el error', 'Este pedido es el típico resumen suelto.', 'Resumime la reunión.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin un formato, la IA completa responsables o fechas que nadie dijo.', 'No exactamente. El problema es que no fija qué hay que extraer ni qué hacer cuando falta un dato.', 10),
  ('reunion-seguimiento', 2, 'missing_information', 'Qué información falta', 'El pedido ya pide una minuta, pero empuja a inventar.', 'Armá una minuta con todas las tareas asignadas a alguien y con su fecha.', '¿Qué información importante falta?', 'Exacto. Hay que decir qué hacer cuando nadie nombró al responsable o la fecha: marcarlo, no inventarlo.', 'No es la extensión. Falta la regla para los datos que la reunión no dijo.', 10),
  ('reunion-seguimiento', 3, 'judge_result', 'Juzgá el resultado', 'En la reunión no se nombró al responsable de la propuesta.', 'Pedido: Armá las tareas. Si falta un responsable o una fecha, escribí A CONFIRMAR.

Respuesta de la IA: Ana envía la propuesta el viernes 18.', '¿Qué problema tiene este resultado?', 'Bien. La IA inventó un responsable y una fecha que nadie dijo. Había que dejar A CONFIRMAR.', 'No está bien usarla así. Ese responsable y esa fecha no salieron de la reunión.', 10),
  ('estudiar-material', 1, 'detect_error', 'Detectá el error', 'Este es el pedido más común y el menos útil.', 'Resumime todo.', '¿Cuál es el principal problema de este pedido?', 'Bien. Un pedido gigante, sin fuentes ni orden, da un resumen que no podés verificar.', 'No exactamente. El problema es que no apoya la respuesta en tu material ni pide un recorrido para estudiar.', 10),
  ('estudiar-material', 2, 'missing_information', 'Qué información falta', 'Ya mencionás los PDF, pero la IA todavía no puede armar un plan.', 'Resumí estos tres PDF y decime qué estudiar.', '¿Qué información importante falta?', 'Exacto. Sin plazo, tiempo por día y nivel de partida, el plan no entra en tu semana.', 'No es el formato del archivo. Faltan el plazo, el tiempo diario y desde dónde partís.', 10),
  ('estudiar-material', 3, 'judge_result', 'Juzgá el resultado', 'El material no menciona ese tema.', 'Pedido: Armá el mapa solo con temas que estén en los PDF. Si algo no está, decilo.

Respuesta de la IA: También tenés que estudiar modelos de regresión logística, que suelen entrar en este examen.', '¿Qué problema tiene este resultado?', 'Bien. Agregó un tema que no estaba en tus documentos. Hay que estudiar lo que está en la fuente.', 'No es que sea breve. El problema es que sumó un tema que tus PDF no traen.', 10),
  ('documento-presentacion', 1, 'detect_error', 'Detectá el error', 'Este pedido pide diseño y contenido al mismo tiempo.', 'Hacé una presentación completa y linda con este informe.', '¿Cuál es el principal problema de este pedido?', 'Bien. Pedir todo junto da diapositivas vistosas, con texto de más y cifras mal copiadas.', 'No exactamente. El problema es pedir el diseño antes de fijar audiencia, tiempo y contenido.', 10),
  ('documento-presentacion', 2, 'missing_information', 'Qué información falta', 'Ya dice para quién es, pero todavía falta acotar.', 'Convertí este informe en diapositivas para directivos.', '¿Qué información importante falta?', 'Exacto. Sin el tiempo y un límite de ideas, la IA mete el informe entero en las diapositivas.', 'No es el color. Faltan la duración y un tope de ideas por diapositiva.', 10),
  ('documento-presentacion', 3, 'judge_result', 'Juzgá el resultado', 'El informe no trae esa cifra.', 'Pedido: Armá el esquema solo con datos del informe. Si falta un número, escribí A CONFIRMAR.

Respuesta de la IA: Las ventas crecieron 18% y el directorio ya aprobó el presupuesto.', '¿Qué problema tiene este resultado?', 'Bien. Inventó una cifra y una decisión que no estaban en el informe.', 'No está lista para usar. Esa cifra y esa aprobación no salen del documento.', 10),
  ('imagenes-redes', 1, 'detect_error', 'Detectá el error', 'Con este pedido la IA elige todo por su cuenta.', 'Una imagen linda de miel.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin sujeto, escena, luz ni restricciones, el resultado sale genérico y se nota que es IA.', 'No exactamente. El problema es que no describe la imagen ni dice qué hay que evitar.', 10),
  ('imagenes-redes', 2, 'missing_information', 'Qué información falta', 'Ya está el producto, pero el pedido sigue abierto.', 'Foto de un frasco de miel artesanal para Instagram.', '¿Qué información importante falta?', 'Exacto. Falta el formato y, sobre todo, pedir que no escriba texto ni ponga el logo dentro de la imagen.', 'No es el eslogan. Falta el formato y la restricción de no poner texto ni logo en la imagen.', 10),
  ('imagenes-redes', 3, 'judge_result', 'Juzgá el resultado', 'El pedido pedía una imagen sin texto.', 'Pedido: Frasco de miel, luz natural, sin texto ni logos.

Respuesta de la IA: Generé el frasco con el texto “50% OFF” en letras doradas sobre la etiqueta.', '¿Qué problema tiene este resultado?', 'Bien. Ignoró la restricción y metió texto en la imagen, que suele salir deformado.', 'No está bien usarla. El pedido decía sin texto y la respuesta lo agregó igual.', 10),
  ('automatizar-tarea', 1, 'detect_error', 'Detectá el error', 'Este plan salta la prueba.', 'Hacé un script que copie los pedidos y lo ejecuto en la planilla real.', '¿Cuál es el principal problema de este pedido?', 'Bien. Ejecutarlo en el archivo real puede pisar datos. Primero hay que describir la tarea y probar en una copia.', 'No exactamente. El riesgo es correr el script sobre los datos reales sin una prueba.', 10),
  ('automatizar-tarea', 2, 'missing_information', 'Qué información falta', 'Ya se sabe que hay un script, pero no cómo probarlo.', 'Escribí un script que pase los pedidos de una planilla a otra.', '¿Qué información importante falta?', 'Exacto. Falta decir que se prueba en una copia y pedir una explicación de qué va a hacer antes de darle permisos.', 'No es el lenguaje. Falta la prueba en una copia y saber qué hace el script.', 10),
  ('automatizar-tarea', 3, 'judge_result', 'Juzgá el resultado', 'Todavía no autorizaste nada sobre el archivo real.', 'Pedido: Explicá el script y decime cómo probarlo en una copia.

Respuesta de la IA: Ya lo ejecuté sobre tu planilla real y actualicé 240 filas.', '¿Qué problema tiene este resultado?', 'Bien. Dice que modificó el archivo real, que era justo lo que había que evitar, y no podés confiar en esa afirmación.', 'No está resuelto. La respuesta se salta la copia y afirma que ya tocó los datos reales.', 10),
  ('comparar-decidir', 1, 'detect_error', 'Detectá el error', 'Este pedido pide un ganador sin criterios.', 'Decime cuál de las tres opciones es la mejor.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin criterios ni fuentes, “la mejor” es una opinión que no podés justificar.', 'No exactamente. El problema es que no define cómo comparar ni pide de dónde sale cada dato.', 10),
  ('comparar-decidir', 2, 'missing_information', 'Qué información falta', 'Ya hay criterios, pero el pedido no se puede verificar.', 'Compará las tres opciones por precio, soporte e integraciones y decime cuál conviene.', '¿Qué información importante falta?', 'Exacto. Sin la fuente de cada dato no podés abrir el enlace y comprobar el precio o el soporte.', 'No es el orden de la tabla. Falta pedir la fuente de cada dato.', 10),
  ('comparar-decidir', 3, 'judge_result', 'Juzgá el resultado', 'El pedido exigía fuentes.', 'Pedido: Compará por precio y soporte, y citá la fuente de cada dato.

Respuesta de la IA: La opción B sale 30 dólares por mes y tiene el mejor soporte. Es la que conviene.', '¿Qué problema tiene este resultado?', 'Bien. Da un precio y una recomendación sin fuente. No se puede verificar.', 'No está lista para decidir. El precio no tiene fuente, así que puede estar inventado o desactualizado.', 10)
on conflict (use_case_id, position) do update
  set type = excluded.type,
      title = excluded.title,
      instruction = excluded.instruction,
      scenario = excluded.scenario,
      question = excluded.question,
      feedback_correct = excluded.feedback_correct,
      feedback_incorrect = excluded.feedback_incorrect,
      xp = excluded.xp;

insert into public.challenge_options (use_case_id, position, letter, body, is_correct, feedback) values
  ('ventas-sin-formulas', 1, 'a', 'Falta contexto sobre los datos y el resultado esperado.', true, 'Bien. El pedido explica la intención, pero no aclara qué datos existen ni qué significa “debe”.'),
  ('ventas-sin-formulas', 1, 'b', 'Tiene demasiados detalles.', false, 'No exactamente. El problema principal es que falta contexto para que la IA pueda interpretar la planilla.'),
  ('ventas-sin-formulas', 1, 'c', 'Está bien así.', false, 'No exactamente. El problema principal es que falta contexto para que la IA pueda interpretar la planilla.'),
  ('ventas-sin-formulas', 2, 'a', 'Definir qué significa estar en deuda, por ejemplo más de 30 días.', true, 'Exacto. Sin una regla clara, la IA no sabe cómo decidir qué cliente está en deuda.'),
  ('ventas-sin-formulas', 2, 'b', 'Agregar un saludo.', false, 'No es eso. Lo que falta es una regla para decidir la deuda, por ejemplo más de 30 días.'),
  ('ventas-sin-formulas', 2, 'c', 'Pedir una respuesta más larga.', false, 'No es eso. Lo que falta es una regla para decidir la deuda, por ejemplo más de 30 días.'),
  ('ventas-sin-formulas', 3, 'a', 'Inventó datos que no estaban en la información.', true, 'Bien. Una respuesta puede sonar convincente y aun así contener información inventada. Siempre hay que verificarla contra la fuente original.'),
  ('ventas-sin-formulas', 3, 'b', 'La respuesta es demasiado corta.', false, 'No exactamente. Esos nombres y montos no estaban en los datos. La IA los inventó, aunque suene segura.'),
  ('ventas-sin-formulas', 3, 'c', 'Está bien y puede usarse directamente.', false, 'No exactamente. Esos nombres y montos no estaban en los datos. La IA los inventó, aunque suene segura.'),
  ('reporte-campania', 1, 'a', 'No dice quién lo lee y mezcla análisis con redacción.', true, 'Bien. No dice quién lo lee ni pide primero los números. Para que el texto suene redondo, la IA puede inventar conclusiones.'),
  ('reporte-campania', 1, 'b', 'El pedido es demasiado corto para una campaña.', false, 'No exactamente. El problema es que mezcla todo y no define al lector ni qué hay que verificar.'),
  ('reporte-campania', 1, 'c', 'Está bien si después se corrige el diseño.', false, 'No exactamente. El problema es que mezcla todo y no define al lector ni qué hay que verificar.'),
  ('reporte-campania', 2, 'a', 'Quién lee el informe y qué decisión tiene que tomar.', true, 'Exacto. Sin saber quién decide y qué tiene que poder hacer después de leer, el informe queda genérico.'),
  ('reporte-campania', 2, 'b', 'Un saludo inicial más formal.', false, 'No es el tono. Falta decir quién lee y qué decisión tiene que tomar.'),
  ('reporte-campania', 2, 'c', 'Pedir más adjetivos profesionales.', false, 'No es el tono. Falta decir quién lee y qué decisión tiene que tomar.'),
  ('reporte-campania', 3, 'a', 'Sacó una conclusión que el pedido no pedía y no mostró los números.', true, 'Bien. No mostró los números pedidos y cerró con una conclusión que los datos todavía no sostienen.'),
  ('reporte-campania', 3, 'b', 'La respuesta es demasiado corta.', false, 'No es la longitud. El problema es que ignoró el pedido y sacó una conclusión sin mostrar las cifras.'),
  ('reporte-campania', 3, 'c', 'Está bien porque suena decidida.', false, 'No es la longitud. El problema es que ignoró el pedido y sacó una conclusión sin mostrar las cifras.'),
  ('reunion-seguimiento', 1, 'a', 'No pide un formato y deja que la IA complete huecos.', true, 'Bien. Sin un formato, la IA completa responsables o fechas que nadie dijo.'),
  ('reunion-seguimiento', 1, 'b', 'Pide demasiados detalles de una sola reunión.', false, 'No exactamente. El problema es que no fija qué hay que extraer ni qué hacer cuando falta un dato.'),
  ('reunion-seguimiento', 1, 'c', 'Está bien para una minuta.', false, 'No exactamente. El problema es que no fija qué hay que extraer ni qué hacer cuando falta un dato.'),
  ('reunion-seguimiento', 2, 'a', 'Indicar que, si falta un dato, se escriba A CONFIRMAR y no se invente.', true, 'Exacto. Hay que decir qué hacer cuando nadie nombró al responsable o la fecha: marcarlo, no inventarlo.'),
  ('reunion-seguimiento', 2, 'b', 'Pedir un tono más cordial.', false, 'No es la extensión. Falta la regla para los datos que la reunión no dijo.'),
  ('reunion-seguimiento', 2, 'c', 'Agregar una frase de cierre motivadora.', false, 'No es la extensión. Falta la regla para los datos que la reunión no dijo.'),
  ('reunion-seguimiento', 3, 'a', 'Inventó un responsable y una fecha que no estaban en la fuente.', true, 'Bien. La IA inventó un responsable y una fecha que nadie dijo. Había que dejar A CONFIRMAR.'),
  ('reunion-seguimiento', 3, 'b', 'La minuta quedó demasiado ordenada.', false, 'No está bien usarla así. Ese responsable y esa fecha no salieron de la reunión.'),
  ('reunion-seguimiento', 3, 'c', 'Está bien porque una minuta tiene que quedar completa.', false, 'No está bien usarla así. Ese responsable y esa fecha no salieron de la reunión.'),
  ('estudiar-material', 1, 'a', 'No usa tu material ni dice cómo querés estudiar.', true, 'Bien. Un pedido gigante, sin fuentes ni orden, da un resumen que no podés verificar.'),
  ('estudiar-material', 1, 'b', 'Pide un resumen demasiado detallado.', false, 'No exactamente. El problema es que no apoya la respuesta en tu material ni pide un recorrido para estudiar.'),
  ('estudiar-material', 1, 'c', 'Está bien para empezar un parcial.', false, 'No exactamente. El problema es que no apoya la respuesta en tu material ni pide un recorrido para estudiar.'),
  ('estudiar-material', 2, 'a', 'El plazo, el tiempo por día y desde qué nivel partís.', true, 'Exacto. Sin plazo, tiempo por día y nivel de partida, el plan no entra en tu semana.'),
  ('estudiar-material', 2, 'b', 'El nombre del profesor.', false, 'No es el formato del archivo. Faltan el plazo, el tiempo diario y desde dónde partís.'),
  ('estudiar-material', 2, 'c', 'Pedir que la respuesta sea más larga.', false, 'No es el formato del archivo. Faltan el plazo, el tiempo diario y desde dónde partís.'),
  ('estudiar-material', 3, 'a', 'Agregó un tema que no estaba en el material.', true, 'Bien. Agregó un tema que no estaba en tus documentos. Hay que estudiar lo que está en la fuente.'),
  ('estudiar-material', 3, 'b', 'La lista de temas es demasiado corta.', false, 'No es que sea breve. El problema es que sumó un tema que tus PDF no traen.'),
  ('estudiar-material', 3, 'c', 'Está bien porque completa lo que falta del programa.', false, 'No es que sea breve. El problema es que sumó un tema que tus PDF no traen.'),
  ('documento-presentacion', 1, 'a', 'Pide la presentación completa sin definir audiencia, tiempo ni contenido.', true, 'Bien. Pedir todo junto da diapositivas vistosas, con texto de más y cifras mal copiadas.'),
  ('documento-presentacion', 1, 'b', 'Incluye demasiadas restricciones de diseño.', false, 'No exactamente. El problema es pedir el diseño antes de fijar audiencia, tiempo y contenido.'),
  ('documento-presentacion', 1, 'c', 'Está bien si el informe ya está escrito.', false, 'No exactamente. El problema es pedir el diseño antes de fijar audiencia, tiempo y contenido.'),
  ('documento-presentacion', 2, 'a', 'Cuánto dura la presentación y cuántas ideas van por diapositiva.', true, 'Exacto. Sin el tiempo y un límite de ideas, la IA mete el informe entero en las diapositivas.'),
  ('documento-presentacion', 2, 'b', 'El color de fondo de las diapositivas.', false, 'No es el color. Faltan la duración y un tope de ideas por diapositiva.'),
  ('documento-presentacion', 2, 'c', 'Una frase de agradecimiento final.', false, 'No es el color. Faltan la duración y un tope de ideas por diapositiva.'),
  ('documento-presentacion', 3, 'a', 'Inventó una cifra y una decisión que no estaban en el informe.', true, 'Bien. Inventó una cifra y una decisión que no estaban en el informe.'),
  ('documento-presentacion', 3, 'b', 'El esquema tiene pocos títulos.', false, 'No está lista para usar. Esa cifra y esa aprobación no salen del documento.'),
  ('documento-presentacion', 3, 'c', 'Está bien porque una presentación tiene que cerrar con un dato fuerte.', false, 'No está lista para usar. Esa cifra y esa aprobación no salen del documento.'),
  ('imagenes-redes', 1, 'a', 'No describe la imagen ni qué hay que evitar.', true, 'Bien. Sin sujeto, escena, luz ni restricciones, el resultado sale genérico y se nota que es IA.'),
  ('imagenes-redes', 1, 'b', 'Pide demasiados estilos a la vez.', false, 'No exactamente. El problema es que no describe la imagen ni dice qué hay que evitar.'),
  ('imagenes-redes', 1, 'c', 'Está bien porque la IA sabe cómo se ve una publicidad.', false, 'No exactamente. El problema es que no describe la imagen ni dice qué hay que evitar.'),
  ('imagenes-redes', 2, 'a', 'El formato y pedir que no haya texto ni logo dentro de la imagen.', true, 'Exacto. Falta el formato y, sobre todo, pedir que no escriba texto ni ponga el logo dentro de la imagen.'),
  ('imagenes-redes', 2, 'b', 'Un eslogan más creativo.', false, 'No es el eslogan. Falta el formato y la restricción de no poner texto ni logo en la imagen.'),
  ('imagenes-redes', 2, 'c', 'Pedir que la imagen sea más brillante.', false, 'No es el eslogan. Falta el formato y la restricción de no poner texto ni logo en la imagen.'),
  ('imagenes-redes', 3, 'a', 'Ignoró la restricción y puso texto dentro de la imagen.', true, 'Bien. Ignoró la restricción y metió texto en la imagen, que suele salir deformado.'),
  ('imagenes-redes', 3, 'b', 'La descripción es demasiado concreta.', false, 'No está bien usarla. El pedido decía sin texto y la respuesta lo agregó igual.'),
  ('imagenes-redes', 3, 'c', 'Está bien porque el texto ayuda a vender.', false, 'No está bien usarla. El pedido decía sin texto y la respuesta lo agregó igual.'),
  ('automatizar-tarea', 1, 'a', 'Propone ejecutarlo en los datos reales, sin prueba ni explicación.', true, 'Bien. Ejecutarlo en el archivo real puede pisar datos. Primero hay que describir la tarea y probar en una copia.'),
  ('automatizar-tarea', 1, 'b', 'Pide un script demasiado simple.', false, 'No exactamente. El riesgo es correr el script sobre los datos reales sin una prueba.'),
  ('automatizar-tarea', 1, 'c', 'Está bien si la tarea es repetitiva.', false, 'No exactamente. El riesgo es correr el script sobre los datos reales sin una prueba.'),
  ('automatizar-tarea', 2, 'a', 'Probarlo en una copia y pedir que explique qué hace.', true, 'Exacto. Falta decir que se prueba en una copia y pedir una explicación de qué va a hacer antes de darle permisos.'),
  ('automatizar-tarea', 2, 'b', 'Elegir un nombre más corto para el archivo.', false, 'No es el lenguaje. Falta la prueba en una copia y saber qué hace el script.'),
  ('automatizar-tarea', 2, 'c', 'Pedir que el código sea más largo.', false, 'No es el lenguaje. Falta la prueba en una copia y saber qué hace el script.'),
  ('automatizar-tarea', 3, 'a', 'Afirma que ya modificó el archivo real, en contra de lo pedido.', true, 'Bien. Dice que modificó el archivo real, que era justo lo que había que evitar, y no podés confiar en esa afirmación.'),
  ('automatizar-tarea', 3, 'b', 'La explicación tiene pocos pasos.', false, 'No está resuelto. La respuesta se salta la copia y afirma que ya tocó los datos reales.'),
  ('automatizar-tarea', 3, 'c', 'Está bien porque así se ahorra tiempo.', false, 'No está resuelto. La respuesta se salta la copia y afirma que ya tocó los datos reales.'),
  ('comparar-decidir', 1, 'a', 'No define criterios ni pide fuentes.', true, 'Bien. Sin criterios ni fuentes, “la mejor” es una opinión que no podés justificar.'),
  ('comparar-decidir', 1, 'b', 'Compara demasiadas opciones a la vez.', false, 'No exactamente. El problema es que no define cómo comparar ni pide de dónde sale cada dato.'),
  ('comparar-decidir', 1, 'c', 'Está bien si la IA tiene búsqueda.', false, 'No exactamente. El problema es que no define cómo comparar ni pide de dónde sale cada dato.'),
  ('comparar-decidir', 2, 'a', 'Pedir la fuente de cada dato para poder comprobarlo.', true, 'Exacto. Sin la fuente de cada dato no podés abrir el enlace y comprobar el precio o el soporte.'),
  ('comparar-decidir', 2, 'b', 'Agregar una columna de color.', false, 'No es el orden de la tabla. Falta pedir la fuente de cada dato.'),
  ('comparar-decidir', 2, 'c', 'Pedir una respuesta más entusiasta.', false, 'No es el orden de la tabla. Falta pedir la fuente de cada dato.'),
  ('comparar-decidir', 3, 'a', 'Da un precio y una recomendación sin citar la fuente.', true, 'Bien. Da un precio y una recomendación sin fuente. No se puede verificar.'),
  ('comparar-decidir', 3, 'b', 'Recomienda una sola opción y eso siempre está mal.', false, 'No está lista para decidir. El precio no tiene fuente, así que puede estar inventado o desactualizado.'),
  ('comparar-decidir', 3, 'c', 'Está bien porque el número es concreto.', false, 'No está lista para decidir. El precio no tiene fuente, así que puede estar inventado o desactualizado.')
on conflict (use_case_id, position, letter) do update
  set body = excluded.body,
      is_correct = excluded.is_correct,
      feedback = excluded.feedback;

update public.use_case_fields
   set in_practice = true
 where (use_case_id, key) in (
  ('ventas-sin-formulas', 'objetivo'),
  ('ventas-sin-formulas', 'columnas'),
  ('ventas-sin-formulas', 'herramienta'),
  ('reporte-campania', 'datos'),
  ('reporte-campania', 'lector'),
  ('reporte-campania', 'objetivo'),
  ('reunion-seguimiento', 'fuente'),
  ('reunion-seguimiento', 'contexto'),
  ('reunion-seguimiento', 'incluir'),
  ('estudiar-material', 'material'),
  ('estudiar-material', 'plazo'),
  ('estudiar-material', 'tiempo_diario'),
  ('documento-presentacion', 'tema'),
  ('documento-presentacion', 'audiencia'),
  ('documento-presentacion', 'duracion'),
  ('imagenes-redes', 'producto'),
  ('imagenes-redes', 'formato'),
  ('imagenes-redes', 'uso'),
  ('automatizar-tarea', 'tarea'),
  ('automatizar-tarea', 'origen'),
  ('automatizar-tarea', 'cuando'),
  ('comparar-decidir', 'decision'),
  ('comparar-decidir', 'opciones'),
  ('comparar-decidir', 'criterios')
 );

-- Las categorías viejas quedan sin casos después de reasignar.
delete from public.categories c
where c.id in ('administracion', 'vinculacion', 'explicacion-ia', 'diseno', 'programacion')
  and not exists (
    select 1 from public.use_case_categories uc where uc.category_id = c.id
  );

update public.profiles
   set goal = 'Resolver tareas concretas usando IA, sin tener que saber de antemano qué herramienta elegir.'
 where id = public.demo_profile_id();

update public.use_cases set output_template = $tpl$Necesito preparar una presentación. Trabajemos primero el contenido, sin diseñar todavía.

Tema o material:
{{tema}}

Audiencia: {{audiencia}}
Duración: {{duracion}}
Cantidad de diapositivas: {{diapositivas}}
Objetivo: {{objetivo}}
Tono: {{tono}}

Convertí este material en un esquema de diapositivas.
Para cada una incluí: título, como máximo 3 ideas y una frase de cierre.
Después escribí las notas del orador en una o dos oraciones por diapositiva.
No inventes cifras, nombres ni datos que no estén en el material. Si falta algo, escribí A CONFIRMAR.$tpl$
where id = 'documento-presentacion';

update public.use_cases set output_template = $tpl$Tengo una planilla de {{herramienta}} en {{idioma}}.

Columnas:
{{columnas}}

Cantidad aproximada de filas: {{filas}}
Quiero lograr esto:
{{objetivo}}

No me des un análisis genérico. Decime qué tiene que calcular la planilla, dame la fórmula lista para pegar y explicala en una línea.
Indicá en qué celda pegarla.
Si la planilla está en español, usá punto y coma como separador.
No incluyas datos personales. Voy a probar la fórmula con 3 filas cuyo resultado ya conozco.$tpl$
where id = 'ventas-sin-formulas';

update public.use_cases set output_template = $tpl$Necesito un informe de una página sobre una campaña.

Datos que tengo:
{{datos}}

Quién lo lee: {{lector}}
Decisión que tiene que tomar: {{objetivo}}
Tono: {{tono}}

Primero calculá los indicadores que se puedan sacar de estos datos y listá los 3 mejores y los 3 peores resultados.
No redactes conclusiones que los números no sostengan.
Después escribí el informe con esta estructura: resumen en 3 líneas, qué funcionó, qué no, y 3 acciones concretas.
Evitá siglas. Si falta un dato, escribí A CONFIRMAR.$tpl$
where id = 'reporte-campania';

update public.use_cases set output_template = $tpl$Necesito dejar por escrito una reunión.

Fuente: {{fuente}}
Contexto:
{{contexto}}

Qué necesito: {{incluir}}
Tono: {{tono}}

Si pedí minuta, armala con fecha, asistentes, decisiones, tareas (quién, qué, para cuándo) y temas pendientes.
No inventes responsables ni fechas. Si falta un dato, escribí A CONFIRMAR.
Si pedí mail, redactá un correo de seguimiento de unas 120 palabras usando solo lo que está en la minuta.
Si pedí ambos, hacé primero la minuta y después el mail.$tpl$
where id = 'reunion-seguimiento';

update public.use_cases set output_template = $tpl$Necesito estudiar este material:

{{material}}

Plazo: {{plazo}}
Tiempo por día: {{tiempo_diario}}
Objetivo: {{objetivo}}
Nivel de partida: {{nivel}}

Empezá por un mapa de los temas, ordenados de lo básico a lo complejo.
Después explicalos de a uno, con un ejemplo, según mi nivel de partida.
Cerrá con un plan día por día que entre en el plazo y el tiempo diario, con repasos.
No agregues temas que no estén en el material. Si algo no está, decilo.$tpl$
where id = 'estudiar-material';

update public.use_cases set output_template = $tpl$Necesito una imagen para publicar, que no parezca genérica.

Producto o tema:
{{producto}}

Formato: {{formato}}
Dónde se publica: {{uso}}
Estilo: {{estilo}}
Colores: {{colores}}
Qué evitar: {{evitar}}

Escribí un pedido visual concreto con sujeto, escenario, luz, estilo, colores y qué no tiene que aparecer.
No pidas texto ni logos dentro de la imagen: eso se agrega después en una herramienta de diseño.
Proponé 3 variantes y, entre una y otra, cambiá una sola cosa.$tpl$
where id = 'imagenes-redes';

update public.use_cases set output_template = $tpl$Necesito automatizar una tarea repetitiva. No sé programar.

Tarea:
{{tarea}}

De dónde salen los datos: {{origen}}
A dónde tienen que llegar: {{destino}}
Cada cuánto: {{cuando}}
Herramienta: {{herramienta}}

Escribí la solución más simple para esa herramienta y explicala paso a paso, en lenguaje simple.
Incluí dónde se pega o se configura.
Antes de ejecutar nada, indícame que lo pruebe en una copia, nunca en el archivo real.
Si hace falta un permiso, explicá en tres líneas qué estoy autorizando.$tpl$
where id = 'automatizar-tarea';

update public.use_cases set output_template = $tpl$Tengo que tomar una decisión y justificarla con información actual.

Decisión:
{{decision}}

Opciones:
{{opciones}}

Criterios:
{{criterios}}

Restricción: {{restriccion}}

Activá la búsqueda web.
Armá una tabla comparativa con estos criterios.
Citá la fuente de cada dato.
Después recomendá una opción, decí por qué y qué podría salir mal.
Si un dato no tiene fuente, no lo uses: escribí SIN FUENTE.$tpl$
where id = 'comparar-decidir';

delete from public.use_case_fields
where use_case_id in (
  'ventas-sin-formulas',
  'reporte-campania',
  'reunion-seguimiento',
  'estudiar-material',
  'documento-presentacion',
  'imagenes-redes',
  'automatizar-tarea',
  'comparar-decidir'
);

insert into public.use_case_fields (id, use_case_id, "key", label, type, placeholder, required, position, options, helper_text) values
  ('documento-presentacion.tema', 'documento-presentacion', 'tema', '¿Qué documento o tema vas a presentar?', 'textarea', 'Pegá el tema o un resumen del documento', true, 1, '{}', 'No hace falta el archivo completo.'),
  ('documento-presentacion.audiencia', 'documento-presentacion', 'audiencia', '¿A quién se lo vas a presentar?', 'text', 'Por ejemplo, directivos o un docente', true, 2, '{}', null),
  ('documento-presentacion.duracion', 'documento-presentacion', 'duracion', '¿Cuánto tiempo tenés?', 'select', 'Elegí una opción', true, 3, array['5 minutos', '10 minutos', '15 minutos', '20 minutos o más'], null),
  ('documento-presentacion.diapositivas', 'documento-presentacion', 'diapositivas', '¿Cuántas diapositivas, aproximadamente?', 'select', 'Elegí una opción', false, 4, array['Que lo decida según la duración', '5 diapositivas', '8 diapositivas', '10 diapositivas', '12 diapositivas', '15 diapositivas'], null),
  ('documento-presentacion.objetivo', 'documento-presentacion', 'objetivo', '¿Qué tiene que lograr la presentación?', 'select', 'Elegí una opción', true, 5, array['Informar', 'Explicar', 'Convencer', 'Presentar resultados'], null),
  ('documento-presentacion.tono', 'documento-presentacion', 'tono', '¿Qué tono necesitás?', 'select', 'Elegí una opción', true, 6, array['Académico', 'Profesional', 'Simple', 'Persuasivo'], null),

  ('ventas-sin-formulas.herramienta', 'ventas-sin-formulas', 'herramienta', '¿Dónde está la planilla?', 'select', 'Elegí una opción', true, 1, array['Google Sheets', 'Excel'], null),
  ('ventas-sin-formulas.idioma', 'ventas-sin-formulas', 'idioma', '¿En qué idioma está la planilla?', 'select', 'Elegí una opción', true, 2, array['Español', 'Inglés'], 'En español los separadores suelen ser punto y coma.'),
  ('ventas-sin-formulas.columnas', 'ventas-sin-formulas', 'columnas', '¿Qué columnas tiene?', 'textarea', 'Fecha, Vendedor, Producto, Monto, Días de deuda', true, 3, '{}', 'No pegues nombres, mails ni datos bancarios. Con los encabezados alcanza.'),
  ('ventas-sin-formulas.objetivo', 'ventas-sin-formulas', 'objetivo', '¿Qué necesitás saber?', 'textarea', 'Total por vendedor y marcar deudas de más de 30 días', true, 4, '{}', null),
  ('ventas-sin-formulas.filas', 'ventas-sin-formulas', 'filas', '¿Cuántas filas tiene, aproximadamente?', 'text', 'Por ejemplo, 600', false, 5, '{}', null),

  ('reporte-campania.datos', 'reporte-campania', 'datos', '¿Qué datos tenés de la campaña?', 'textarea', 'Impresiones, clics, gasto y conversiones de cada anuncio', true, 1, '{}', null),
  ('reporte-campania.lector', 'reporte-campania', 'lector', '¿Quién va a leer el informe?', 'text', 'Por ejemplo, el dueño de una pyme', true, 2, '{}', null),
  ('reporte-campania.objetivo', 'reporte-campania', 'objetivo', '¿Qué decisión tiene que tomar?', 'textarea', 'Decidir qué anuncios mantener el mes que viene', true, 3, '{}', null),
  ('reporte-campania.tono', 'reporte-campania', 'tono', '¿Qué tono tiene que tener?', 'select', 'Elegí una opción', true, 4, array['Simple', 'Profesional', 'Directo'], null),

  ('reunion-seguimiento.fuente', 'reunion-seguimiento', 'fuente', '¿Con qué fuente contás?', 'select', 'Elegí una opción', true, 1, array['Transcripción', 'Apuntes propios'], null),
  ('reunion-seguimiento.contexto', 'reunion-seguimiento', 'contexto', '¿De qué fue la reunión?', 'textarea', 'Con quién fue y qué se trató', true, 2, '{}', null),
  ('reunion-seguimiento.incluir', 'reunion-seguimiento', 'incluir', '¿Qué necesitás obtener?', 'select', 'Elegí una opción', true, 3, array['Minuta y mail', 'Solo minuta', 'Solo mail'], null),
  ('reunion-seguimiento.tono', 'reunion-seguimiento', 'tono', '¿Qué tono tiene que tener el mail?', 'select', 'Elegí una opción', true, 4, array['Cordial', 'Formal', 'Breve'], null),

  ('estudiar-material.material', 'estudiar-material', 'material', '¿Qué tenés que estudiar?', 'textarea', 'Materia, PDF o certificación', true, 1, '{}', 'No pegues el archivo entero. Con el nombre y los temas alcanza.'),
  ('estudiar-material.plazo', 'estudiar-material', 'plazo', '¿En cuánto tiempo?', 'text', 'Por ejemplo, 14 días', true, 2, '{}', null),
  ('estudiar-material.tiempo', 'estudiar-material', 'tiempo_diario', '¿Cuánto tiempo por día?', 'select', 'Elegí una opción', true, 3, array['30 minutos', '1 hora', '2 horas'], null),
  ('estudiar-material.objetivo', 'estudiar-material', 'objetivo', '¿Para qué lo estudiás?', 'text', 'Por ejemplo, aprobar un parcial', true, 4, '{}', null),
  ('estudiar-material.nivel', 'estudiar-material', 'nivel', '¿Desde dónde partís?', 'select', 'Elegí una opción', true, 5, array['Desde cero', 'Ya sé lo básico', 'Es un repaso'], null),

  ('imagenes-redes.producto', 'imagenes-redes', 'producto', '¿Qué hay que mostrar?', 'textarea', 'El producto o la idea', true, 1, '{}', null),
  ('imagenes-redes.formato', 'imagenes-redes', 'formato', '¿Qué formato necesitás?', 'select', 'Elegí una opción', true, 2, array['Cuadrado', 'Vertical', 'Horizontal'], null),
  ('imagenes-redes.uso', 'imagenes-redes', 'uso', '¿Dónde se va a publicar?', 'text', 'Por ejemplo, una historia de Instagram', true, 3, '{}', null),
  ('imagenes-redes.estilo', 'imagenes-redes', 'estilo', '¿Qué estilo buscás?', 'text', 'Por ejemplo, foto de revista con luz natural', true, 4, '{}', null),
  ('imagenes-redes.colores', 'imagenes-redes', 'colores', '¿Qué colores tiene que respetar?', 'text', 'Por ejemplo, dorado y blanco', false, 5, '{}', null),
  ('imagenes-redes.evitar', 'imagenes-redes', 'evitar', '¿Qué no tiene que aparecer?', 'textarea', 'Texto, logos, personas, fondos brillantes', false, 6, '{}', null),

  ('automatizar-tarea.tarea', 'automatizar-tarea', 'tarea', '¿Qué tarea se repite?', 'textarea', 'Qué copiás, desde qué columnas y qué le agregás', true, 1, '{}', null),
  ('automatizar-tarea.origen', 'automatizar-tarea', 'origen', '¿De dónde salen los datos?', 'text', 'Por ejemplo, la planilla de pedidos', true, 2, '{}', null),
  ('automatizar-tarea.destino', 'automatizar-tarea', 'destino', '¿A dónde tienen que llegar?', 'text', 'Por ejemplo, la planilla de control', true, 3, '{}', null),
  ('automatizar-tarea.cuando', 'automatizar-tarea', 'cuando', '¿Cada cuánto?', 'text', 'Por ejemplo, todos los lunes', true, 4, '{}', null),
  ('automatizar-tarea.herramienta', 'automatizar-tarea', 'herramienta', '¿En qué herramienta está?', 'select', 'Elegí una opción', true, 5, array['Google Sheets', 'Excel', 'Otra'], null),

  ('comparar-decidir.decision', 'comparar-decidir', 'decision', '¿Qué tenés que decidir?', 'textarea', 'La decisión que tenés que justificar', true, 1, '{}', null),
  ('comparar-decidir.opciones', 'comparar-decidir', 'opciones', '¿Cuáles son las opciones?', 'textarea', 'Dos o tres alternativas', true, 2, '{}', null),
  ('comparar-decidir.criterios', 'comparar-decidir', 'criterios', '¿Con qué criterios las comparás?', 'textarea', 'Precio, soporte, facilidad, integraciones', true, 3, '{}', null),
  ('comparar-decidir.restriccion', 'comparar-decidir', 'restriccion', '¿Hay algo que no puede faltar?', 'textarea', 'Una condición obligatoria, si existe', false, 4, '{}', null);
