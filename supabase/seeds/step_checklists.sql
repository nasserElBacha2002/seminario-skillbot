-- Completa los checklists de cada paso. Pegalo en el SQL Editor si el seed
-- original quedó con arrays vacíos.

update public.use_case_steps set checklist = array['Solo encabezados','Hasta 10 filas de ejemplo','Sin datos sensibles']
  where use_case_id = 'ventas-sin-formulas' and position = 2;
update public.use_case_steps set checklist = array['Objetivo en castellano','Columnas nombradas','Herramienta (Sheets o Excel)']
  where use_case_id = 'ventas-sin-formulas' and position = 3;
update public.use_case_steps set checklist = array['Explicación en una línea','Dónde pegar la fórmula']
  where use_case_id = 'ventas-sin-formulas' and position = 4;
update public.use_case_steps set checklist = array['3 filas cuyo resultado ya conocés','Si no coincide, devolvê el error textual']
  where use_case_id = 'ventas-sin-formulas' and position = 5;
update public.use_case_steps set checklist = array['3 hallazgos','Un gráfico recomendado']
  where use_case_id = 'ventas-sin-formulas' and position = 6;

update public.use_case_steps set checklist = array['CSV o planilla exportada','Columnas que no hacen falta, afuera']
  where use_case_id = 'reporte-campania' and position = 1;
update public.use_case_steps set checklist = array['Pedí análisis, no el texto final','Costo por conversión de cada anuncio']
  where use_case_id = 'reporte-campania' and position = 2;
update public.use_case_steps set checklist = array['2 o 3 cuentas a mano','Compará contra la planilla']
  where use_case_id = 'reporte-campania' and position = 3;
update public.use_case_steps set checklist = array['Quién lee el informe','Sin siglas si no las conoce']
  where use_case_id = 'reporte-campania' and position = 4;
update public.use_case_steps set checklist = array['Resumen en 3 líneas','Qué funcionó y qué no','3 acciones para el mes que viene']
  where use_case_id = 'reporte-campania' and position = 5;
update public.use_case_steps set checklist = array['Tabla para pegar en el control']
  where use_case_id = 'reporte-campania' and position = 6;
update public.use_case_steps set checklist = array['Tono del lector','Exportar a Word o PDF']
  where use_case_id = 'reporte-campania' and position = 7;

update public.use_case_steps set checklist = array['Una sola fuente','Si hay grabación, avisá a los participantes']
  where use_case_id = 'reunion-seguimiento' and position = 1;
update public.use_case_steps set checklist = array['Precios internos afuera','Datos personales afuera']
  where use_case_id = 'reunion-seguimiento' and position = 2;
update public.use_case_steps set checklist = array['Decisiones','Tareas con quién y para cuándo','Si falta un dato: A CONFIRMAR']
  where use_case_id = 'reunion-seguimiento' and position = 3;
update public.use_case_steps set checklist = array['Cada tarea con responsable','Cada tarea con fecha']
  where use_case_id = 'reunion-seguimiento' and position = 4;
update public.use_case_steps set checklist = array['Mail cordial','Alrededor de 120 palabras']
  where use_case_id = 'reunion-seguimiento' and position = 5;
update public.use_case_steps set checklist = array['Tabla lista para la planilla de seguimiento']
  where use_case_id = 'reunion-seguimiento' and position = 6;
update public.use_case_steps set checklist = array['Leé todo antes de enviar']
  where use_case_id = 'reunion-seguimiento' and position = 7;

update public.use_case_steps set checklist = array['PDF como fuente','No pegues texto suelto']
  where use_case_id = 'estudiar-material' and position = 1;
update public.use_case_steps set checklist = array['8 temas principales','De lo básico a lo complejo']
  where use_case_id = 'estudiar-material' and position = 2;
update public.use_case_steps set checklist = array['Un tema por vez','Un ejemplo concreto']
  where use_case_id = 'estudiar-material' and position = 3;
update public.use_case_steps set checklist = array['10 preguntas','Respondelas sin mirar']
  where use_case_id = 'estudiar-material' and position = 4;
update public.use_case_steps set checklist = array['Plazo del examen','Horas por día','Repaso incluido']
  where use_case_id = 'estudiar-material' and position = 5;
update public.use_case_steps set checklist = array['Al menos una cita contra la fuente']
  where use_case_id = 'estudiar-material' and position = 6;

update public.use_case_steps set checklist = array['Quién escucha','Cuántos minutos hay']
  where use_case_id = 'documento-presentacion' and position = 1;
update public.use_case_steps set checklist = array['Esquema en texto','Máximo 3 ideas por diapositiva']
  where use_case_id = 'documento-presentacion' and position = 2;
update public.use_case_steps set checklist = array['Sacá, juntá o reordená','Todavía no diseñes']
  where use_case_id = 'documento-presentacion' and position = 3;
update public.use_case_steps set checklist = array['Usá el esquema ya corregido']
  where use_case_id = 'documento-presentacion' and position = 4;
update public.use_case_steps set checklist = array['Notas del orador por diapositiva']
  where use_case_id = 'documento-presentacion' and position = 5;
update public.use_case_steps set checklist = array['Cifras contra el informe','Nombres contra el informe']
  where use_case_id = 'documento-presentacion' and position = 6;

update public.use_case_steps set checklist = array['Formato (cuadrado o vertical)','Dónde se publica','Qué tiene que transmitir']
  where use_case_id = 'imagenes-redes' and position = 1;
update public.use_case_steps set checklist = array['Sujeto','Escenario y luz','Estilo y colores','Qué evitar']
  where use_case_id = 'imagenes-redes' and position = 2;
update public.use_case_steps set checklist = array['Foto real del producto o una referencia']
  where use_case_id = 'imagenes-redes' and position = 3;
update public.use_case_steps set checklist = array['Tres variantes','Cambiá una sola cosa por vez']
  where use_case_id = 'imagenes-redes' and position = 4;
update public.use_case_steps set checklist = array['Manos','Texto raro','Detalles que delatan a la IA']
  where use_case_id = 'imagenes-redes' and position = 5;
update public.use_case_steps set checklist = array['Texto y logo en la herramienta de diseño']
  where use_case_id = 'imagenes-redes' and position = 6;

update public.use_case_steps set checklist = array['Qué planilla','Qué se copia','A dónde y cuándo']
  where use_case_id = 'automatizar-tarea' and position = 1;
update public.use_case_steps set checklist = array['Aclará que no sabés programar','Pedí dónde pegarlo, paso a paso']
  where use_case_id = 'automatizar-tarea' and position = 2;
update public.use_case_steps set checklist = array['Copia de la planilla','Nunca el archivo real']
  where use_case_id = 'automatizar-tarea' and position = 3;
update public.use_case_steps set checklist = array['Error completo, sin recortar']
  where use_case_id = 'automatizar-tarea' and position = 4;
update public.use_case_steps set checklist = array['Qué hace el script en 3 líneas','Qué permisos pide']
  where use_case_id = 'automatizar-tarea' and position = 5;
update public.use_case_steps set checklist = array['Disparador de tiempo','Comprobá la primera ejecución']
  where use_case_id = 'automatizar-tarea' and position = 6;

update public.use_case_steps set checklist = array['Qué decisión','Criterios: precio, soporte, facilidad, integraciones']
  where use_case_id = 'comparar-decidir' and position = 1;
update public.use_case_steps set checklist = array['Búsqueda web activada','Fuente de cada dato']
  where use_case_id = 'comparar-decidir' and position = 2;
update public.use_case_steps set checklist = array['Abrí al menos dos enlaces','Comprobá que el dato esté']
  where use_case_id = 'comparar-decidir' and position = 3;
update public.use_case_steps set checklist = array['Misma tabla, mismos criterios del paso 1']
  where use_case_id = 'comparar-decidir' and position = 4;
update public.use_case_steps set checklist = array['Una recomendación','Qué podría salir mal']
  where use_case_id = 'comparar-decidir' and position = 5;
update public.use_case_steps set checklist = array['Segunda IA','Si difieren, investigá ese punto']
  where use_case_id = 'comparar-decidir' and position = 6;
