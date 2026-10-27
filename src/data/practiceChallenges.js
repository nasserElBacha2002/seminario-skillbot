// Tres desafíos fijos por caso. El componente solo los renderiza.
// Se usan mientras la base no tenga la migración de práctica; el seed replica este contenido.

export const practiceFieldKeys = {
  'ventas-sin-formulas': ['objetivo', 'columnas', 'herramienta'],
  'reporte-campania': ['datos', 'lector', 'objetivo'],
  'reunion-seguimiento': ['fuente', 'contexto', 'incluir'],
  'estudiar-material': ['material', 'plazo', 'tiempo_diario'],
  'documento-presentacion': ['tema', 'audiencia', 'duracion'],
  'imagenes-redes': ['producto', 'formato', 'uso'],
  'automatizar-tarea': ['tarea', 'origen', 'cuando'],
  'comparar-decidir': ['decision', 'opciones', 'criterios'],
}

export const practiceKeys = {
  'ventas-sin-formulas': [
    'Explicá qué columnas tiene la planilla.',
    'Decí qué querés obtener, no la fórmula.',
    'No pegues nombres, mails ni datos bancarios.',
    'Pedí que explique el resultado y verificá con filas que ya conocés.',
  ],
  'reporte-campania': [
    'Separá el análisis de la redacción.',
    'Decí quién lee el informe y qué decisión tiene que tomar.',
    'No pidas conclusiones que los números no sostienen.',
    'Verificá las cifras contra la planilla original.',
  ],
  'reunion-seguimiento': [
    'Pedí un formato fijo: decisiones, tareas y pendientes.',
    'Si falta un responsable o una fecha, que lo marque y no lo invente.',
    'Usá una sola fuente, no mezcles recuerdos sueltos.',
    'Revisá que cada tarea haya sido dicha en la reunión.',
  ],
  'estudiar-material': [
    'Trabajá sobre tu material, no sobre lo que la IA cree saber.',
    'Pedí primero un mapa de temas, de lo básico a lo complejo.',
    'Decí el plazo y cuánto tiempo tenés por día.',
    'Si un dato no está en el material, la respuesta tiene que decirlo.',
  ],
  'documento-presentacion': [
    'Primero el contenido, después el diseño.',
    'Definí audiencia y tiempo antes de pedir diapositivas.',
    'Limitá las ideas por diapositiva.',
    'No dejes que copie cifras que no están en el informe.',
  ],
  'imagenes-redes': [
    'Describí sujeto, escenario, luz y estilo.',
    'Decí el formato y dónde se va a publicar.',
    'Pedí que no ponga texto ni logos dentro de la imagen.',
    'Cambiá una sola cosa entre variantes.',
  ],
  'automatizar-tarea': [
    'Describí la tarea repetitiva, no el código.',
    'Decí de dónde salen los datos y a dónde tienen que ir.',
    'Probalo siempre en una copia, nunca en el archivo real.',
    'Pedí que explique qué hace antes de darle permisos.',
  ],
  'comparar-decidir': [
    'Definí los criterios antes de pedir una recomendación.',
    'Pedí la fuente de cada dato.',
    'Sin búsqueda, los precios y las funciones pueden estar viejos.',
    'Contrastá la recomendación: una respuesta segura no alcanza.',
  ],
}

function round(position, type, title, instruction, scenario, question, correct, wrong, choices) {
  return {
    position,
    type,
    title,
    instruction,
    scenario,
    question,
    feedbackCorrect: correct,
    feedbackIncorrect: wrong,
    xp: 10,
    options: choices.map(([letter, body, ok]) => ({
      letter,
      body,
      is_correct: ok,
      feedback: ok ? correct : wrong,
    })),
  }
}

export const practiceChallenges = {
  'ventas-sin-formulas': [
    round(1, 'detect_error', 'Detectá el error', 'Mirá este pedido y encontrá qué lo hace difícil de responder.', 'Analizá este Excel y decime quién debe.', '¿Cuál es el principal problema de este pedido?', 'Bien. El pedido explica la intención, pero no aclara qué datos existen ni qué significa “debe”.', 'No exactamente. El problema principal es que falta contexto para que la IA pueda interpretar la planilla.', [
      ['a', 'Falta contexto sobre los datos y el resultado esperado.', true],
      ['b', 'Tiene demasiados detalles.', false],
      ['c', 'Está bien así.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Este pedido ya tiene algo de contexto, pero todavía no se puede resolver bien.', 'Tengo una planilla de ventas con columnas Cliente y Monto. Quiero saber quién debe.', '¿Qué información importante falta?', 'Exacto. Sin una regla clara, la IA no sabe cómo decidir qué cliente está en deuda.', 'No es eso. Lo que falta es una regla para decidir la deuda, por ejemplo más de 30 días.', [
      ['a', 'Definir qué significa estar en deuda, por ejemplo más de 30 días.', true],
      ['b', 'Agregar un saludo.', false],
      ['c', 'Pedir una respuesta más larga.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'Leíste el pedido y la respuesta. No alcanza con que suene convincente.', 'Pedido: Identificá clientes con más de 30 días de deuda.\n\nRespuesta de la IA: Juan Pérez debe $150.000 y María Gómez $90.000.', '¿Qué problema tiene este resultado?', 'Bien. Una respuesta puede sonar convincente y aun así contener información inventada. Siempre hay que verificarla contra la fuente original.', 'No exactamente. Esos nombres y montos no estaban en los datos. La IA los inventó, aunque suene segura.', [
      ['a', 'Inventó datos que no estaban en la información.', true],
      ['b', 'La respuesta es demasiado corta.', false],
      ['c', 'Está bien y puede usarse directamente.', false],
    ]),
  ],
  'reporte-campania': [
    round(1, 'detect_error', 'Detectá el error', 'Este pedido pide el informe de una sola vez.', 'Hacé un informe profesional de la campaña, con mucho detalle.', '¿Cuál es el principal problema de este pedido?', 'Bien. No dice quién lo lee ni pide primero los números. Para que el texto suene redondo, la IA puede inventar conclusiones.', 'No exactamente. El problema es que mezcla todo y no define al lector ni qué hay que verificar.', [
      ['a', 'No dice quién lo lee y mezcla análisis con redacción.', true],
      ['b', 'El pedido es demasiado corto para una campaña.', false],
      ['c', 'Está bien si después se corrige el diseño.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya hay datos, pero el pedido sigue incompleto.', 'Con estos números de impresiones, clics y gasto, escribí el informe de la campaña.', '¿Qué información importante falta?', 'Exacto. Sin saber quién decide y qué tiene que poder hacer después de leer, el informe queda genérico.', 'No es el tono. Falta decir quién lee y qué decisión tiene que tomar.', [
      ['a', 'Quién lee el informe y qué decisión tiene que tomar.', true],
      ['b', 'Un saludo inicial más formal.', false],
      ['c', 'Pedir más adjetivos profesionales.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'Compará el pedido con lo que respondió la IA.', 'Pedido: Calculá el costo por conversión y listá los 3 mejores y los 3 peores anuncios. No redactes conclusiones todavía.\n\nRespuesta de la IA: La campaña fue un éxito y conviene duplicar el presupuesto del anuncio principal.', '¿Qué problema tiene este resultado?', 'Bien. No mostró los números pedidos y cerró con una conclusión que los datos todavía no sostienen.', 'No es la longitud. El problema es que ignoró el pedido y sacó una conclusión sin mostrar las cifras.', [
      ['a', 'Sacó una conclusión que el pedido no pedía y no mostró los números.', true],
      ['b', 'La respuesta es demasiado corta.', false],
      ['c', 'Está bien porque suena decidida.', false],
    ]),
  ],
  'reunion-seguimiento': [
    round(1, 'detect_error', 'Detectá el error', 'Este pedido es el típico resumen suelto.', 'Resumime la reunión.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin un formato, la IA completa responsables o fechas que nadie dijo.', 'No exactamente. El problema es que no fija qué hay que extraer ni qué hacer cuando falta un dato.', [
      ['a', 'No pide un formato y deja que la IA complete huecos.', true],
      ['b', 'Pide demasiados detalles de una sola reunión.', false],
      ['c', 'Está bien para una minuta.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'El pedido ya pide una minuta, pero empuja a inventar.', 'Armá una minuta con todas las tareas asignadas a alguien y con su fecha.', '¿Qué información importante falta?', 'Exacto. Hay que decir qué hacer cuando nadie nombró al responsable o la fecha: marcarlo, no inventarlo.', 'No es la extensión. Falta la regla para los datos que la reunión no dijo.', [
      ['a', 'Indicar que, si falta un dato, se escriba A CONFIRMAR y no se invente.', true],
      ['b', 'Pedir un tono más cordial.', false],
      ['c', 'Agregar una frase de cierre motivadora.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'En la reunión no se nombró al responsable de la propuesta.', 'Pedido: Armá las tareas. Si falta un responsable o una fecha, escribí A CONFIRMAR.\n\nRespuesta de la IA: Ana envía la propuesta el viernes 18.', '¿Qué problema tiene este resultado?', 'Bien. La IA inventó un responsable y una fecha que nadie dijo. Había que dejar A CONFIRMAR.', 'No está bien usarla así. Ese responsable y esa fecha no salieron de la reunión.', [
      ['a', 'Inventó un responsable y una fecha que no estaban en la fuente.', true],
      ['b', 'La minuta quedó demasiado ordenada.', false],
      ['c', 'Está bien porque una minuta tiene que quedar completa.', false],
    ]),
  ],
  'estudiar-material': [
    round(1, 'detect_error', 'Detectá el error', 'Este es el pedido más común y el menos útil.', 'Resumime todo.', '¿Cuál es el principal problema de este pedido?', 'Bien. Un pedido gigante, sin fuentes ni orden, da un resumen que no podés verificar.', 'No exactamente. El problema es que no apoya la respuesta en tu material ni pide un recorrido para estudiar.', [
      ['a', 'No usa tu material ni dice cómo querés estudiar.', true],
      ['b', 'Pide un resumen demasiado detallado.', false],
      ['c', 'Está bien para empezar un parcial.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya mencionás los PDF, pero la IA todavía no puede armar un plan.', 'Resumí estos tres PDF y decime qué estudiar.', '¿Qué información importante falta?', 'Exacto. Sin plazo, tiempo por día y nivel de partida, el plan no entra en tu semana.', 'No es el formato del archivo. Faltan el plazo, el tiempo diario y desde dónde partís.', [
      ['a', 'El plazo, el tiempo por día y desde qué nivel partís.', true],
      ['b', 'El nombre del profesor.', false],
      ['c', 'Pedir que la respuesta sea más larga.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'El material no menciona ese tema.', 'Pedido: Armá el mapa solo con temas que estén en los PDF. Si algo no está, decilo.\n\nRespuesta de la IA: También tenés que estudiar modelos de regresión logística, que suelen entrar en este examen.', '¿Qué problema tiene este resultado?', 'Bien. Agregó un tema que no estaba en tus documentos. Hay que estudiar lo que está en la fuente.', 'No es que sea breve. El problema es que sumó un tema que tus PDF no traen.', [
      ['a', 'Agregó un tema que no estaba en el material.', true],
      ['b', 'La lista de temas es demasiado corta.', false],
      ['c', 'Está bien porque completa lo que falta del programa.', false],
    ]),
  ],
  'documento-presentacion': [
    round(1, 'detect_error', 'Detectá el error', 'Este pedido pide diseño y contenido al mismo tiempo.', 'Hacé una presentación completa y linda con este informe.', '¿Cuál es el principal problema de este pedido?', 'Bien. Pedir todo junto da diapositivas vistosas, con texto de más y cifras mal copiadas.', 'No exactamente. El problema es pedir el diseño antes de fijar audiencia, tiempo y contenido.', [
      ['a', 'Pide la presentación completa sin definir audiencia, tiempo ni contenido.', true],
      ['b', 'Incluye demasiadas restricciones de diseño.', false],
      ['c', 'Está bien si el informe ya está escrito.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya dice para quién es, pero todavía falta acotar.', 'Convertí este informe en diapositivas para directivos.', '¿Qué información importante falta?', 'Exacto. Sin el tiempo y un límite de ideas, la IA mete el informe entero en las diapositivas.', 'No es el color. Faltan la duración y un tope de ideas por diapositiva.', [
      ['a', 'Cuánto dura la presentación y cuántas ideas van por diapositiva.', true],
      ['b', 'El color de fondo de las diapositivas.', false],
      ['c', 'Una frase de agradecimiento final.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'El informe no trae esa cifra.', 'Pedido: Armá el esquema solo con datos del informe. Si falta un número, escribí A CONFIRMAR.\n\nRespuesta de la IA: Las ventas crecieron 18% y el directorio ya aprobó el presupuesto.', '¿Qué problema tiene este resultado?', 'Bien. Inventó una cifra y una decisión que no estaban en el informe.', 'No está lista para usar. Esa cifra y esa aprobación no salen del documento.', [
      ['a', 'Inventó una cifra y una decisión que no estaban en el informe.', true],
      ['b', 'El esquema tiene pocos títulos.', false],
      ['c', 'Está bien porque una presentación tiene que cerrar con un dato fuerte.', false],
    ]),
  ],
  'imagenes-redes': [
    round(1, 'detect_error', 'Detectá el error', 'Con este pedido la IA elige todo por su cuenta.', 'Una imagen linda de miel.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin sujeto, escena, luz ni restricciones, el resultado sale genérico y se nota que es IA.', 'No exactamente. El problema es que no describe la imagen ni dice qué hay que evitar.', [
      ['a', 'No describe la imagen ni qué hay que evitar.', true],
      ['b', 'Pide demasiados estilos a la vez.', false],
      ['c', 'Está bien porque la IA sabe cómo se ve una publicidad.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya está el producto, pero el pedido sigue abierto.', 'Foto de un frasco de miel artesanal para Instagram.', '¿Qué información importante falta?', 'Exacto. Falta el formato y, sobre todo, pedir que no escriba texto ni ponga el logo dentro de la imagen.', 'No es el eslogan. Falta el formato y la restricción de no poner texto ni logo en la imagen.', [
      ['a', 'El formato y pedir que no haya texto ni logo dentro de la imagen.', true],
      ['b', 'Un eslogan más creativo.', false],
      ['c', 'Pedir que la imagen sea más brillante.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'El pedido pedía una imagen sin texto.', 'Pedido: Frasco de miel, luz natural, sin texto ni logos.\n\nRespuesta de la IA: Generé el frasco con el texto “50% OFF” en letras doradas sobre la etiqueta.', '¿Qué problema tiene este resultado?', 'Bien. Ignoró la restricción y metió texto en la imagen, que suele salir deformado.', 'No está bien usarla. El pedido decía sin texto y la respuesta lo agregó igual.', [
      ['a', 'Ignoró la restricción y puso texto dentro de la imagen.', true],
      ['b', 'La descripción es demasiado concreta.', false],
      ['c', 'Está bien porque el texto ayuda a vender.', false],
    ]),
  ],
  'automatizar-tarea': [
    round(1, 'detect_error', 'Detectá el error', 'Este plan salta la prueba.', 'Hacé un script que copie los pedidos y lo ejecuto en la planilla real.', '¿Cuál es el principal problema de este pedido?', 'Bien. Ejecutarlo en el archivo real puede pisar datos. Primero hay que describir la tarea y probar en una copia.', 'No exactamente. El riesgo es correr el script sobre los datos reales sin una prueba.', [
      ['a', 'Propone ejecutarlo en los datos reales, sin prueba ni explicación.', true],
      ['b', 'Pide un script demasiado simple.', false],
      ['c', 'Está bien si la tarea es repetitiva.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya se sabe que hay un script, pero no cómo probarlo.', 'Escribí un script que pase los pedidos de una planilla a otra.', '¿Qué información importante falta?', 'Exacto. Falta decir que se prueba en una copia y pedir una explicación de qué va a hacer antes de darle permisos.', 'No es el lenguaje. Falta la prueba en una copia y saber qué hace el script.', [
      ['a', 'Probarlo en una copia y pedir que explique qué hace.', true],
      ['b', 'Elegir un nombre más corto para el archivo.', false],
      ['c', 'Pedir que el código sea más largo.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'Todavía no autorizaste nada sobre el archivo real.', 'Pedido: Explicá el script y decime cómo probarlo en una copia.\n\nRespuesta de la IA: Ya lo ejecuté sobre tu planilla real y actualicé 240 filas.', '¿Qué problema tiene este resultado?', 'Bien. Dice que modificó el archivo real, que era justo lo que había que evitar, y no podés confiar en esa afirmación.', 'No está resuelto. La respuesta se salta la copia y afirma que ya tocó los datos reales.', [
      ['a', 'Afirma que ya modificó el archivo real, en contra de lo pedido.', true],
      ['b', 'La explicación tiene pocos pasos.', false],
      ['c', 'Está bien porque así se ahorra tiempo.', false],
    ]),
  ],
  'comparar-decidir': [
    round(1, 'detect_error', 'Detectá el error', 'Este pedido pide un ganador sin criterios.', 'Decime cuál de las tres opciones es la mejor.', '¿Cuál es el principal problema de este pedido?', 'Bien. Sin criterios ni fuentes, “la mejor” es una opinión que no podés justificar.', 'No exactamente. El problema es que no define cómo comparar ni pide de dónde sale cada dato.', [
      ['a', 'No define criterios ni pide fuentes.', true],
      ['b', 'Compara demasiadas opciones a la vez.', false],
      ['c', 'Está bien si la IA tiene búsqueda.', false],
    ]),
    round(2, 'missing_information', 'Qué información falta', 'Ya hay criterios, pero el pedido no se puede verificar.', 'Compará las tres opciones por precio, soporte e integraciones y decime cuál conviene.', '¿Qué información importante falta?', 'Exacto. Sin la fuente de cada dato no podés abrir el enlace y comprobar el precio o el soporte.', 'No es el orden de la tabla. Falta pedir la fuente de cada dato.', [
      ['a', 'Pedir la fuente de cada dato para poder comprobarlo.', true],
      ['b', 'Agregar una columna de color.', false],
      ['c', 'Pedir una respuesta más entusiasta.', false],
    ]),
    round(3, 'judge_result', 'Juzgá el resultado', 'El pedido exigía fuentes.', 'Pedido: Compará por precio y soporte, y citá la fuente de cada dato.\n\nRespuesta de la IA: La opción B sale 30 dólares por mes y tiene el mejor soporte. Es la que conviene.', '¿Qué problema tiene este resultado?', 'Bien. Da un precio y una recomendación sin fuente. No se puede verificar.', 'No está lista para decidir. El precio no tiene fuente, así que puede estar inventado o desactualizado.', [
      ['a', 'Da un precio y una recomendación sin citar la fuente.', true],
      ['b', 'Recomienda una sola opción y eso siempre está mal.', false],
      ['c', 'Está bien porque el número es concreto.', false],
    ]),
  ],
}
