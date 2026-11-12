-- Esqueleto y catalogo: niveles, habilidades, logros y los casos de uso con
-- sus pasos, herramientas y desafios.
--
-- A proposito NO siembra usuarios ni progreso. Cada cuenta de Supabase Auth
-- crea su fila en profiles via el trigger on_auth_user_created y arranca en
-- cero. El progreso se llena practicando.
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

-- Los perfiles de producto los crea el trigger public.handle_new_user()
-- cuando nace un usuario en auth.users. No se siembra un perfil demo.

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

-- SkillBot 2.0 — 45 casos para emprendedores, además de los 8 ya publicados.
-- No borra esos 8, ni su guía, ni el progreso. Los ids de este bloque son otros.
-- 42 fichas no tienen pasos, campos ni desafíos: la pantalla muestra que la práctica no está armada.
-- Tres casos sí tienen guía completa: auditoria-instagram, diagnostico-financiero y pedidos-multicanal.
-- Las etiquetas usan solo ids de onboarding_options. Reejecutar este bloque no duplica filas.
insert into public.use_cases (id, title, summary, situation, skill_id, difficulty, estimated_minutes, icon, color, common_mistake, learning_outcome, xp_reward, status, sort_order, area, output_template) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q7b29ce2c44$Auditar una cuenta de Instagram con tus propias métricas$q7b29ce2c44$, $q07e40ec291$Interpretá el período de una cuenta profesional con los números que copiás de Estadísticas, sin conectar la cuenta a ninguna herramienta.$q07e40ec291$, $qd65c812984$Publicás seguido y no sabés si el alcance, las visitas al perfil o los clics al enlace justifican seguir con el mismo tipo de piezas. La contraseña no se comparte: el análisis sale de lo que vos pegás.$qd65c812984$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $q50e19fda0d$Image$q50e19fda0d$, $qb0f7f12833$pink$qb0f7f12833$, $qdfc461af63$Pedirle a la IA que entre a la cuenta o que diga que creciste sin pegar los números del período.$qdfc461af63$, $q34f7babb60$Leer métricas que exportaste y pedir cambios solo sobre esos datos.$q34f7babb60$, 40, $qc2807535f2$published$qc2807535f2$, 101, $qa286075043$marketing$qa286075043$, $q720a4e9ba9$Quiero auditar una cuenta de Instagram con datos que yo pego. No tenés acceso a la cuenta y no digas que te conectaste.

Cuenta: {{cuenta}}
Período: {{periodo}}
Objetivo del negocio: {{objetivo}}

Métricas que copié de Estadísticas. Si falta alguna, no la completes: escribí DATO NO INFORMADO.
{{metricas}}

Piezas del período, si las anoté:
{{piezas}}

Hacé esto, en este orden:
1. Repetí los números que te pasé, sin redondear ni inventar comparaciones con un período anterior que no esté escrito.
2. Calculá, mostrando la cuenta, solo los indicadores que se puedan sacar de esos números. Si no se puede, explicalo.
3. Decime qué métrica no alcanza para saber si la cuenta cumple el objetivo.
4. Proponé 3 cambios para el próximo período, cada uno atado a un número que yo haya pegado.$q720a4e9ba9$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qeaad294007$Comparar competidores sin copiarles$qeaad294007$, $qd0bf7d8953$Armá una lectura de dos o tres competidores para decidir qué decir distinto, no para repetir sus publicaciones.$qd0bf7d8953$, $q81ea5db008$Vendés en el mismo barrio o rubro que otras cuentas. Ves que publican seguido, pero no sabés si conviene imitar el formato, el precio que muestran o el tono.$q81ea5db008$, $q48f9fc3ca0$investigacion$q48f9fc3ca0$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qa29f025627$Scale$qa29f025627$, $qb0f7f12833$pink$qb0f7f12833$, $q9df73f2c8e$Pedirle a la IA que copie el estilo de un competidor y publicar eso como si fuera propio.$q9df73f2c8e$, $q565252be7d$Comparar con criterios propios y quedarte con una diferencia que puedas sostener.$q565252be7d$, 30, $qc2807535f2$published$qc2807535f2$, 102, $qa286075043$marketing$qa286075043$, null),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q077d9e7f35$Diseñar una campaña con un presupuesto chico$q077d9e7f35$, $q2175b19935$Definí a quién le hablás, cuánto podés gastar y qué tiene que pasar para saber si la campaña sirvió.$q2175b19935$, $q8a16d3a86b$Querés pagar un anuncio por primera vez, o repetir uno, y el presupuesto es el de un mes flojo. Si no fijás el tope y la meta, el gasto se va sin un criterio para cortar.$q8a16d3a86b$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q134ca9eedf$Avanzada$q134ca9eedf$, 45, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $qb0f7f12833$pink$qb0f7f12833$, $qb8b41c8e43$Pedir una campaña creativa sin decir el monto máximo ni qué cuenta como resultado.$qb8b41c8e43$, $q944ddd423b$Traducir un presupuesto en una meta, una audiencia y una regla para frenar el gasto.$q944ddd423b$, 30, $qc2807535f2$published$qc2807535f2$, 103, $qa286075043$marketing$qa286075043$, null),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $qdf3f13784b$Decidir qué anuncios cortar con los números que ya tenés$qdf3f13784b$, $q1fa3e5a84b$Leé un período de anuncios ya corridos y separá los que justifican seguir de los que hay que pausar.$q1fa3e5a84b$, $q263a28d9ef$Ya gastaste en anuncios. El panel muestra alcance, clics y alguna venta, pero no está claro cuál pieza se queda y cuál se apaga el lunes.$q263a28d9ef$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 30, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $qb0f7f12833$pink$qb0f7f12833$, $q2dcbe8ba4c$Pedir que la IA elija al ganador sin pegar el gasto y los resultados de cada anuncio.$q2dcbe8ba4c$, $q03fba7135f$Pausar o sostener un anuncio con una cuenta que sale de tus propios números.$q03fba7135f$, 30, $qc2807535f2$published$qc2807535f2$, 104, $qa286075043$marketing$qa286075043$, null),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qb1e26516f5$Elegir qué producir según señales del rubro$qb1e26516f5$, $q3144ea2a9a$Juntá señales recientes de tu rubro y decidí qué ofrecer este mes, en vez de publicar lo que ya se saturó.$q3144ea2a9a$, $q80aa406ee6$Hacés productos o servicios que cambian con la temporada. No querés stock o contenidos de algo que tus clientes ya dejaron de pedir.$q80aa406ee6$, $q48f9fc3ca0$investigacion$q48f9fc3ca0$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qa29f025627$Scale$qa29f025627$, $qb0f7f12833$pink$qb0f7f12833$, $q741ed14f49$Tomar una tendencia de memoria de la IA, sin fecha ni fuente, y comprar o producir en base a eso.$q741ed14f49$, $q446709165d$Pedir señales con fuente y fecha, y cruzarlas con lo que tus clientes ya te pidieron.$q446709165d$, 30, $qc2807535f2$published$qc2807535f2$, 105, $qa286075043$marketing$qa286075043$, null),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q03fa86caf7$Armar el recorrido desde el aviso hasta la consulta$q03fa86caf7$, $qb9ab4c127e$Diseñá el camino que hace una persona desde que ve la publicación hasta que te escribe, y detectá dónde se cae.$qb9ab4c127e$, $q337ea331fe$Hay visitas o me gusta, pero pocas consultas. No está claro si el problema es el aviso, el perfil, el mensaje de WhatsApp o la falta de un paso intermedio.$q337ea331fe$, $q66dc193dc9$organizacion$q66dc193dc9$, $q134ca9eedf$Avanzada$q134ca9eedf$, 50, $qd7a484140f$Workflow$qd7a484140f$, $qb0f7f12833$pink$qb0f7f12833$, $q49751f73c2$Pedir más publicaciones cuando todavía no existe un camino claro para que la persona consulte.$q49751f73c2$, $qaca81a0d24$Nombrar cada paso del recorrido y decidir cuál vas a cambiar primero.$qaca81a0d24$, 30, $qc2807535f2$published$qc2807535f2$, 106, $qa286075043$marketing$qa286075043$, null),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q008356eab8$Planificar el lanzamiento de una oferta$q008356eab8$, $q270965038b$Ordená las semanas previas a salir con una oferta nueva: a quién se lo contás, qué tiene que estar listo y cómo sabés que funcionó.$q270965038b$, $q440a116953$Vas a abrir un turno, un menú o un servicio nuevo en una fecha fija. Si improvisás el día anterior, se mezclan el stock, el mensaje y las consultas.$q440a116953$, $q4d6a43f8b2$comunicacion$q4d6a43f8b2$, $q134ca9eedf$Avanzada$q134ca9eedf$, 70, $q6e875951a6$Presentation$q6e875951a6$, $qb0f7f12833$pink$qb0f7f12833$, $qedcd46988e$Pedir un calendario de posts genérico sin fecha de salida, cupo ni qué pasa si se agota.$qedcd46988e$, $q9cc6934d94$Bajar un lanzamiento a una secuencia con responsables y una señal de corte.$q9cc6934d94$, 30, $qc2807535f2$published$qc2807535f2$, 107, $qa286075043$marketing$qa286075043$, null),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $q9b5587f6f9$Explicar por qué te eligen y no a otro$q9b5587f6f9$, $q31cce27710$Pasá de una descripción del oficio a una razón concreta para elegirte, usable en el perfil, el presupuesto y la vidriera.$q31cce27710$, $q4149eb7708$Cuando te preguntan qué hacés, respondés el rubro. El cliente compara por precio porque no entiende la diferencia.$q4149eb7708$, $q4d6a43f8b2$comunicacion$q4d6a43f8b2$, $qe304d15aca$Fácil$qe304d15aca$, 25, $q6e875951a6$Presentation$q6e875951a6$, $qb0f7f12833$pink$qb0f7f12833$, $q5a993b9655$Aceptar una frase marketinera que podría decir cualquiera del rubro.$q5a993b9655$, $qe4f74d454c$Probar si la frase sigue en pie cuando se la mostrás a un cliente real.$qe4f74d454c$, 30, $qc2807535f2$published$qc2807535f2$, 108, $qa286075043$marketing$qa286075043$, null),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q88bb88dbca$Armar el mes de contenidos con un objetivo de negocio$q88bb88dbca$, $q5246aa4fc8$Distribuí el mes entre piezas que venden, piezas que explican y piezas que responden dudas, con un objetivo medible.$q5246aa4fc8$, $q5bc9a91d64$Publicás cuando te acordás. A fin de mes no podés decir si el contenido trajo consultas o solo llenó el perfil.$q5bc9a91d64$, $q33461f0289$creatividad$q33461f0289$, $q0c77aeece8$Media$q0c77aeece8$, 40, $q50e19fda0d$Image$q50e19fda0d$, $qb0f7f12833$pink$qb0f7f12833$, $q04b9fb8c1c$Pedir 30 ideas sueltas de publicaciones, sin un resultado de negocio para el mes.$q04b9fb8c1c$, $q044575595d$Atar cada semana a una intención: que consulten, que entiendan la oferta o que vuelvan.$q044575595d$, 30, $qc2807535f2$published$qc2807535f2$, 109, $qa286075043$marketing$qa286075043$, null),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qb70849eb7c$Ordenar las respuestas a consultas que se repiten$qb70849eb7c$, $qbb3be3a96d$Convertí las preguntas de siempre en respuestas cortas y revisables, para no reescribirlas en cada chat.$qbb3be3a96d$, $qb910c19912$Cada día te preguntan precio, tiempos, envío o si queda stock. Contestás de memoria y a veces el dato cambia según quién responde.$qb910c19912$, $q4d6a43f8b2$comunicacion$q4d6a43f8b2$, $qe304d15aca$Fácil$qe304d15aca$, 25, $qf1b8421a21$ClipboardList$qf1b8421a21$, $qb0f7f12833$pink$qb0f7f12833$, $q06d67fd3c8$Dejar que la IA invente precios o plazos que no le pasaste.$q06d67fd3c8$, $qf92332ea7b$Separar lo que es dato del negocio de lo que es solo una forma de decirlo.$qf92332ea7b$, 30, $qc2807535f2$published$qc2807535f2$, 110, $qa286075043$marketing$qa286075043$, null),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q5d5774dd1a$Preparar una promo sin regalar el margen$q5d5774dd1a$, $q0554866e2f$Definí una promoción de temporada que se pueda comunicar y que siga cubriendo el costo.$q0554866e2f$, $qb26f21be15$Se acerca una fecha fuerte y querés un descuento. Si el porcentaje sale de un número redondo, podés vender más y ganar menos que un mes normal.$qb26f21be15$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 35, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $qb0f7f12833$pink$qb0f7f12833$, $q5535053a29$Elegir el 2x1 o el 30% porque suena bien, sin calcular qué queda después del costo.$q5535053a29$, $qa088044d6a$Fijar el descuento a partir del costo y recién después escribir cómo se cuenta.$qa088044d6a$, 30, $qc2807535f2$published$qc2807535f2$, 111, $qa286075043$marketing$qa286075043$, null),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $q5d99c6a206$Preparar respuestas a las objeciones que frenan la venta$q5d99c6a206$, $qc2bb2ebc11$Listá las frases con las que la gente no compra y prepará una respuesta que no discuta ni baje el precio de entrada.$qc2bb2ebc11$, $qedf1d92f49$Te dicen que está caro, que lo piensan o que otro lo hace más rápido. En el momento contestás distinto cada vez y a veces regalás un descuento que no hacía falta.$qedf1d92f49$, $q4d6a43f8b2$comunicacion$q4d6a43f8b2$, $q0c77aeece8$Media$q0c77aeece8$, 30, $q6e875951a6$Presentation$q6e875951a6$, $qb0f7f12833$pink$qb0f7f12833$, $qf9d60e7884$Pedir un speech agresivo de cierre, o autorizar un descuento que no definiste.$qf9d60e7884$, $q1535002946$Reconocer la objeción real y responder con un dato o una condición, no con presión.$q1535002946$, 30, $qc2807535f2$published$qc2807535f2$, 112, $qa286075043$marketing$qa286075043$, null),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q04626da0f5$Decidir en qué canales estar y cuáles soltar$q04626da0f5$, $qd0bf17d502$Compará los canales que ya usás según consultas, tiempo que te llevan y ventas, y elegí dónde concentrarte.$qd0bf17d502$, $q4764c4c073$Estás en Instagram, WhatsApp, un marketplace y a veces en otro lado. Mantener todos te saca horas y no sabés cuál trae clientes.$q4764c4c073$, $q48f9fc3ca0$investigacion$q48f9fc3ca0$, $q0c77aeece8$Media$q0c77aeece8$, 35, $qa29f025627$Scale$qa29f025627$, $qb0f7f12833$pink$qb0f7f12833$, $qf5ccd44e72$Abrir un canal nuevo porque está de moda, sin mirar de dónde salieron las últimas ventas.$qf5ccd44e72$, $q9b1bd86e7e$Elegir con el tiempo que podés dedicar y con el origen real de las consultas.$q9b1bd86e7e$, 30, $qc2807535f2$published$qc2807535f2$, 113, $qa286075043$marketing$qa286075043$, null),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qa68964430f$Bajar una campaña a piezas que digan lo mismo$qa68964430f$, $q915fa66bf6$Pasá una oferta ya definida a las piezas que necesitás publicar, sin que cada una cuente una cosa distinta.$q915fa66bf6$, $q8cf9929610$Ya sabés qué vendés y hasta cuándo. Falta la historia, la publicación del feed y el mensaje para reenviar, y cada uno termina con un precio o una fecha diferente.$q8cf9929610$, $q33461f0289$creatividad$q33461f0289$, $q0c77aeece8$Media$q0c77aeece8$, 35, $q50e19fda0d$Image$q50e19fda0d$, $qb0f7f12833$pink$qb0f7f12833$, $qe968733556$Generar piezas sueltas que cambian el precio, la fecha o la condición de la oferta.$qe968733556$, $qad08253ed3$Fijar un mensaje único y derivar las piezas desde ahí.$qad08253ed3$, 30, $qc2807535f2$published$qc2807535f2$, 114, $qa286075043$marketing$qa286075043$, null),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qea02521fff$Retomar a quien consultó y no compró$qea02521fff$, $qbfdabf7001$Armá un seguimiento corto para personas que preguntaron, con una regla de cuándo escribir y cuándo parar.$qbfdabf7001$, $q8238025001$Tenés chats de la semana pasada que quedaron en visto. No querés spamear ni perder a quien sí estaba por comprar.$q8238025001$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 25, $qf1b8421a21$ClipboardList$qf1b8421a21$, $qb0f7f12833$pink$qb0f7f12833$, $q7e5d9cafff$Pedir un mensaje insistente para todos, sin distinguir quién pidió precio y quién solo miró.$q7e5d9cafff$, $qbd9b68338d$Definir un seguimiento con motivo, plazo y un punto en el que se deja de escribir.$qbd9b68338d$, 30, $qc2807535f2$published$qc2807535f2$, 115, $qa286075043$marketing$qa286075043$, null),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qa44d63e47e$Diagnosticar las finanzas del emprendimiento$qa44d63e47e$, $q6822cc1e7c$Interpretá ventas, gastos y caja de un período con totales que ya calculaste. La IA no reemplaza la planilla.$q6822cc1e7c$, $q216469473f$Llegás a fin de mes sin poder decir si el negocio ganó, si el problema es el precio o si la plata está en la calle. Los números están en tickets y en una planilla a medio armar.$q216469473f$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 45, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $q04ce823a42$Pasarle movimientos sueltos y aceptar un margen o una proyección que no sale de tus totales.$q04ce823a42$, $qbd480a059e$Llegar con totales propios y usar la IA para leerlos, mostrando cada cuenta.$qbd480a059e$, 40, $qc2807535f2$published$qc2807535f2$, 116, $qedb3174a7e$finanzas$qedb3174a7e$, $q5329873e77$Voy a pegar totales que ya calculé en la planilla. No los reemplaces por otros. Si una cuenta no cierra, decilo. No entres a ningún banco.

Período: {{periodo}}
Ventas, con el total que yo sumé:
{{ventas}}
Gastos, separados en fijos y variables, con el total que yo sumé:
{{gastos}}
Caja de hoy del negocio, sin la plata personal: {{caja}}
Deudas y cobros pendientes:
{{deudas}}

Con esos números, y sin inventar otros:
1. Repetí mis totales.
2. Mostrá el resultado del período como ventas menos gastos, con la resta escrita.
3. Decime si la caja de hoy cubre los gastos fijos que informé para el mes que viene. Si falta un dato para saberlo, pedilo.
4. Señalá un solo gasto o una deuda para revisar, citando el monto que yo escribí.$q5329873e77$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qeee6f88d5a$Detectar si el dinero no alcanza aunque vendas$qeee6f88d5a$, $q5c6ea03f35$Separá ventas, cobros y pagos del mes para ver si el problema es de margen o de timing de la caja.$q5c6ea03f35$, $qb1b544d421$El mes cerró con ventas buenas y aun así no llegás a pagar alquiler o mercadería. No está claro si se vendió barato o si la plata todavía no entró.$qb1b544d421$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $q70d529c624$Pedirle a la IA que explique la caja sin distinguir qué se vendió, qué se cobró y qué se pagó.$q70d529c624$, $qfbcb32197c$Nombrar si el hueco viene de precios, de cobros atrasados o de un gasto que se adelantó.$qfbcb32197c$, 30, $qc2807535f2$published$qc2807535f2$, 117, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $q2ce3b8307c$Simular qué pasa si subís un precio$q2ce3b8307c$, $q1761b21160$Calculá en la planilla el efecto de un aumento y usá la IA para leer escenarios, no para reemplazar la cuenta.$q1761b21160$, $q7795b631ea$El costo subió y estás por tocar el precio. Te da miedo perder ventas y no tenés escrito cuántas unidades menos seguirían dejando la misma plata.$q7795b631ea$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 30, $qd877b77d22$Table2$qd877b77d22$, $q4c9a82ce72$blue$q4c9a82ce72$, $qbc2f2e21e4$Aceptar un precio nuevo que la IA propone sin mostrar precio actual, costo y unidades.$qbc2f2e21e4$, $qfa6a610cd8$Comparar el resultado de dos precios con una cuenta que podés rehacer.$qfa6a610cd8$, 30, $qc2807535f2$published$qc2807535f2$, 118, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qe262448121$Ver qué producto deja plata y cuál solo ocupa tiempo$qe262448121$, $q229c5aa8d6$Ordená tus productos por lo que queda después del costo directo, no por lo que más se vende.$q229c5aa8d6$, $qd098e1cd37$Tenés un producto que sale mucho y otro que casi no rota. No sabés cuál sostiene el mes porque mirás facturación, no lo que sobra.$qd098e1cd37$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $qa8510c345e$Rankear productos por unidades vendidas y tratar a ese ranking como si fuera ganancia.$qa8510c345e$, $q31eb0ba2e2$Distinguir lo que más se vende de lo que más deja después de sus costos.$q31eb0ba2e2$, 30, $qc2807535f2$published$qc2807535f2$, 119, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qdccb7c478b$Decidir si una compra se paga sola$qdccb7c478b$, $q247ce0ca4e$Estimá en cuánto tiempo una herramienta, máquina o local recuperaría lo que cuesta, con supuestos escritos.$q247ce0ca4e$, $q3dc22ddc3b$Querés comprar un horno, un software o mudarte. El vendedor dice que se paga solo. No tenés la cuenta de cuántos meses de margen harían falta.$q3dc22ddc3b$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q134ca9eedf$Avanzada$q134ca9eedf$, 45, $qa29f025627$Scale$qa29f025627$, $q4c9a82ce72$blue$q4c9a82ce72$, $q0a844b6f57$Aceptar el recupero que promete el vendedor sin escribir tus ventas y tu margen.$q0a844b6f57$, $q729b35a034$Convertir una compra en meses de recupero y marcar qué supuesto, si cambia, rompe la decisión.$q729b35a034$, 30, $qc2807535f2$published$qc2807535f2$, 120, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qdf1e800996$Armar tres escenarios del mes que viene$qdf1e800996$, $q751c046d0e$Proyectá un mes flojo, uno esperado y uno bueno, con las mismas categorías, para ver qué decisión cambia.$q751c046d0e$, $q1121df95a2$El mes que viene tiene una fecha fuerte o un gasto grande. Un solo número te deja sin plan si las ventas vienen peor.$q1121df95a2$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q134ca9eedf$Avanzada$q134ca9eedf$, 70, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $q9159f70c8d$Pedir una proyección única y optimista, sin decir de dónde sale cada supuesto.$q9159f70c8d$, $qd28184122e$Mirar la misma decisión en tres escenarios y elegir qué harías en el peor.$qd28184122e$, 30, $qc2807535f2$published$qc2807535f2$, 121, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qfd088dfc5a$Separar costos fijos y variables de lo que vendés$qfd088dfc5a$, $qc4817f2d22$Desarmá un producto o servicio en lo que cambia con cada venta y lo que pagás igual.$qc4817f2d22$, $q0e79567d9f$Sabés el precio de venta y algunos insumos, pero el alquiler, el packaging y tu tiempo están mezclados. El precio queda a ojo.$q0e79567d9f$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qd877b77d22$Table2$qd877b77d22$, $q4c9a82ce72$blue$q4c9a82ce72$, $qb557c2ee90$Sumar todo en un costo único y después no poder decir qué pasa si vendés el doble.$qb557c2ee90$, $qe4d804c9cc$Clasificar cada costo y usar esa lista antes de tocar el precio.$qe4d804c9cc$, 30, $qc2807535f2$published$qc2807535f2$, 122, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q4a79848a09$Armar un tablero con las pocas cifras que importan$q4a79848a09$, $qef5869e2ec$Elegí un puñado de números mensuales y dejá escrito cómo se calculan, para no rehacer el informe cada vez.$qef5869e2ec$, $qa4c6614ef7$Cada fin de mes armás un resumen distinto. Comparar con el mes anterior lleva más tiempo que mirar el negocio.$qa4c6614ef7$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 35, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $q5d1f44f710$Pedir un dashboard con veinte indicadores que nadie va a actualizar.$q5d1f44f710$, $qce1f56999d$Quedarte con pocas cifras, cada una con su fórmula y su fuente.$qce1f56999d$, 30, $qc2807535f2$published$qc2807535f2$, 123, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q03179174b7$Priorizar a quién cobrar primero$q03179174b7$, $q1d06409254$Ordená las deudas de clientes por monto y antigüedad para decidir a quién escribir esta semana.$q1d06409254$, $q5112950a82$Varias personas te deben. Escribís primero a la que tenés más fresca en la memoria, no a la que más desbalancea la semana.$q5112950a82$, $q66dc193dc9$organizacion$q66dc193dc9$, $qe304d15aca$Fácil$qe304d15aca$, 25, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q4c9a82ce72$blue$q4c9a82ce72$, $qcf210cb8b9$Pedir textos de cobranza sin una lista real de montos y fechas.$qcf210cb8b9$, $q30fd7ffd99$Elegir el orden de cobranza con un criterio y recién después redactar.$q30fd7ffd99$, 30, $qc2807535f2$published$qc2807535f2$, 124, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $q890038e37b$Revisar si el precio cubre el costo real$q890038e37b$, $q3bf2f72221$Contrastá el precio publicado con el costo que acabás de listar y marcá qué productos quedan debajo.$q3bf2f72221$, $q35becfc59e$Hace meses que no tocás los precios y los insumos sí subieron. No querés descubrirlo cuando ya vendiste la tanda.$q35becfc59e$, $qac1d8e49d5$analisis$qac1d8e49d5$, $qe304d15aca$Fácil$qe304d15aca$, 25, $qd877b77d22$Table2$qd877b77d22$, $q4c9a82ce72$blue$q4c9a82ce72$, $qb8c256ff79$Actualizar todos los precios un porcentaje redondo sin mirar el costo de cada uno.$qb8c256ff79$, $q834adec60a$Detectar qué precio ya no cubre su costo antes de aplicar un aumento parejo.$q834adec60a$, 30, $qc2807535f2$published$qc2807535f2$, 125, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q8985a3d5f1$Encontrar gastos chicos que se comen el mes$q8985a3d5f1$, $qa734c6c595$Agrupá suscripciones, delivery, comisiones y compras menores para ver cuáles se pueden cortar.$qa734c6c595$, $qa3d1b63c34$El resumen del banco o de la billetera tiene muchos movimientos chicos. Ninguno asusta solo, pero el mes no cierra.$qa3d1b63c34$, $qac1d8e49d5$analisis$qac1d8e49d5$, $qe304d15aca$Fácil$qe304d15aca$, 30, $qd877b77d22$Table2$qd877b77d22$, $q4c9a82ce72$blue$q4c9a82ce72$, $qa5764c9706$Borrar gastos de memoria o pedirle a la IA que adivine tus suscripciones.$qa5764c9706$, $q386aac944f$Agrupar movimientos reales y elegir uno o dos para cortar esta semana.$q386aac944f$, 30, $qc2807535f2$published$qc2807535f2$, 126, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q4fcad1d53c$Clasificar facturas y tickets del negocio$q4fcad1d53c$, $q7ec470af66$Ordená comprobantes en categorías estables para saber qué es gasto del negocio y qué no.$q7ec470af66$, $qfede43a79d$Tenés una carpeta o un mail lleno de facturas. A fin de mes no podés decir cuánto fue mercadería, flete o algo personal.$qfede43a79d$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q4c9a82ce72$blue$q4c9a82ce72$, $qafe0de0d5d$Fotografiar un ticket y dar por bueno un rubro que la IA inventó porque la imagen no se lee.$qafe0de0d5d$, $q5718b9bb03$Definir categorías y revisar cualquier monto que no se pueda leer en el comprobante.$q5718b9bb03$, 30, $qc2807535f2$published$qc2807535f2$, 127, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $q0272290599$Calcular cuánto hay que vender para no perder$q0272290599$, $qb64ae024ee$Estimá el punto en el que las ventas cubren los costos fijos, con el margen de un producto representativo.$qb64ae024ee$, $q5af90000fc$Sabés que hay que vender más, pero no cuántas unidades o servicios del mes alcanzan para cubrir el alquiler y los costos fijos.$q5af90000fc$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 30, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $qb237da002b$Pedir el punto de equilibrio sin costos fijos ni margen, y usar el número que aparezca.$qb237da002b$, $q1c04601663$Rehacer la cuenta con tus costos y entender qué supuesto la mueve.$q1c04601663$, 30, $qc2807535f2$published$qc2807535f2$, 128, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $q97f85de0ee$Separar la plata del negocio de la tuya$q97f85de0ee$, $q3852d7ccf2$Marcá qué salidas son del negocio y cuáles son retiros tuyos, para no leer como gasto algo que es sueldo.$q3852d7ccf2$, $qc145e8c1e1$Pagás cosas personales desde la misma cuenta del emprendimiento. A fin de mes el negocio parece que pierde, o al revés.$qc145e8c1e1$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 25, $qa29f025627$Scale$qa29f025627$, $q4c9a82ce72$blue$q4c9a82ce72$, $q3728195592$Pedirle a la IA que calcule tu ganancia mezclando retiros, gastos y ventas en una sola lista.$q3728195592$, $q191743c2ec$Leer el resultado del negocio aparte de lo que te llevás.$q191743c2ec$, 30, $qc2807535f2$published$qc2807535f2$, 129, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q4299cc072a$Anticipar los meses flojos con tu historial$q4299cc072a$, $q207766f0c8$Mirá cómo se movieron las ventas en el último año y prepará caja para el mes que suele caer.$q207766f0c8$, $q2c23d72425$Todos los años hay un mes tranquilo y todos los años te agarra sin mercadería paga o sin reserva. El historial está en la planilla, pero no lo usás para el mes que viene.$q2c23d72425$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $q4b61ca69e5$ChartColumn$q4b61ca69e5$, $q4c9a82ce72$blue$q4c9a82ce72$, $qb6b2b403c7$Proyectar el mes flojo con un promedio anual que esconde la caída.$qb6b2b403c7$, $q1e6c8fe153$Usar tus propios meses anteriores, no un estacionalidad genérica del rubro.$q1e6c8fe153$, 30, $qc2807535f2$published$qc2807535f2$, 130, $qedb3174a7e$finanzas$qedb3174a7e$, null),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q91296fa419$Organizar pedidos que llegan por canales distintos$q91296fa419$, $q0959086cc0$Pasá a una sola tabla los pedidos que hoy viven en Instagram, WhatsApp, el mostrador u otro canal.$q0959086cc0$, $q0ba0f21f0c$Anotás pedidos en tres lugares. A la tarde no sabés cuál está pago, cuál hay que producir y cuál ya se entregó. Nadie integra los canales: el orden sale de lo que vos pegás.$q0ba0f21f0c$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $q96baa4ab10$Pedir que la IA lea el WhatsApp del negocio o marque como entregado un pedido que no pegaste.$q96baa4ab10$, $qb904df784d$Unificar pedidos pegados a mano y detectar duplicados o estados que faltan.$qb904df784d$, 40, $qc2807535f2$published$qc2807535f2$, 131, $q6e80dd213a$administracion$q6e80dd213a$, $q2823afae09$Necesito una sola tabla de pedidos. No tenés acceso a mis chats ni al local: trabajá solo con lo que pego. No marques un pedido como entregado si yo no escribí ese estado.

Canales que uso:
{{canales}}

Estados que quiero usar:
{{estados}}

Pedidos que copié, un bloque por pedido:
{{pedidos}}

Qué se me está mezclando:
{{problema}}

Hacé esto:
1. Armá una tabla con columnas: canal, pedido, cantidad, estado y qué dato falta.
2. Si el mismo pedido parece repetido en dos canales, marcalo como POSIBLE DUPLICADO y no lo borres.
3. Si falta el estado, escribí SIN ESTADO. No lo completes por tu cuenta.
4. Dejá al final una lista corta de lo que habría que resolver hoy, solo con pedidos que estén en el texto.$q2823afae09$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qb0a57ff73b$Diseñar un asistente para tareas administrativas repetidas$qb0a57ff73b$, $q931f6de9e6$Escribí las instrucciones de un asistente que te ayude con una tarea administrativa concreta, con límites de lo que no puede decidir.$q931f6de9e6$, $qb60da378d3$Varias veces por semana armás el mismo resumen, la misma lista o el mismo recordatorio. Cada vez empezás de cero y a veces se te escapa un dato.$qb60da378d3$, $q695f5dc76d$automatizacion$q695f5dc76d$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qd7a484140f$Workflow$qd7a484140f$, $q13818a5684$violet$q13818a5684$, $qafa9840cac$Pedir un asistente que haga todo el negocio, sin una tarea, una fuente y una regla de qué no debe inventar.$qafa9840cac$, $q57102a4009$Dejar instrucciones reutilizables, con entradas, salida y lo que queda para una persona.$q57102a4009$, 30, $qc2807535f2$published$qc2807535f2$, 132, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q9596f9e281$Decidir qué reponer antes de que falte$q9596f9e281$, $qba67263a91$Cruzá stock, ventas recientes y plazo del proveedor para elegir qué comprar esta semana.$qba67263a91$, $q4266d21dbb$A veces te quedás sin el producto que más sale y otras veces tenés cajas quietas. El pedido al proveedor sale por costumbre.$q4266d21dbb$, $qac1d8e49d5$analisis$qac1d8e49d5$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qd877b77d22$Table2$qd877b77d22$, $q13818a5684$violet$q13818a5684$, $q189c84d68f$Pedirle a la IA un pedido de reposición sin stock actual ni cuánto tardó el proveedor la última vez.$q189c84d68f$, $qbe6cd3a208$Priorizar la compra con una regla simple que puedas aplicar el mes que viene.$qbe6cd3a208$, 30, $qc2807535f2$published$qc2807535f2$, 133, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $q2699f4e469$Encontrar dónde se traba el trabajo de la semana$q2699f4e469$, $q6f4e28a6fa$Reconstruí el recorrido de un pedido o un encargo y marcá el paso que más se demora.$q6f4e28a6fa$, $q99749f65c2$Los clientes dicen que tardás. Vos sentís que trabajás todo el día, pero no podés señalar si la demora está en cobrar, producir, conseguir un insumo o avisar.$q99749f65c2$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 30, $qd7a484140f$Workflow$qd7a484140f$, $q13818a5684$violet$q13818a5684$, $qdd2bba37fb$Pedir consejos generales de productividad sin describir los pasos reales de un caso reciente.$qdd2bba37fb$, $q5e4d1c9313$Elegir un solo cuello de botella para cambiar esta semana.$q5e4d1c9313$, 30, $qc2807535f2$published$qc2807535f2$, 134, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qdd3072550c$Dejar armado el seguimiento de pedidos sin hacerlo a mano$qdd3072550c$, $qcadd36b220$Definí qué aviso corresponde a cada estado del pedido y cómo se dispara, sin prometer una integración que no existe.$qcadd36b220$, $q7d24398bb2$Cuando el pedido pasa a listo, avisás de memoria. Algunos clientes se enteran al día siguiente y otros reciben dos mensajes.$q7d24398bb2$, $q695f5dc76d$automatizacion$q695f5dc76d$, $q134ca9eedf$Avanzada$q134ca9eedf$, 70, $qd7a484140f$Workflow$qd7a484140f$, $q13818a5684$violet$q13818a5684$, $qc38e654a74$Pedir un bot de WhatsApp conectado al negocio cuando todavía no hay una lista de estados ni una planilla.$qc38e654a74$, $q9c7757e591$Diseñar el aviso y el disparador sobre una copia de la planilla, antes de automatizar el envío.$q9c7757e591$, 30, $qc2807535f2$published$qc2807535f2$, 135, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q8b3ddd567a$Elegir proveedor con criterios del negocio$q8b3ddd567a$, $qf0a9a5c0af$Compará proveedores por precio, plazo, mínimo de compra y problemas de la última entrega.$qf0a9a5c0af$, $q7b0a2ffb17$Tenés dos o tres proveedores para el mismo insumo. El más barato a veces falla la fecha y el otro pide un mínimo que no llegás a comprar.$q7b0a2ffb17$, $q48f9fc3ca0$investigacion$q48f9fc3ca0$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qa29f025627$Scale$qa29f025627$, $q13818a5684$violet$q13818a5684$, $qea5c817a96$Elegir al más barato de una tabla que la IA completó con precios que no te pasaron.$qea5c817a96$, $q114a5688fe$Decidir con criterios escritos y con datos de tus últimas entregas.$q114a5688fe$, 30, $qc2807535f2$published$qc2807535f2$, 136, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qcd1c8a0960$Armar el tablero de pendientes del día$qcd1c8a0960$, $q0d39025489$Dejá una lista corta de lo que tiene que salir hoy, con dueño y estado, en un solo lugar.$q0d39025489$, $qa1aeda8375$Los pendientes viven en chats, papelitos y la cabeza. A la tarde no sabés qué quedó sin hacer y qué ya avisaste.$qa1aeda8375$, $q66dc193dc9$organizacion$q66dc193dc9$, $qe304d15aca$Fácil$qe304d15aca$, 20, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $q861471a7c8$Pasar todos los chats a una lista infinita que nadie vuelve a mirar.$q861471a7c8$, $qf1bdc9960d$Quedarte con lo que vence hoy y con un estado que se pueda actualizar.$qf1bdc9960d$, 30, $qc2807535f2$published$qc2807535f2$, 137, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qa0cb768507$Dejar escrito cómo se hace un trabajo$qa0cb768507$, $q0a18484924$Documentá un proceso que hoy solo sabés vos, con los pasos y los errores que no hay que repetir.$q0a18484924$, $qff27caeddd$Si te enfermás o se suma alguien, el local o el taller se frena porque el procedimiento está en tu cabeza.$qff27caeddd$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qe0760d98f3$BookOpen$qe0760d98f3$, $q13818a5684$violet$q13818a5684$, $qe22d7f245c$Aceptar un manual genérico del rubro que no menciona tus herramientas ni tus excepciones.$qe22d7f245c$, $q53f00ea68a$Escribir un proceso que otra persona pueda seguir sin llamarte en cada paso.$q53f00ea68a$, 30, $qc2807535f2$published$qc2807535f2$, 138, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q9878afb2b9$Repartir las tareas de la semana entre quienes trabajan$q9878afb2b9$, $q09cc34504c$Asigná el trabajo de la semana con carga visible, para que no recaiga siempre en la misma persona.$q09cc34504c$, $qc09dd6b191$Son dos o tres. El lunes se reparte de palabra y el jueves alguien está sobrecargado mientras otra tarea nadie la tomó.$qc09dd6b191$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 25, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $q50a6043bda$Armar un cronograma que ignora días libres, turnos o la cantidad real de horas.$q50a6043bda$, $q39b06d47d6$Repartir con nombres, horas y una tarea que se pueda terminar en la semana.$q39b06d47d6$, 30, $qc2807535f2$published$qc2807535f2$, 139, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q5e008f5cf4$Ordenar reclamos sin perder el historial$q5e008f5cf4$, $qb8be01e20a$Registrá cada reclamo con estado y próximo paso, para no depender de buscar en el chat.$qb8be01e20a$, $qf503abcba3$Un cliente escribe que llegó mal un pedido. Más tarde otro pregunta lo mismo. No encontrás qué le prometiste al primero.$qf503abcba3$, $q4d6a43f8b2$comunicacion$q4d6a43f8b2$, $q0c77aeece8$Media$q0c77aeece8$, 35, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $qd4fb680d40$Responder el reclamo con una política que la IA inventó y que tu negocio no tiene.$qd4fb680d40$, $q25087771ca$Dejar un registro con lo que pasó, lo que ofreciste y qué falta resolver.$q25087771ca$, 30, $qc2807535f2$published$qc2807535f2$, 140, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qf7e1733877$Preparar la reunión semanal con lo que quedó pendiente$qf7e1733877$, $qf169e4b5b2$Armá la agenda de la reunión interna con pendientes, decisiones que hacen falta y un tiempo máximo.$qf169e4b5b2$, $qae99e68ba9$Se juntan igual todos los lunes y se habla de lo urgente. Los temas de la semana pasada vuelven porque no quedaron cerrados.$qae99e68ba9$, $q66dc193dc9$organizacion$q66dc193dc9$, $qe304d15aca$Fácil$qe304d15aca$, 20, $q6e875951a6$Presentation$q6e875951a6$, $q13818a5684$violet$q13818a5684$, $qd3eae704dc$Llegar con una lista larga que no entra en el tiempo y sin decir qué decisión hay que tomar.$qd3eae704dc$, $q1fdd1dbb68$Entrar a la reunión con pocos temas, cada uno con un resultado esperado.$q1fdd1dbb68$, 30, $qc2807535f2$published$qc2807535f2$, 141, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q3713312814$Controlar lo que llega contra lo que pediste$q3713312814$, $q1c81a499ca$Compará el remito o el mensaje del proveedor con el pedido original y dejá asentado qué falta o qué vino de más.$q1c81a499ca$, $qb05d7928ff$Llega mercadería y la guardás rápido. Días después descubrís un faltante que ya no podés reclamar con claridad.$qb05d7928ff$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 25, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $q128ba2a5d5$Dar por recibida una entrega porque el mensaje del proveedor dice que está completa.$q128ba2a5d5$, $q86b0ad57cd$Dejar una diferencia explícita entre lo pedido y lo contado.$q86b0ad57cd$, 30, $qc2807535f2$published$qc2807535f2$, 142, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qdb15e69183$Elegir qué hacer esta semana cuando todo parece urgente$qdb15e69183$, $q70135e0829$Ordená los pendientes por impacto y por fecha, y dejá afuera lo que puede esperar siete días.$q70135e0829$, $qf72af0e317$El lunes hay más tareas que horas. Si no elegís, el día se va en lo que grita más fuerte y no en lo que mueve la semana.$qf72af0e317$, $q66dc193dc9$organizacion$q66dc193dc9$, $qe304d15aca$Fácil$qe304d15aca$, 15, $qa29f025627$Scale$qa29f025627$, $q13818a5684$violet$q13818a5684$, $qa0024a1b66$Pedir un plan motivacional que no tacha nada de la lista.$qa0024a1b66$, $q5f566be094$Salir con pocas prioridades y con una lista de lo que explícitamente espera.$q5f566be094$, 30, $qc2807535f2$published$qc2807535f2$, 143, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qe9a4bf0d60$Armar la primera semana de quien se suma$qe9a4bf0d60$, $q85cef772ea$Prepará los primeros días de una persona nueva: qué tiene que mirar, qué puede decidir y a quién preguntar.$q85cef772ea$, $qc46a3a07e3$Se suma alguien part-time o un familiar a ayudar. El primer día le explicás todo junto y al tercero ya está preguntando lo mismo.$qc46a3a07e3$, $q66dc193dc9$organizacion$q66dc193dc9$, $q0c77aeece8$Media$q0c77aeece8$, 40, $qe0760d98f3$BookOpen$qe0760d98f3$, $q13818a5684$violet$q13818a5684$, $q3cc1c5f555$Entregar un manual genérico de onboarding corporativo que no habla de tu local o tu taller.$q3cc1c5f555$, $qeb8c209984$Dejar una primera semana concreta, con accesos, límites y una tarea chica para practicar.$qeb8c209984$, 30, $qc2807535f2$published$qc2807535f2$, 144, $q6e80dd213a$administracion$q6e80dd213a$, null),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qb7a4f199b4$Cerrar el día con pedidos, plata y pendientes juntos$qb7a4f199b4$, $q863a07c5e3$Dejá un cierre corto: qué se vendió, qué se cobró, qué pedido quedó abierto y qué se mira mañana.$q863a07c5e3$, $q6e8598451f$Cerrás el local o la notebook sin un registro. Al día siguiente reconstruís de memoria si cobraste todo y qué pedido sigue pendiente.$q6e8598451f$, $q66dc193dc9$organizacion$q66dc193dc9$, $qe304d15aca$Fácil$qe304d15aca$, 15, $qf1b8421a21$ClipboardList$qf1b8421a21$, $q13818a5684$violet$q13818a5684$, $qc58725960e$Pedir un informe largo de gestión que no vas a completar un martes a las diez de la noche.$qc58725960e$, $q3c831150d7$Cerrar con cuatro datos que salen de lo que pasó hoy, no de un modelo ideal.$q3c831150d7$, 30, $qc2807535f2$published$qc2807535f2$, 145, $q6e80dd213a$administracion$q6e80dd213a$, null)
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
      sort_order = excluded.sort_order,
      area = excluded.area,
      output_template = excluded.output_template;
insert into public.use_case_categories (use_case_id, category_id, is_primary) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qca749267ce$datos$qca749267ce$, true),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qca749267ce$datos$qca749267ce$, true),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qca749267ce$datos$qca749267ce$, true),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $qca749267ce$datos$qca749267ce$, true),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qca749267ce$datos$qca749267ce$, true),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $q280f9f8162$contenido$q280f9f8162$, true),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qca749267ce$datos$qca749267ce$, true),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qca749267ce$datos$qca749267ce$, true),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $qca749267ce$datos$qca749267ce$, true),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qca749267ce$datos$qca749267ce$, true),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qca749267ce$datos$qca749267ce$, true),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qca749267ce$datos$qca749267ce$, true),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qca749267ce$datos$qca749267ce$, true),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $qca749267ce$datos$qca749267ce$, true),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $qca749267ce$datos$qca749267ce$, true),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $qca749267ce$datos$qca749267ce$, true),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $qca749267ce$datos$qca749267ce$, true),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $qca749267ce$datos$qca749267ce$, true),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $qca749267ce$datos$qca749267ce$, true),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q763d934305$asistente-de-tareas$q763d934305$, $q695f5dc76d$automatizacion$q695f5dc76d$, true),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $qca749267ce$datos$qca749267ce$, true),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q695f5dc76d$automatizacion$q695f5dc76d$, true),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qca749267ce$datos$qca749267ce$, true),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $q66dc193dc9$organizacion$q66dc193dc9$, true),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q66dc193dc9$organizacion$q66dc193dc9$, true)
on conflict (use_case_id, category_id) do update set is_primary = excluded.is_primary;
insert into public.use_case_tools (use_case_id, tool_id, role, reason, sort_order) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q7319264d29$Para interpretar las métricas que pegás. SkillBot no se conecta a Instagram.$q7319264d29$, 1),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q468da084e9$gemini$q468da084e9$, $q816d63e63c$alternative$q816d63e63c$, $q4bd4cd5ca9$Sirve igual si preferís otro chat. Tampoco entra a la cuenta.$q4bd4cd5ca9$, 2),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qab99b4f69a$Para ordenar lo que vos observaste. No entra a las cuentas por vos.$qab99b4f69a$, 1),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $q468da084e9$gemini$q468da084e9$, $q816d63e63c$alternative$q816d63e63c$, $qb7c8615f94$Si preferís contrastar la misma comparación en otra IA.$qb7c8615f94$, 2),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q7fd219e93b$Para armar el plan con los números que vos cargás.$q7fd219e93b$, 1),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q9b794bcc23$copilot$q9b794bcc23$, $q6d5c9dab96$complement$q6d5c9dab96$, $q32bcbdfac5$Si el presupuesto ya está en Excel y querés ordenar las cuentas ahí.$q32bcbdfac5$, 2),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qc422f762df$Si el export está en Excel.$qc422f762df$, 1),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q50cbb8b790$Si el export está en Google Sheets.$q50cbb8b790$, 2),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q96d5a2c9c3$Con búsqueda activada, para traer señales recientes y el enlace.$q96d5a2c9c3$, 1),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qab0ddc029a$chatgpt$qab0ddc029a$, $q816d63e63c$alternative$q816d63e63c$, $q6eb13ad39d$Para la misma búsqueda, si preferís otro asistente.$q6eb13ad39d$, 2),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qf19e677ecf$Para ordenar el recorrido con lo que vos describís. No se conecta a Instagram ni a WhatsApp.$qf19e677ecf$, 1),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qf49946dfff$Para armar la secuencia a partir de tu fecha, cupo y oferta.$qf49946dfff$, 1),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qf1dda22f6c$claude$qf1dda22f6c$, $q816d63e63c$alternative$q816d63e63c$, $q1309611eae$Si el plan queda largo y querés una segunda lectura.$q1309611eae$, 2),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qdde0d9c7c4$Para proponer variantes. La decisión de cuál usar es tuya.$qdde0d9c7c4$, 1),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $qf1dda22f6c$claude$qf1dda22f6c$, $q816d63e63c$alternative$q816d63e63c$, $qb81748aad1$Para revisar si la frase dice algo que otro no puede copiar.$qb81748aad1$, 2),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q016b18cccf$Para proponer el mes a partir de tu objetivo. No publica por vos.$q016b18cccf$, 1),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q866e1ad9de$Para redactar con tus datos. No lee tus chats de WhatsApp.$q866e1ad9de$, 1),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qe89c02134a$Para revisar la cuenta del descuento en la planilla, no para inventar el margen.$qe89c02134a$, 1),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qc2d63e7aaf$diseno$qc2d63e7aaf$, $q6d5c9dab96$complement$q6d5c9dab96$, $q67ef7bf303$Canva, para la pieza, recién cuando el número ya está decidido.$q67ef7bf303$, 2),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qd7d229e7c9$Para ensayar respuestas con ejemplos que vos trajiste.$qd7d229e7c9$, 1),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q3f00c0b9ac$Para armar la comparación con los datos que vos anotás de cada canal.$q3f00c0b9ac$, 1),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q2eb8455278$Para escribir los textos a partir del mensaje que ya cerraste.$q2eb8455278$, 1),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qc2d63e7aaf$diseno$qc2d63e7aaf$, $q6d5c9dab96$complement$q6d5c9dab96$, $qdc0584f6c0$Canva, para componer. El texto y el precio no se generan dentro de la imagen.$qdc0584f6c0$, 2),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q5dc95ceb1d$Para redactar el seguimiento con datos que vos pegás. No envía mensajes.$q5dc95ceb1d$, 1),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qf302a97bcf$Si calculás los totales en Excel. La IA no entra al home banking.$qf302a97bcf$, 1),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q50d726dcb4$Si calculás los totales en Google Sheets.$q50d726dcb4$, 2),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q7b1cf90f8d$Para interpretar totales que ya calculaste en Excel.$q7b1cf90f8d$, 1),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $qf44ae752b7$Para la misma lectura si la planilla está en Google Sheets.$qf44ae752b7$, 2),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q28c50f7537$Para leer la simulación que armaste. El aumento se calcula en la planilla.$q28c50f7537$, 1),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q64e42a3c7b$Si los costos están en Excel.$q64e42a3c7b$, 1),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q8311f05145$Si los costos están en Google Sheets.$q8311f05145$, 2),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q577df31faf$Para cuestionar los supuestos. El recupero lo calculás con tus números.$q577df31faf$, 1),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $q9b794bcc23$copilot$q9b794bcc23$, $q6d5c9dab96$complement$q6d5c9dab96$, $q6be5308c28$Para dejar la cuenta en la planilla y poder cambiar un supuesto.$q6be5308c28$, 2),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qd5289b0746$Para revisar la planilla de escenarios, no para inventar las ventas.$qd5289b0746$, 1),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q55a678dd01$Para ayudarte a clasificar. Los montos los ponés vos.$q55a678dd01$, 1),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $qbf391b345a$Si el tablero va a vivir en Google Sheets.$qbf391b345a$, 1),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q9b794bcc23$copilot$q9b794bcc23$, $q816d63e63c$alternative$q816d63e63c$, $qc986b55db9$Si el tablero va a vivir en Excel.$qc986b55db9$, 2),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q68b378c34c$Para ordenar la lista en la planilla.$q68b378c34c$, 1),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $qab0ddc029a$chatgpt$qab0ddc029a$, $q6d5c9dab96$complement$q6d5c9dab96$, $q5656b11ab6$Para redactar el mensaje una vez que elegiste a quién y cuánto. No se envía solo.$q5656b11ab6$, 2),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qbdc05f6679$Para señalar diferencias. La cuenta del costo es tuya.$qbdc05f6679$, 1),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qac4d17e145$Si pegás el extracto en Excel, sin números de tarjeta ni claves.$qac4d17e145$, 1),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q468da084e9$gemini$q468da084e9$, $q816d63e63c$alternative$q816d63e63c$, $q4df04018e3$Si preferís hacerlo en Google Sheets.$q4df04018e3$, 2),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q7aa3834c98$Para proponer la categoría. Si el comprobante no se lee, el monto queda pendiente.$q7aa3834c98$, 1),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q9b794bcc23$copilot$q9b794bcc23$, $q6d5c9dab96$complement$q6d5c9dab96$, $q629b28afcc$Para volcar la clasificación a la planilla.$q629b28afcc$, 2),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $qec5198358e$Para dejar visible la fórmula. El resultado se verifica cambiando un número.$qec5198358e$, 1),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q211a527423$Para clasificar movimientos que vos etiquetaste. No entra al banco.$q211a527423$, 1),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $qc93a055ca6$Si el historial está en Google Sheets.$qc93a055ca6$, 1),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q9b794bcc23$copilot$q9b794bcc23$, $q816d63e63c$alternative$q816d63e63c$, $q728cd242f8$Si el historial está en Excel.$q728cd242f8$, 2),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q74d9f228b4$Para dejar la tabla en Google Sheets. No lee Instagram ni WhatsApp solo.$q74d9f228b4$, 1),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qab0ddc029a$chatgpt$qab0ddc029a$, $q816d63e63c$alternative$q816d63e63c$, $q690dfea7dc$Si preferís armar la tabla en el chat y después pegarla.$q690dfea7dc$, 2),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q2ea578fc77$Para guardar las instrucciones y volver a usarlas en el mismo chat.$q2ea578fc77$, 1),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qf1dda22f6c$claude$qf1dda22f6c$, $q816d63e63c$alternative$q816d63e63c$, $qe059f29e0f$Si preferís el otro asistente para la misma tarea.$qe059f29e0f$, 2),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q9b794bcc23$copilot$q9b794bcc23$, $qe3b7c980d7$primary$qe3b7c980d7$, $q1eab558117$Si el stock está en Excel.$q1eab558117$, 1),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $qd39944e3fc$Si el stock está en Google Sheets.$qd39944e3fc$, 2),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qe8f8c61bc7$Para ordenar la secuencia que vos contás. No ve tu calendario solo.$qe8f8c61bc7$, 1),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q346a9f48ba$Para pensar el aviso dentro de Google Sheets.$q346a9f48ba$, 1),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qb7af6ad9e9$apps-script$qb7af6ad9e9$, $q6d5c9dab96$complement$q6d5c9dab96$, $q09d8ad096b$Solo después de probar en una copia. No envía WhatsApp por sí mismo.$q09d8ad096b$, 2),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qdad94806ce$Para armar la comparación. Si no hay fuente de un precio, queda sin dato.$qdad94806ce$, 1),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q9b794bcc23$copilot$q9b794bcc23$, $q6d5c9dab96$complement$q6d5c9dab96$, $qce19333fd0$Para guardar la tabla en Excel.$qce19333fd0$, 2),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q0b3fb58bc5$Si la lista va a quedar en Google Sheets.$q0b3fb58bc5$, 1),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qab0ddc029a$chatgpt$qab0ddc029a$, $q816d63e63c$alternative$q816d63e63c$, $qf76ff6020f$Para pasar en limpio pendientes que vos pegás.$qf76ff6020f$, 2),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q75b0efa191$Para ordenar los pasos que vos dictás. No observa cómo trabajás.$q75b0efa191$, 1),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q0e707dcb3f$Para proponer el reparto con las restricciones que vos indicás.$q0e707dcb3f$, 1),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q19ad1fecb6$Para proponer la respuesta a partir del reclamo que pegás.$q19ad1fecb6$, 1),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q468da084e9$gemini$q468da084e9$, $q6d5c9dab96$complement$q6d5c9dab96$, $q24ff079957$Para volcar el caso a una planilla de seguimiento.$q24ff079957$, 2),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q9cb1b0d4bb$Para ordenar la agenda con los pendientes que vos traés.$q9cb1b0d4bb$, 1),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q7056face00$Para armar la lista de diferencias con los dos textos que pegás.$q7056face00$, 1),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q9b794bcc23$copilot$q9b794bcc23$, $q6d5c9dab96$complement$q6d5c9dab96$, $qae9ebdbe58$Si el pedido original ya está en Excel.$qae9ebdbe58$, 2),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $q6b3cbf74ce$Para ayudarte a ordenar. La prioridad final la confirmás vos.$q6b3cbf74ce$, 1),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qab0ddc029a$chatgpt$qab0ddc029a$, $qe3b7c980d7$primary$qe3b7c980d7$, $qea76aa3a5e$Para ordenar el plan con las tareas reales del negocio.$qea76aa3a5e$, 1),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q468da084e9$gemini$q468da084e9$, $qe3b7c980d7$primary$qe3b7c980d7$, $q9f90c04656$Si el cierre se anota en Google Sheets.$q9f90c04656$, 1),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qab0ddc029a$chatgpt$qab0ddc029a$, $q816d63e63c$alternative$q816d63e63c$, $q496f94c505$Para pasar en limpio notas sueltas que vos pegás.$q496f94c505$, 2)
on conflict (use_case_id, tool_id) do update
  set role = excluded.role,
      reason = excluded.reason,
      sort_order = excluded.sort_order;
insert into public.use_case_tags (use_case_id, kind, value) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q58937a361b$publicar_en_redes$q58937a361b$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qa2d343c98e$medir_resultados$qa2d343c98e$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($qd2f4b6924d$analisis-competidores$qd2f4b6924d$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qb958af6ea6$atraer_clientes$qb958af6ea6$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qa2d343c98e$medir_resultados$qa2d343c98e$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($q37a75d7525$campana-presupuesto$q37a75d7525$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qa2d343c98e$medir_resultados$qa2d343c98e$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q89a176f71c$rendimiento-anuncios$q89a176f71c$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q1de2f7b3e1$crear_contenido$q1de2f7b3e1$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q1937c4c28f$tool$q1937c4c28f$, $q468da084e9$gemini$q468da084e9$),
  ($q6f1113287c$tendencias-rubro$q6f1113287c$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qb958af6ea6$atraer_clientes$qb958af6ea6$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q12bfa0a9c4$responder_consultas$q12bfa0a9c4$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q61f23c6cf9$embudo-consultas$q61f23c6cf9$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q714eea0f4c$time$q714eea0f4c$, $q26646a1cea$mas_de_60$q26646a1cea$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qb958af6ea6$atraer_clientes$qb958af6ea6$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q1d550b84cd$lanzamiento-oferta$q1d550b84cd$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $qdb9a022b75$goal$qdb9a022b75$, $qb8cc175a64$mejorar_comunicacion$qb8cc175a64$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $qf96da029a6$experience$qf96da029a6$, $q21174b125e$nunca$q21174b125e$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($qb0290ef053$propuesta-valor$qb0290ef053$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q58937a361b$publicar_en_redes$q58937a361b$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q1de2f7b3e1$crear_contenido$q1de2f7b3e1$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q00aadf9142$calendario-contenidos$q00aadf9142$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qdb9a022b75$goal$qdb9a022b75$, $q34fc9e1660$ahorrar_tiempo$q34fc9e1660$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q12bfa0a9c4$responder_consultas$q12bfa0a9c4$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qdbd2dc5ea7$ahorrar_tiempo_repetitivo$qdbd2dc5ea7$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q260c8d8d06$respuestas-que-se-repiten$q260c8d8d06$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q57451cb708$armar_precios$q57451cb708$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q0414ff0fcb$promo-sin-romper-precio$q0414ff0fcb$, $q1937c4c28f$tool$q1937c4c28f$, $q787256cc41$canva$q787256cc41$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q12bfa0a9c4$responder_consultas$q12bfa0a9c4$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($qcc34be2ed5$objeciones-de-venta$qcc34be2ed5$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q58937a361b$publicar_en_redes$q58937a361b$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q548e6c0234$elegir-canales$q548e6c0234$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qdb9a022b75$goal$qdb9a022b75$, $qb8cc175a64$mejorar_comunicacion$qb8cc175a64$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q1de2f7b3e1$crear_contenido$q1de2f7b3e1$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q5b2dfd9634$explicar_oferta$q5b2dfd9634$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $q1937c4c28f$tool$q1937c4c28f$, $q787256cc41$canva$q787256cc41$),
  ($q0ae07b8ae8$piezas-de-campana$q0ae07b8ae8$, $q1937c4c28f$tool$q1937c4c28f$, $qb66806f4d5$instagram$qb66806f4d5$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $q699e8ae92c$area$q699e8ae92c$, $qa286075043$marketing$qa286075043$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qdb9a022b75$goal$qdb9a022b75$, $q13b4703b6f$conseguir_clientes$q13b4703b6f$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4d0d6cde90$hacer_seguimiento$q4d0d6cde90$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qb958af6ea6$atraer_clientes$qb958af6ea6$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q9d6a4a5a6f$retomar-consultas$q9d6a4a5a6f$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q74452a85b5$cobrar_a_tiempo$q74452a85b5$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q8ee1bb30cf$hueco-de-caja$q8ee1bb30cf$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q57451cb708$armar_precios$q57451cb708$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($qe42b7ea8c6$simular-precio$qe42b7ea8c6$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qddecaff482$rentabilidad-por-producto$qddecaff482$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($q956e588b95$evaluar-una-compra$q956e588b95$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $q714eea0f4c$time$q714eea0f4c$, $q26646a1cea$mas_de_60$q26646a1cea$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qa6277fd9eb$tres-escenarios$qa6277fd9eb$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q57451cb708$armar_precios$q57451cb708$),
  ($qb05b74ccb7$costos-de-un-producto$qb05b74ccb7$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4e6f707b85$ordenar_comprobantes$q4e6f707b85$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qc2d6e8f085$tablero-del-mes$qc2d6e8f085$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q74452a85b5$cobrar_a_tiempo$q74452a85b5$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q7502cca28e$a-quien-cobrar$q7502cca28e$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $qf96da029a6$experience$qf96da029a6$, $q21174b125e$nunca$q21174b125e$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q57451cb708$armar_precios$q57451cb708$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($qad1c1cf3dd$precio-cubre-costo$qad1c1cf3dd$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qd1d424dc12$gastos-que-se-repiten$qd1d424dc12$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $qf96da029a6$experience$qf96da029a6$, $q21174b125e$nunca$q21174b125e$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4e6f707b85$ordenar_comprobantes$q4e6f707b85$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($q0013ca7543$clasificar-comprobantes$q0013ca7543$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $qdb9a022b75$goal$qdb9a022b75$, $q97c636b043$tomar_decisiones$q97c636b043$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q57451cb708$armar_precios$q57451cb708$),
  ($q9b80121871$punto-de-equilibrio$q9b80121871$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q23e497db99$controlar_gastos$q23e497db99$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($q2e8854b8b4$plata-del-negocio$q2e8854b8b4$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q699e8ae92c$area$q699e8ae92c$, $qedb3174a7e$finanzas$qedb3174a7e$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $qdb9a022b75$goal$qdb9a022b75$, $qe66a3817cd$ordenar_finanzas$qe66a3817cd$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q9807e4385f$proyectar_caja$q9807e4385f$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qdf066a6062$meses-flojos$qdf066a6062$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qdbd2dc5ea7$ahorrar_tiempo_repetitivo$qdbd2dc5ea7$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qdb9a022b75$goal$qdb9a022b75$, $q34fc9e1660$ahorrar_tiempo$q34fc9e1660$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qdbd2dc5ea7$ahorrar_tiempo_repetitivo$qdbd2dc5ea7$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q14691e96fa$documentar_procesos$q14691e96fa$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($q763d934305$asistente-de-tareas$q763d934305$, $q1937c4c28f$tool$q1937c4c28f$, $qf1dda22f6c$claude$qf1dda22f6c$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($q7e8e4d4359$que-reponer$q7e8e4d4359$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $qdb9a022b75$goal$qdb9a022b75$, $q34fc9e1660$ahorrar_tiempo$q34fc9e1660$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($qb611002b1b$donde-se-traba$qb611002b1b$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qdb9a022b75$goal$qdb9a022b75$, $q34fc9e1660$ahorrar_tiempo$q34fc9e1660$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q714eea0f4c$time$q714eea0f4c$, $q26646a1cea$mas_de_60$q26646a1cea$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qdbd2dc5ea7$ahorrar_tiempo_repetitivo$qdbd2dc5ea7$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4d0d6cde90$hacer_seguimiento$q4d0d6cde90$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q4f3116ef66$seguimiento-de-pedidos$q4f3116ef66$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qc98d4032c6$elegir-proveedor$qc98d4032c6$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4d0d6cde90$hacer_seguimiento$q4d0d6cde90$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q2bda576437$pendientes-del-dia$q2bda576437$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qf96da029a6$experience$qf96da029a6$, $q21174b125e$nunca$q21174b125e$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q14691e96fa$documentar_procesos$q14691e96fa$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qdbd2dc5ea7$ahorrar_tiempo_repetitivo$qdbd2dc5ea7$),
  ($qd5db060c7e$dejar-escrito-el-proceso$qd5db060c7e$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q6b11b559a0$reparto-semanal$q6b11b559a0$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $qdb9a022b75$goal$qdb9a022b75$, $qb8cc175a64$mejorar_comunicacion$qb8cc175a64$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qd7d414d8d7$atender_clientes$qd7d414d8d7$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4d0d6cde90$hacer_seguimiento$q4d0d6cde90$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($qf80fa76867$historial-de-reclamos$qf80fa76867$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q1bf97db30a$preparar_reuniones$q1bf97db30a$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q845299d073$reunion-de-la-semana$q845299d073$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q714eea0f4c$time$q714eea0f4c$, $qa84ce6df08$de_15_a_30$qa84ce6df08$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q4e6f707b85$ordenar_comprobantes$q4e6f707b85$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q1937c4c28f$tool$q1937c4c28f$, $qd455be4adf$excel$qd455be4adf$),
  ($qc469649d6f$control-de-recepcion$qc469649d6f$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qdb9a022b75$goal$qdb9a022b75$, $q34fc9e1660$ahorrar_tiempo$q34fc9e1660$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qf96da029a6$experience$qf96da029a6$, $q328245a59c$alguna_vez$q328245a59c$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $q714eea0f4c$time$q714eea0f4c$, $qaa103dffd8$menos_15$qaa103dffd8$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qff6c9e7fa7$decidir_con_informacion$qff6c9e7fa7$),
  ($q6fe5c18c8e$que-hacer-esta-semana$q6fe5c18c8e$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qf96da029a6$experience$qf96da029a6$, $q2940ad90a2$seguido$q2940ad90a2$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $q714eea0f4c$time$q714eea0f4c$, $q2192b8743d$de_30_a_60$q2192b8743d$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q14691e96fa$documentar_procesos$q14691e96fa$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q8acd4f4acd$coordinar_pendientes$q8acd4f4acd$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $q1937c4c28f$tool$q1937c4c28f$, $qab0ddc029a$chatgpt$qab0ddc029a$),
  ($qcc3a6ad689$primera-semana-de-alguien$qcc3a6ad689$, $q1937c4c28f$tool$q1937c4c28f$, $qe3dd4cdb7c$calendario$qe3dd4cdb7c$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q699e8ae92c$area$q699e8ae92c$, $q6e80dd213a$administracion$q6e80dd213a$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qdb9a022b75$goal$qdb9a022b75$, $q4b7455f536$ordenar_operacion$q4b7455f536$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qf96da029a6$experience$qf96da029a6$, $q1617db3f80$en_el_negocio$q1617db3f80$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q714eea0f4c$time$q714eea0f4c$, $qaa103dffd8$menos_15$qaa103dffd8$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $q40cc22b365$organizar_tareas$q40cc22b365$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $qa5a0d15d4a$problem$qa5a0d15d4a$, $qe74bd93c45$entender_ventas$qe74bd93c45$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q1937c4c28f$tool$q1937c4c28f$, $q015d94525b$google_sheets$q015d94525b$),
  ($q89fda73da2$cierre-del-dia$q89fda73da2$, $q1937c4c28f$tool$q1937c4c28f$, $q35ff4793f6$whatsapp$q35ff4793f6$)
on conflict (use_case_id, kind, value) do nothing;
insert into public.use_case_fields (id, use_case_id, "key", label, type, placeholder, required, position, options, helper_text, in_practice) values
  ($q2f912a9302$auditoria-instagram.cuenta$q2f912a9302$, $q705ba215c5$auditoria-instagram$q705ba215c5$, $qde7f6b3e6f$cuenta$qde7f6b3e6f$, $q071fa88bcd$¿Qué cuenta vas a mirar?$q071fa88bcd$, $q372ea08cab$text$q372ea08cab$, $q7f339bc231$El @ o el nombre, sin contraseña$q7f339bc231$, true, 1, '{}', $qcbbe4367a1$No pegues la clave ni un código de acceso.$qcbbe4367a1$, true),
  ($qc885197ba7$auditoria-instagram.periodo$qc885197ba7$, $q705ba215c5$auditoria-instagram$q705ba215c5$, $q2a575ca894$periodo$q2a575ca894$, $qc76646a5b7$¿Qué período mirás?$qc76646a5b7$, $q81448fe273$select$q81448fe273$, $qfba98f45e6$Elegí una opción$qfba98f45e6$, true, 2, array[$q2a38397780$Últimos 7 días$q2a38397780$, $q9c6ed4b4ea$Últimos 28 días$q9c6ed4b4ea$, $q196c2e170d$Últimos 90 días$q196c2e170d$], null, true),
  ($q4712a2e71f$auditoria-instagram.metricas$q4712a2e71f$, $q705ba215c5$auditoria-instagram$q705ba215c5$, $q42a83f260d$metricas$q42a83f260d$, $q19232c5c85$¿Qué números copiaste de Estadísticas?$q19232c5c85$, $qfc8656334c$textarea$qfc8656334c$, $q88fd60ea92$Alcance, visitas al perfil, clics al enlace, seguidores que entraron y salieron$q88fd60ea92$, true, 3, '{}', $q4ee8f881d8$Si un número no está en la pantalla, dejalo vacío. No lo estimes.$q4ee8f881d8$, true),
  ($q8747d37a00$auditoria-instagram.objetivo$q8747d37a00$, $q705ba215c5$auditoria-instagram$q705ba215c5$, $qfa9377762c$objetivo$qfa9377762c$, $qe4f77a9324$¿Para qué te sirve la cuenta este mes?$qe4f77a9324$, $q81448fe273$select$q81448fe273$, $qfba98f45e6$Elegí una opción$qfba98f45e6$, true, 4, array[$q7f122fa1c0$Conseguir consultas$q7f122fa1c0$, $q35f345cf6c$Vender un producto$q35f345cf6c$, $q9eb08a3ab7$Que más gente conozca el local$q9eb08a3ab7$], null, true),
  ($q3a01bb6b22$auditoria-instagram.piezas$q3a01bb6b22$, $q705ba215c5$auditoria-instagram$q705ba215c5$, $q79cd889d00$piezas$q79cd889d00$, $qae772aefa8$¿Qué publicaste en ese período?$qae772aefa8$, $qfc8656334c$textarea$qfc8656334c$, $qd89e630752$Fecha y tipo: foto, reel o historia. Una por línea$qd89e630752$, false, 5, '{}', $q80cb2fa0e6$Opcional. Con tres piezas ya se puede mirar el patrón.$q80cb2fa0e6$, true),
  ($q8d824e0f45$diagnostico-financiero.periodo$q8d824e0f45$, $q4a447ba538$diagnostico-financiero$q4a447ba538$, $q2a575ca894$periodo$q2a575ca894$, $qd3fa6fbe9e$¿Qué período cerraste?$qd3fa6fbe9e$, $q81448fe273$select$q81448fe273$, $qfba98f45e6$Elegí una opción$qfba98f45e6$, true, 1, array[$q28a282d8d1$Último mes$q28a282d8d1$, $qc5b8eeba48$Últimos 3 meses$qc5b8eeba48$], null, true),
  ($q1dcaa3aefa$diagnostico-financiero.ventas$q1dcaa3aefa$, $q4a447ba538$diagnostico-financiero$q4a447ba538$, $qefd3caec41$ventas$qefd3caec41$, $q06b0b88a0b$¿Cuánto suman las ventas de ese período?$q06b0b88a0b$, $qfc8656334c$textarea$qfc8656334c$, $q1a7622310e$El total que calculaste, y si cobrado y facturado no son lo mismo, los dos$q1a7622310e$, true, 2, '{}', $qfbc9532791$Sumalo en la planilla antes de pegarlo. No pegues CBU ni números de tarjeta.$qfbc9532791$, true),
  ($q168d219fba$diagnostico-financiero.gastos$q168d219fba$, $q4a447ba538$diagnostico-financiero$q4a447ba538$, $q80dca12ee1$gastos$q80dca12ee1$, $qfb5eab901c$¿Cuánto suman los gastos y cómo se parten?$qfb5eab901c$, $qfc8656334c$textarea$qfc8656334c$, $q8adc141044$Total de fijos, total de variables y dos o tres ejemplos con monto$q8adc141044$, true, 3, '{}', $q79babee2dd$Si un monto no lo sumaste, no lo escribas como si estuviera cerrado.$q79babee2dd$, true),
  ($q8991d87edd$diagnostico-financiero.caja$q8991d87edd$, $q4a447ba538$diagnostico-financiero$q4a447ba538$, $q862448c9b2$caja$q862448c9b2$, $q2d1ac8a195$¿Cuánta plata del negocio hay hoy?$q2d1ac8a195$, $q372ea08cab$text$q372ea08cab$, $qa40dfc7723$Un solo número, sin la cuenta personal$qa40dfc7723$, true, 4, '{}', $q9e883a2e9a$Si no la separaste, decilo en vez de mezclarla.$q9e883a2e9a$, true),
  ($q26c382bbf6$diagnostico-financiero.deudas$q26c382bbf6$, $q4a447ba538$diagnostico-financiero$q4a447ba538$, $q7e5b71e4c1$deudas$q7e5b71e4c1$, $q29f9c63093$¿Qué se debe y qué te deben?$q29f9c63093$, $qfc8656334c$textarea$qfc8656334c$, $qf1a88f303d$Quién, monto y si es para cobrar o para pagar$qf1a88f303d$, false, 5, '{}', $q005d753974$Opcional. Sin nombres de más: alcanza el monto y el concepto.$q005d753974$, true),
  ($qea021d7c0c$pedidos-multicanal.canales$qea021d7c0c$, $qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qdd8327be71$canales$qdd8327be71$, $q8319b13e3b$¿Por dónde te entran los pedidos?$q8319b13e3b$, $qfc8656334c$textarea$qfc8656334c$, $q2c129c37f0$Por ejemplo: Instagram, WhatsApp y mostrador$q2c129c37f0$, true, 1, '{}', $qb4818b8663$Nombrá los canales. No hace falta conectar ninguna cuenta.$qb4818b8663$, true),
  ($qd142fc6610$pedidos-multicanal.pedidos$qd142fc6610$, $qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qb50a7ddd6b$pedidos$qb50a7ddd6b$, $qf44b654f82$¿Qué pedidos vas a ordenar?$qf44b654f82$, $qfc8656334c$textarea$qfc8656334c$, $q30abcf6804$Pegá cada uno con canal, qué pidió, cantidad y el estado si lo sabés$q30abcf6804$, true, 2, '{}', $q5429de2485$Sacá direcciones y documentos si no hacen falta para producir.$q5429de2485$, true),
  ($q14ee4ed9fa$pedidos-multicanal.estados$q14ee4ed9fa$, $qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $q26047a5c14$estados$q26047a5c14$, $qcd3a540839$¿Qué estados usás?$qcd3a540839$, $q372ea08cab$text$q372ea08cab$, $qff3731758d$Por ejemplo: nuevo, en producción, listo, entregado$qff3731758d$, true, 3, '{}', $qe090afb409$Si todavía no tenés estados, proponé cuatro y después los confirmás.$qe090afb409$, true),
  ($qaca12734b7$pedidos-multicanal.problema$qaca12734b7$, $qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, $qc98484f0d2$problema$qc98484f0d2$, $q2b9a5ce8cc$¿Qué se te mezcla hoy?$q2b9a5ce8cc$, $qfc8656334c$textarea$qfc8656334c$, $q7894b7a87f$Pedidos perdidos, duplicados o sin saber si están pagos$q7894b7a87f$, true, 4, '{}', null, true)
on conflict (id) do update
  set label = excluded.label,
      type = excluded.type,
      placeholder = excluded.placeholder,
      required = excluded.required,
      position = excluded.position,
      options = excluded.options,
      helper_text = excluded.helper_text,
      in_practice = excluded.in_practice;
insert into public.use_case_steps (use_case_id, position, body, example_prompt, checklist, requires_confirmation, confirmation_label) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 1, $q405773265a$Entrá a las estadísticas de la cuenta profesional y anotá el período. No compartas la contraseña ni un código.$q405773265a$, null, array[$q5ac27a9b06$Período anotado$q5ac27a9b06$, $q50b01d65a5$Sin contraseña$q50b01d65a5$], false, null),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 2, $q8f71b2cd86$Copiá alcance, visitas al perfil, clics al enlace y el movimiento de seguidores. Si un número no aparece, dejalo en blanco.$q8f71b2cd86$, null, array[$qf03a23ea97$Alcance$qf03a23ea97$, $q99c2582418$Visitas al perfil$q99c2582418$, $qfd2a54984c$Clics o seguidores, si están$qfd2a54984c$], false, null),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 3, $qa587d46e06$Anotá hasta cinco piezas del período, con fecha y formato. No hace falta el texto completo.$qa587d46e06$, null, array[$qbcc476092d$Fecha$qbcc476092d$, $qf1121d078b$Formato de la pieza$qf1121d078b$], false, null),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 4, $q73c3bc26fe$Pegá esos datos en el chat y pedí que repita los números antes de opinar.$q73c3bc26fe$, null, array[$qcfbda6ef75$La respuesta repite tus números$qcfbda6ef75$, $qa72cc2331a$No aparece un período que vos no pasaste$qa72cc2331a$], true, $q2bc83d7337$La respuesta repitió mis números y no inventó un período anterior$q2bc83d7337$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 5, $q5b7a49b24b$Rehacé una cuenta simple, por ejemplo clics dividido alcance, y comparala con la de la IA. Si no coincide, devolvé el cálculo.$q5b7a49b24b$, null, array[$qe4c89a0e24$Una cuenta rehecha a mano$qe4c89a0e24$], false, null),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 1, $q99b62e7d79$Armá en la planilla el total de ventas del período. Si lo facturado y lo cobrado difieren, dejalos en dos filas.$q99b62e7d79$, null, array[$q5e356f2cf4$Total de ventas calculado en la planilla$q5e356f2cf4$], false, null),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 2, $qb0806cac7c$Sumá los gastos y marcalos como fijos o variables. No mezcles retiros personales.$qb0806cac7c$, null, array[$q9f6c1301ba$Gastos fijos$q9f6c1301ba$, $qc9dc87a4c3$Gastos variables$qc9dc87a4c3$, $q7f3584eb13$Sin retiros personales$q7f3584eb13$], false, null),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 3, $qddacc6f14a$Anotá la caja de hoy del negocio y, si los tenés, los montos a cobrar y a pagar.$qddacc6f14a$, null, array[$qc128820a6d$Caja del negocio$qc128820a6d$, $q2da5ee7446$Deudas solo si las tenés a mano$q2da5ee7446$], false, null),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 4, $q86eb64b4bb$Pedile a la IA que repita tus totales y que escriba la resta. No le pidas que busque otros números.$q86eb64b4bb$, null, array[$qefdda6c69d$La respuesta repite tus totales$qefdda6c69d$, $qa97f683be1$La resta está escrita$qa97f683be1$], true, $qfc2e92f861$Los totales los calculé yo y la respuesta no los cambió$qfc2e92f861$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 5, $q396d217bf0$Rehacé la resta a mano o en la planilla. Si no coincide, devolvé el error antes de leer cualquier consejo.$q396d217bf0$, null, array[$q1ba8bdcca3$Resta verificada$q1ba8bdcca3$], false, null),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 1, $q51624d0e9e$Elegí los pedidos de hoy o de ayer. No hace falta el historial entero.$q51624d0e9e$, null, array[$qcf3eb08474$Un recorte chico, no todo el mes$qcf3eb08474$], false, null),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 2, $q3e2cd92ee0$Copiá cada pedido en texto: canal, producto, cantidad y estado. Borrá direcciones si no las necesitás para armarlo.$q3e2cd92ee0$, null, array[$q61f21e6ff9$Canal$q61f21e6ff9$, $q2b1b0c89c7$Producto y cantidad$q2b1b0c89c7$, $q2d148c16fe$Sin datos de más$q2d148c16fe$], false, null),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 3, $q751172d060$Escribí los estados que de verdad usás. Si uno no existe, no lo agregues después en la tabla.$q751172d060$, null, array[$q1822fca9a2$Lista corta de estados$q1822fca9a2$], false, null),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 4, $qafc74c8283$Pedí la tabla y revisá una fila contra el mensaje original.$qafc74c8283$, null, array[$q75da05fcd6$Una fila comparada con el mensaje$q75da05fcd6$], true, $q3e04d49b8b$Revisé al menos un pedido contra el texto original$q3e04d49b8b$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 5, $q7ed0263714$Si aparece un duplicado o un estado vacío, decídilo vos antes de avisarle al cliente.$q7ed0263714$, null, array[$qc250b176c8$Duplicados marcados$qc250b176c8$, $q42ca9d8e70$Estados vacíos sin completar$q42ca9d8e70$], false, null)
on conflict (use_case_id, position) do update
  set body = excluded.body,
      example_prompt = excluded.example_prompt,
      checklist = excluded.checklist,
      requires_confirmation = excluded.requires_confirmation,
      confirmation_label = excluded.confirmation_label;
insert into public.use_case_challenges (use_case_id, position, type, title, instruction, scenario, question, feedback_correct, feedback_incorrect, xp) values
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 1, $q96d68805bb$detect_error$q96d68805bb$, $q7ceb980d7f$Detectá el error$q7ceb980d7f$, $q91586d3ae2$Este pedido supone que la IA puede ver la cuenta.$q91586d3ae2$, $qf4c781e7dc$Entrá a mi Instagram y decime cómo hacerla crecer.$qf4c781e7dc$, $q194570f535$¿Cuál es el principal problema de este pedido?$q194570f535$, $qd053ecc1aa$Bien. Nadie se conectó a la cuenta. Sin métricas del período, crecer es un consejo genérico.$qd053ecc1aa$, $q76ea1d4d48$No exactamente. El problema es que no hay números pegados y se pide un acceso que no existe.$q76ea1d4d48$, 10),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 2, $q05dd751210$missing_information$q05dd751210$, $q9407104cf0$Qué información falta$q9407104cf0$, $q11eb5176ca$Hay algunos números, pero todavía no se puede auditar el período.$q11eb5176ca$, $qbdf4356f29$Tuve 12.000 de alcance y 40 visitas al perfil. Decime si me fue bien.$qbdf4356f29$, $q56b5a0beab$¿Qué información importante falta?$q56b5a0beab$, $q5b0386f6aa$Exacto. Sin período ni objetivo, ese alcance no dice si el mes sirvió.$q5b0386f6aa$, $qe39af56b6c$No es el diseño del perfil. Falta el período y para qué querés la cuenta.$qe39af56b6c$, 10),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 3, $qf7f48ccb0d$judge_result$qf7f48ccb0d$, $q45f17a2486$Juzgá el resultado$q45f17a2486$, $q589a186633$El pedido no incluía el mes anterior.$q589a186633$, $qe6b3a82044$Pedido: Repetí solo estos números de los últimos 28 días: alcance 12.000, visitas al perfil 40. No compares con otro período.

Respuesta de la IA: Tu alcance subió 40% respecto del mes pasado. La cuenta está en crecimiento.$qe6b3a82044$, $q6f76740305$¿Qué problema tiene este resultado?$q6f76740305$, $q1566ef898b$Bien. Inventó una comparación con un mes que no estaba en los datos.$q1566ef898b$, $q761a401ab1$No está listo para usar. Ese 40% no sale de los números que se pegaron.$q761a401ab1$, 10),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 1, $q96d68805bb$detect_error$q96d68805bb$, $q7ceb980d7f$Detectá el error$q7ceb980d7f$, $q91e12095d7$Este pedido le deja la cuenta a la IA.$q91e12095d7$, $qe340ad0579$Mirá mis finanzas y decime si el negocio es rentable. Te paso luego los tickets.$qe340ad0579$, $q194570f535$¿Cuál es el principal problema de este pedido?$q194570f535$, $q61ebe59530$Bien. Sin totales calculados, cualquier margen que aparezca es una suposición.$q61ebe59530$, $qe505910f67$No exactamente. El problema es que todavía no hay números propios para interpretar.$qe505910f67$, 10),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 2, $q05dd751210$missing_information$q05dd751210$, $q9407104cf0$Qué información falta$q9407104cf0$, $q48b5ba714c$Hay una venta, pero no alcanza para el resultado del mes.$q48b5ba714c$, $qc9f20b7040$Este mes vendí $800.000. ¿Me fue bien?$qc9f20b7040$, $q56b5a0beab$¿Qué información importante falta?$q56b5a0beab$, $q9b0a98e5b2$Exacto. Sin los gastos y sin decir si ese número es lo cobrado, no hay resultado.$q9b0a98e5b2$, $qbc0cb3ceeb$No es el rubro. Faltan los gastos y saber qué representa esa venta.$qbc0cb3ceeb$, 10),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 3, $qf7f48ccb0d$judge_result$qf7f48ccb0d$, $q45f17a2486$Juzgá el resultado$q45f17a2486$, $qeafba5fe50$La persona ya había pasado los totales.$qeafba5fe50$, $q7d06688415$Pedido: Ventas del mes $800.000, gastos $650.000, ambos calculados por mí. Mostrá la resta. No uses otros números.

Respuesta de la IA: Tu margen real es 35% porque en este rubro se trabaja así. Conviene subir todos los precios un 10%.$q7d06688415$, $q6f76740305$¿Qué problema tiene este resultado?$q6f76740305$, $qbc56ea5e9c$Bien. Ignoró la resta pedida y trajo un margen que no sale de 800 menos 650.$qbc56ea5e9c$, $qdd128fc278$No está para usar. El 35% no es el resultado de los totales que se pasaron.$qdd128fc278$, 10),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 1, $q96d68805bb$detect_error$q96d68805bb$, $q7ceb980d7f$Detectá el error$q7ceb980d7f$, $qa3c0133d5d$Este pedido supone una conexión que no existe.$qa3c0133d5d$, $qd829acfb1f$Leé mis chats de WhatsApp y de Instagram y armame la lista de pedidos de hoy.$qd829acfb1f$, $q194570f535$¿Cuál es el principal problema de este pedido?$q194570f535$, $qcbdaefd463$Bien. Esos chats no están conectados. Hay que pegar los pedidos.$qcbdaefd463$, $q39a3b609cf$No exactamente. El problema es pedir un acceso a los canales en vez de pegar los pedidos.$q39a3b609cf$, 10),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 2, $q05dd751210$missing_information$q05dd751210$, $q9407104cf0$Qué información falta$q9407104cf0$, $q19c26a8639$Hay pedidos, pero la tabla puede inventar el estado.$q19c26a8639$, $q3eb6fcb69c$Tengo estos pedidos: Ana, 2 tortas, Instagram. Luis, 1 torta, WhatsApp. Organizalos.$q3eb6fcb69c$, $q56b5a0beab$¿Qué información importante falta?$q56b5a0beab$, $q5093cfb8ad$Exacto. Sin estados definidos, la IA puede darlos por listos o por entregados.$q5093cfb8ad$, $qec1356b847$No es el precio. Falta saber qué estados usás y cuál tiene cada pedido.$qec1356b847$, 10),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 3, $qf7f48ccb0d$judge_result$qf7f48ccb0d$, $q45f17a2486$Juzgá el resultado$q45f17a2486$, $qee8beed01d$El texto pegado decía que el pedido seguía pendiente.$qee8beed01d$, $q694b69493f$Pedido: Si no escribí el estado, poné SIN ESTADO. No lo completes.

Texto pegado: Canal WhatsApp. 1 torta. Sin estado.

Respuesta de la IA: Ese pedido ya figura como entregado porque los de WhatsApp suelen retirarse en el día.$q694b69493f$, $q6f76740305$¿Qué problema tiene este resultado?$q6f76740305$, $qc90d689e8d$Bien. Inventó el estado entregado. Había que dejar SIN ESTADO.$qc90d689e8d$, $qea5a0a0356$No está para usar. El estado no estaba en el pedido y la respuesta lo completó igual.$qea5a0a0356$, 10)
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
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 1, $q86f7e437fa$a$q86f7e437fa$, $qb6904b247d$Pide un acceso a Instagram que no existe y no trae métricas.$qb6904b247d$, true, $qd053ecc1aa$Bien. Nadie se conectó a la cuenta. Sin métricas del período, crecer es un consejo genérico.$qd053ecc1aa$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 1, $qe9d71f5ee7$b$qe9d71f5ee7$, $qc69703bd3a$Pide crecer demasiado rápido para una cuenta chica.$qc69703bd3a$, false, $q76ea1d4d48$No exactamente. El problema es que no hay números pegados y se pide un acceso que no existe.$q76ea1d4d48$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 1, $q84a516841b$c$q84a516841b$, $qd473f72132$Está bien si la cuenta es pública.$qd473f72132$, false, $q76ea1d4d48$No exactamente. El problema es que no hay números pegados y se pide un acceso que no existe.$q76ea1d4d48$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 2, $q86f7e437fa$a$q86f7e437fa$, $q986a829036$El período de esos números y qué tendría que haber pasado si a la cuenta le fue bien.$q986a829036$, true, $q5b0386f6aa$Exacto. Sin período ni objetivo, ese alcance no dice si el mes sirvió.$q5b0386f6aa$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 2, $qe9d71f5ee7$b$qe9d71f5ee7$, $q08ce765e7d$El filtro de color de las fotos.$q08ce765e7d$, false, $qe39af56b6c$No es el diseño del perfil. Falta el período y para qué querés la cuenta.$qe39af56b6c$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 2, $q84a516841b$c$q84a516841b$, $q1ab0ef5941$La cantidad de emojis del nombre.$q1ab0ef5941$, false, $qe39af56b6c$No es el diseño del perfil. Falta el período y para qué querés la cuenta.$qe39af56b6c$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 3, $q86f7e437fa$a$q86f7e437fa$, $q487882252c$Comparó con un mes anterior que nadie informó.$q487882252c$, true, $q1566ef898b$Bien. Inventó una comparación con un mes que no estaba en los datos.$q1566ef898b$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 3, $qe9d71f5ee7$b$qe9d71f5ee7$, $q5a3beed3c2$El alcance de 12.000 es demasiado bajo para analizar.$q5a3beed3c2$, false, $q761a401ab1$No está listo para usar. Ese 40% no sale de los números que se pegaron.$q761a401ab1$),
  ($q705ba215c5$auditoria-instagram$q705ba215c5$, 3, $q84a516841b$c$q84a516841b$, $q5628acf625$Está bien porque 12.000 suena a un buen número.$q5628acf625$, false, $q761a401ab1$No está listo para usar. Ese 40% no sale de los números que se pegaron.$q761a401ab1$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 1, $q86f7e437fa$a$q86f7e437fa$, $q63e3181b13$Pide un diagnóstico sin totales que la persona haya calculado.$q63e3181b13$, true, $q61ebe59530$Bien. Sin totales calculados, cualquier margen que aparezca es una suposición.$q61ebe59530$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 1, $qe9d71f5ee7$b$qe9d71f5ee7$, $qb7bc3496d2$Habla de rentabilidad, que es un tema demasiado avanzado.$qb7bc3496d2$, false, $qe505910f67$No exactamente. El problema es que todavía no hay números propios para interpretar.$qe505910f67$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 1, $q84a516841b$c$q84a516841b$, $qddc813a5dd$Está bien porque la IA puede estimar un margen típico del rubro.$qddc813a5dd$, false, $qe505910f67$No exactamente. El problema es que todavía no hay números propios para interpretar.$qe505910f67$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 2, $q86f7e437fa$a$q86f7e437fa$, $qd0d3006fc9$Los gastos del mismo período y si los $800.000 ya se cobraron.$qd0d3006fc9$, true, $q9b0a98e5b2$Exacto. Sin los gastos y sin decir si ese número es lo cobrado, no hay resultado.$q9b0a98e5b2$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 2, $qe9d71f5ee7$b$qe9d71f5ee7$, $qbb0ae5ad4e$El logo del negocio para el informe.$qbb0ae5ad4e$, false, $qbc0cb3ceeb$No es el rubro. Faltan los gastos y saber qué representa esa venta.$qbc0cb3ceeb$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 2, $q84a516841b$c$q84a516841b$, $q8af71bddca$Una proyección a cinco años.$q8af71bddca$, false, $qbc0cb3ceeb$No es el rubro. Faltan los gastos y saber qué representa esa venta.$qbc0cb3ceeb$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 3, $q86f7e437fa$a$q86f7e437fa$, $q1a9c258363$Reemplazó la cuenta pedida por un margen que no sale de esos totales.$q1a9c258363$, true, $qbc56ea5e9c$Bien. Ignoró la resta pedida y trajo un margen que no sale de 800 menos 650.$qbc56ea5e9c$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 3, $qe9d71f5ee7$b$qe9d71f5ee7$, $qab2c3b39f5$El 10% de aumento es obligatorio en cualquier diagnóstico.$qab2c3b39f5$, false, $qdd128fc278$No está para usar. El 35% no es el resultado de los totales que se pasaron.$qdd128fc278$),
  ($q4a447ba538$diagnostico-financiero$q4a447ba538$, 3, $q84a516841b$c$q84a516841b$, $q7b954036d9$Está bien porque 35% es un margen sano.$q7b954036d9$, false, $qdd128fc278$No está para usar. El 35% no es el resultado de los totales que se pasaron.$qdd128fc278$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 1, $q86f7e437fa$a$q86f7e437fa$, $qf5964bd197$Pide leer chats a los que la herramienta no está conectada.$qf5964bd197$, true, $qcbdaefd463$Bien. Esos chats no están conectados. Hay que pegar los pedidos.$qcbdaefd463$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 1, $qe9d71f5ee7$b$qe9d71f5ee7$, $qa72b1b261c$Mezcla dos canales y eso siempre es un error.$qa72b1b261c$, false, $q39a3b609cf$No exactamente. El problema es pedir un acceso a los canales en vez de pegar los pedidos.$q39a3b609cf$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 1, $q84a516841b$c$q84a516841b$, $q07c97b907b$Está bien si el celular está cerca.$q07c97b907b$, false, $q39a3b609cf$No exactamente. El problema es pedir un acceso a los canales en vez de pegar los pedidos.$q39a3b609cf$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 2, $q86f7e437fa$a$q86f7e437fa$, $q7b7aa48587$Qué estados existen y en cuál está cada pedido.$q7b7aa48587$, true, $q5093cfb8ad$Exacto. Sin estados definidos, la IA puede darlos por listos o por entregados.$q5093cfb8ad$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 2, $qe9d71f5ee7$b$qe9d71f5ee7$, $q995fc30758$El color de la tabla.$q995fc30758$, false, $qec1356b847$No es el precio. Falta saber qué estados usás y cuál tiene cada pedido.$qec1356b847$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 2, $q84a516841b$c$q84a516841b$, $q69995c8d5f$La receta de la torta.$q69995c8d5f$, false, $qec1356b847$No es el precio. Falta saber qué estados usás y cuál tiene cada pedido.$qec1356b847$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 3, $q86f7e437fa$a$q86f7e437fa$, $q71c482943e$Completó un estado que el pedido decía no inventar.$q71c482943e$, true, $qc90d689e8d$Bien. Inventó el estado entregado. Había que dejar SIN ESTADO.$qc90d689e8d$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 3, $qe9d71f5ee7$b$qe9d71f5ee7$, $q1d2fba00dc$Usó WhatsApp, y ese canal no se puede anotar.$q1d2fba00dc$, false, $qea5a0a0356$No está para usar. El estado no estaba en el pedido y la respuesta lo completó igual.$qea5a0a0356$),
  ($qf6b2fcf07a$pedidos-multicanal$qf6b2fcf07a$, 3, $q84a516841b$c$q84a516841b$, $q0f215c4a44$Está bien asumir que ya se retiró.$q0f215c4a44$, false, $qea5a0a0356$No está para usar. El estado no estaba en el pedido y la respuesta lo completó igual.$qea5a0a0356$)
on conflict (use_case_id, position, letter) do update
  set body = excluded.body,
      is_correct = excluded.is_correct,
      feedback = excluded.feedback;

-- Area y etiquetas de matching de los ocho casos con practica del Sprint 2.
-- Sin esto el ranking no los puede recomendar y no aparecen al filtrar por
-- area. estudiar-material queda sin area porque sirve en cualquiera.
-- Se puede correr suelto sobre una base que ya tiene el catalogo.
update public.use_cases as u
   set area = v.area
  from (values
    ('ventas-sin-formulas', 'finanzas'),
    ('reporte-campania', 'marketing'),
    ('reunion-seguimiento', 'administracion'),
    ('documento-presentacion', 'marketing'),
    ('imagenes-redes', 'marketing'),
    ('automatizar-tarea', 'administracion'),
    ('comparar-decidir', 'administracion')
  ) as v (id, area)
 where u.id = v.id;

insert into public.use_case_tags (use_case_id, kind, value) values
  ('ventas-sin-formulas', 'area', 'finanzas'),
  ('ventas-sin-formulas', 'problem', 'entender_ventas'),
  ('ventas-sin-formulas', 'problem', 'cobrar_a_tiempo'),
  ('ventas-sin-formulas', 'goal', 'ordenar_finanzas'),
  ('ventas-sin-formulas', 'tool', 'excel'),
  ('ventas-sin-formulas', 'tool', 'google_sheets'),
  ('ventas-sin-formulas', 'experience', 'alguna_vez'),
  ('ventas-sin-formulas', 'time', 'de_15_a_30'),

  ('reporte-campania', 'area', 'marketing'),
  ('reporte-campania', 'problem', 'medir_resultados'),
  ('reporte-campania', 'problem', 'decidir_con_informacion'),
  ('reporte-campania', 'goal', 'mejorar_comunicacion'),
  ('reporte-campania', 'tool', 'chatgpt'),
  ('reporte-campania', 'tool', 'google_sheets'),
  ('reporte-campania', 'experience', 'alguna_vez'),
  ('reporte-campania', 'time', 'de_15_a_30'),

  ('reunion-seguimiento', 'area', 'administracion'),
  ('reunion-seguimiento', 'problem', 'preparar_reuniones'),
  ('reunion-seguimiento', 'problem', 'hacer_seguimiento'),
  ('reunion-seguimiento', 'problem', 'atender_clientes'),
  ('reunion-seguimiento', 'goal', 'ordenar_operacion'),
  ('reunion-seguimiento', 'tool', 'chatgpt'),
  ('reunion-seguimiento', 'tool', 'gemini'),
  ('reunion-seguimiento', 'experience', 'alguna_vez'),
  ('reunion-seguimiento', 'time', 'de_15_a_30'),

  ('estudiar-material', 'problem', 'empezar_sin_experiencia'),
  ('estudiar-material', 'problem', 'decidir_con_informacion'),
  ('estudiar-material', 'goal', 'ahorrar_tiempo'),
  ('estudiar-material', 'tool', 'notebooklm'),
  ('estudiar-material', 'tool', 'chatgpt'),
  ('estudiar-material', 'experience', 'nunca'),
  ('estudiar-material', 'time', 'de_15_a_30'),

  ('documento-presentacion', 'area', 'marketing'),
  ('documento-presentacion', 'problem', 'explicar_oferta'),
  ('documento-presentacion', 'problem', 'preparar_reuniones'),
  ('documento-presentacion', 'goal', 'mejorar_comunicacion'),
  ('documento-presentacion', 'tool', 'chatgpt'),
  ('documento-presentacion', 'tool', 'copilot'),
  ('documento-presentacion', 'experience', 'alguna_vez'),
  ('documento-presentacion', 'time', 'de_15_a_30'),

  ('imagenes-redes', 'area', 'marketing'),
  ('imagenes-redes', 'problem', 'publicar_en_redes'),
  ('imagenes-redes', 'problem', 'crear_contenido'),
  ('imagenes-redes', 'goal', 'conseguir_clientes'),
  ('imagenes-redes', 'tool', 'chatgpt'),
  ('imagenes-redes', 'tool', 'canva'),
  ('imagenes-redes', 'tool', 'instagram'),
  ('imagenes-redes', 'experience', 'alguna_vez'),
  ('imagenes-redes', 'time', 'de_15_a_30'),

  ('automatizar-tarea', 'area', 'administracion'),
  ('automatizar-tarea', 'problem', 'ahorrar_tiempo_repetitivo'),
  ('automatizar-tarea', 'problem', 'empezar_sin_experiencia'),
  ('automatizar-tarea', 'goal', 'ahorrar_tiempo'),
  ('automatizar-tarea', 'tool', 'google_sheets'),
  ('automatizar-tarea', 'tool', 'chatgpt'),
  ('automatizar-tarea', 'experience', 'seguido'),
  ('automatizar-tarea', 'time', 'de_30_a_60'),

  ('comparar-decidir', 'area', 'administracion'),
  ('comparar-decidir', 'problem', 'decidir_con_informacion'),
  ('comparar-decidir', 'goal', 'tomar_decisiones'),
  ('comparar-decidir', 'tool', 'chatgpt'),
  ('comparar-decidir', 'tool', 'gemini'),
  ('comparar-decidir', 'experience', 'alguna_vez'),
  ('comparar-decidir', 'time', 'de_15_a_30')
on conflict (use_case_id, kind, value) do nothing;
