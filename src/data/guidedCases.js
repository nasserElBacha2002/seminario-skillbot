// Fixture TEMPORAL, copiado del seed. No es la fuente de verdad.
// Se usa solo si la base todavía tiene el schema o las categorías anteriores.
// Cuando estén aplicadas 20261020210000, 20261020223000 y el seed, eliminar este archivo.
export const fallbackCategories = [
  {
    "id": "presentaciones",
    "name": "Presentaciones"
  },
  {
    "id": "datos",
    "name": "Datos y análisis"
  },
  {
    "id": "estudio",
    "name": "Estudio"
  },
  {
    "id": "organizacion",
    "name": "Organización y productividad"
  },
  {
    "id": "contenido",
    "name": "Contenido y redacción"
  },
  {
    "id": "automatizacion",
    "name": "Automatización"
  }
]

export const toolUrls = {
  "chatgpt": "https://chatgpt.com/",
  "claude": "https://claude.ai/new",
  "gemini": "https://gemini.google.com/app",
  "copilot": "https://copilot.microsoft.com/",
  "notebooklm": "https://notebooklm.google.com/",
  "apps-script": "https://script.google.com/home",
  "diseno": "https://www.canva.com/"
}

export const guidedCases = {
  "documento-presentacion": {
    "categoryIds": [
      "presentaciones"
    ],
    "outputTemplate": "Necesito preparar una presentación. Trabajemos primero el contenido, sin diseñar todavía.\n\nTema o material:\n{{tema}}\n\nAudiencia: {{audiencia}}\nDuración: {{duracion}}\nCantidad de diapositivas: {{diapositivas}}\nObjetivo: {{objetivo}}\nTono: {{tono}}\n\nConvertí este material en un esquema de diapositivas.\nPara cada una incluí: título, como máximo 3 ideas y una frase de cierre.\nDespués escribí las notas del orador en una o dos oraciones por diapositiva.\nNo inventes cifras, nombres ni datos que no estén en el material. Si falta algo, escribí A CONFIRMAR.",
    "fields": [
      {
        "id": "documento-presentacion.tema",
        "key": "tema",
        "label": "¿Qué documento o tema vas a presentar?",
        "type": "textarea",
        "placeholder": "Pegá el tema o un resumen del documento",
        "required": true,
        "options": [],
        "helper": "No hace falta el archivo completo."
      },
      {
        "id": "documento-presentacion.audiencia",
        "key": "audiencia",
        "label": "¿A quién se lo vas a presentar?",
        "type": "text",
        "placeholder": "Por ejemplo, directivos o un docente",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "documento-presentacion.duracion",
        "key": "duracion",
        "label": "¿Cuánto tiempo tenés?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "5 minutos",
          "10 minutos",
          "15 minutos",
          "20 minutos o más"
        ],
        "helper": ""
      },
      {
        "id": "documento-presentacion.diapositivas",
        "key": "diapositivas",
        "label": "¿Cuántas diapositivas, aproximadamente?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": false,
        "options": [
          "Que lo decida según la duración",
          "5 diapositivas",
          "8 diapositivas",
          "10 diapositivas",
          "12 diapositivas",
          "15 diapositivas"
        ],
        "helper": ""
      },
      {
        "id": "documento-presentacion.objetivo",
        "key": "objetivo",
        "label": "¿Qué tiene que lograr la presentación?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Informar",
          "Explicar",
          "Convencer",
          "Presentar resultados"
        ],
        "helper": ""
      },
      {
        "id": "documento-presentacion.tono",
        "key": "tono",
        "label": "¿Qué tono necesitás?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Académico",
          "Profesional",
          "Simple",
          "Persuasivo"
        ],
        "helper": ""
      }
    ]
  },
  "ventas-sin-formulas": {
    "categoryIds": [
      "datos"
    ],
    "outputTemplate": "Tengo una planilla de {{herramienta}} en {{idioma}}.\n\nColumnas:\n{{columnas}}\n\nCantidad aproximada de filas: {{filas}}\nQuiero lograr esto:\n{{objetivo}}\n\nNo me des un análisis genérico. Decime qué tiene que calcular la planilla, dame la fórmula lista para pegar y explicala en una línea.\nIndicá en qué celda pegarla.\nSi la planilla está en español, usá punto y coma como separador.\nNo incluyas datos personales. Voy a probar la fórmula con 3 filas cuyo resultado ya conozco.",
    "fields": [
      {
        "id": "ventas-sin-formulas.herramienta",
        "key": "herramienta",
        "label": "¿Dónde está la planilla?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Google Sheets",
          "Excel"
        ],
        "helper": ""
      },
      {
        "id": "ventas-sin-formulas.idioma",
        "key": "idioma",
        "label": "¿En qué idioma está la planilla?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Español",
          "Inglés"
        ],
        "helper": "En español los separadores suelen ser punto y coma."
      },
      {
        "id": "ventas-sin-formulas.columnas",
        "key": "columnas",
        "label": "¿Qué columnas tiene?",
        "type": "textarea",
        "placeholder": "Fecha, Vendedor, Producto, Monto, Días de deuda",
        "required": true,
        "options": [],
        "helper": "No pegues nombres, mails ni datos bancarios. Con los encabezados alcanza."
      },
      {
        "id": "ventas-sin-formulas.objetivo",
        "key": "objetivo",
        "label": "¿Qué necesitás saber?",
        "type": "textarea",
        "placeholder": "Total por vendedor y marcar deudas de más de 30 días",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "ventas-sin-formulas.filas",
        "key": "filas",
        "label": "¿Cuántas filas tiene, aproximadamente?",
        "type": "text",
        "placeholder": "Por ejemplo, 600",
        "required": false,
        "options": [],
        "helper": ""
      }
    ]
  },
  "reporte-campania": {
    "categoryIds": [
      "contenido",
      "datos"
    ],
    "outputTemplate": "Necesito un informe de una página sobre una campaña.\n\nDatos que tengo:\n{{datos}}\n\nQuién lo lee: {{lector}}\nDecisión que tiene que tomar: {{objetivo}}\nTono: {{tono}}\n\nPrimero calculá los indicadores que se puedan sacar de estos datos y listá los 3 mejores y los 3 peores resultados.\nNo redactes conclusiones que los números no sostengan.\nDespués escribí el informe con esta estructura: resumen en 3 líneas, qué funcionó, qué no, y 3 acciones concretas.\nEvitá siglas. Si falta un dato, escribí A CONFIRMAR.",
    "fields": [
      {
        "id": "reporte-campania.datos",
        "key": "datos",
        "label": "¿Qué datos tenés de la campaña?",
        "type": "textarea",
        "placeholder": "Impresiones, clics, gasto y conversiones de cada anuncio",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "reporte-campania.lector",
        "key": "lector",
        "label": "¿Quién va a leer el informe?",
        "type": "text",
        "placeholder": "Por ejemplo, el dueño de una pyme",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "reporte-campania.objetivo",
        "key": "objetivo",
        "label": "¿Qué decisión tiene que tomar?",
        "type": "textarea",
        "placeholder": "Decidir qué anuncios mantener el mes que viene",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "reporte-campania.tono",
        "key": "tono",
        "label": "¿Qué tono tiene que tener?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Simple",
          "Profesional",
          "Directo"
        ],
        "helper": ""
      }
    ]
  },
  "reunion-seguimiento": {
    "categoryIds": [
      "organizacion"
    ],
    "outputTemplate": "Necesito dejar por escrito una reunión.\n\nFuente: {{fuente}}\nContexto:\n{{contexto}}\n\nQué necesito: {{incluir}}\nTono: {{tono}}\n\nSi pedí minuta, armala con fecha, asistentes, decisiones, tareas (quién, qué, para cuándo) y temas pendientes.\nNo inventes responsables ni fechas. Si falta un dato, escribí A CONFIRMAR.\nSi pedí mail, redactá un correo de seguimiento de unas 120 palabras usando solo lo que está en la minuta.\nSi pedí ambos, hacé primero la minuta y después el mail.",
    "fields": [
      {
        "id": "reunion-seguimiento.fuente",
        "key": "fuente",
        "label": "¿Con qué fuente contás?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Transcripción",
          "Apuntes propios"
        ],
        "helper": ""
      },
      {
        "id": "reunion-seguimiento.contexto",
        "key": "contexto",
        "label": "¿De qué fue la reunión?",
        "type": "textarea",
        "placeholder": "Con quién fue y qué se trató",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "reunion-seguimiento.incluir",
        "key": "incluir",
        "label": "¿Qué necesitás obtener?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Minuta y mail",
          "Solo minuta",
          "Solo mail"
        ],
        "helper": ""
      },
      {
        "id": "reunion-seguimiento.tono",
        "key": "tono",
        "label": "¿Qué tono tiene que tener el mail?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Cordial",
          "Formal",
          "Breve"
        ],
        "helper": ""
      }
    ]
  },
  "estudiar-material": {
    "categoryIds": [
      "estudio"
    ],
    "outputTemplate": "Necesito estudiar este material:\n\n{{material}}\n\nPlazo: {{plazo}}\nTiempo por día: {{tiempo_diario}}\nObjetivo: {{objetivo}}\nNivel de partida: {{nivel}}\n\nEmpezá por un mapa de los temas, ordenados de lo básico a lo complejo.\nDespués explicalos de a uno, con un ejemplo, según mi nivel de partida.\nCerrá con un plan día por día que entre en el plazo y el tiempo diario, con repasos.\nNo agregues temas que no estén en el material. Si algo no está, decilo.",
    "fields": [
      {
        "id": "estudiar-material.material",
        "key": "material",
        "label": "¿Qué tenés que estudiar?",
        "type": "textarea",
        "placeholder": "Materia, PDF o certificación",
        "required": true,
        "options": [],
        "helper": "No pegues el archivo entero. Con el nombre y los temas alcanza."
      },
      {
        "id": "estudiar-material.plazo",
        "key": "plazo",
        "label": "¿En cuánto tiempo?",
        "type": "text",
        "placeholder": "Por ejemplo, 14 días",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "estudiar-material.tiempo",
        "key": "tiempo_diario",
        "label": "¿Cuánto tiempo por día?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "30 minutos",
          "1 hora",
          "2 horas"
        ],
        "helper": ""
      },
      {
        "id": "estudiar-material.objetivo",
        "key": "objetivo",
        "label": "¿Para qué lo estudiás?",
        "type": "text",
        "placeholder": "Por ejemplo, aprobar un parcial",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "estudiar-material.nivel",
        "key": "nivel",
        "label": "¿Desde dónde partís?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Desde cero",
          "Ya sé lo básico",
          "Es un repaso"
        ],
        "helper": ""
      }
    ]
  },
  "imagenes-redes": {
    "categoryIds": [
      "contenido"
    ],
    "outputTemplate": "Necesito una imagen para publicar, que no parezca genérica.\n\nProducto o tema:\n{{producto}}\n\nFormato: {{formato}}\nDónde se publica: {{uso}}\nEstilo: {{estilo}}\nColores: {{colores}}\nQué evitar: {{evitar}}\n\nEscribí un pedido visual concreto con sujeto, escenario, luz, estilo, colores y qué no tiene que aparecer.\nNo pidas texto ni logos dentro de la imagen: eso se agrega después en una herramienta de diseño.\nProponé 3 variantes y, entre una y otra, cambiá una sola cosa.",
    "fields": [
      {
        "id": "imagenes-redes.producto",
        "key": "producto",
        "label": "¿Qué hay que mostrar?",
        "type": "textarea",
        "placeholder": "El producto o la idea",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "imagenes-redes.formato",
        "key": "formato",
        "label": "¿Qué formato necesitás?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Cuadrado",
          "Vertical",
          "Horizontal"
        ],
        "helper": ""
      },
      {
        "id": "imagenes-redes.uso",
        "key": "uso",
        "label": "¿Dónde se va a publicar?",
        "type": "text",
        "placeholder": "Por ejemplo, una historia de Instagram",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "imagenes-redes.estilo",
        "key": "estilo",
        "label": "¿Qué estilo buscás?",
        "type": "text",
        "placeholder": "Por ejemplo, foto de revista con luz natural",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "imagenes-redes.colores",
        "key": "colores",
        "label": "¿Qué colores tiene que respetar?",
        "type": "text",
        "placeholder": "Por ejemplo, dorado y blanco",
        "required": false,
        "options": [],
        "helper": ""
      },
      {
        "id": "imagenes-redes.evitar",
        "key": "evitar",
        "label": "¿Qué no tiene que aparecer?",
        "type": "textarea",
        "placeholder": "Texto, logos, personas, fondos brillantes",
        "required": false,
        "options": [],
        "helper": ""
      }
    ]
  },
  "automatizar-tarea": {
    "categoryIds": [
      "automatizacion"
    ],
    "outputTemplate": "Necesito automatizar una tarea repetitiva. No sé programar.\n\nTarea:\n{{tarea}}\n\nDe dónde salen los datos: {{origen}}\nA dónde tienen que llegar: {{destino}}\nCada cuánto: {{cuando}}\nHerramienta: {{herramienta}}\n\nEscribí la solución más simple para esa herramienta y explicala paso a paso, en lenguaje simple.\nIncluí dónde se pega o se configura.\nAntes de ejecutar nada, indícame que lo pruebe en una copia, nunca en el archivo real.\nSi hace falta un permiso, explicá en tres líneas qué estoy autorizando.",
    "fields": [
      {
        "id": "automatizar-tarea.tarea",
        "key": "tarea",
        "label": "¿Qué tarea se repite?",
        "type": "textarea",
        "placeholder": "Qué copiás, desde qué columnas y qué le agregás",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "automatizar-tarea.origen",
        "key": "origen",
        "label": "¿De dónde salen los datos?",
        "type": "text",
        "placeholder": "Por ejemplo, la planilla de pedidos",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "automatizar-tarea.destino",
        "key": "destino",
        "label": "¿A dónde tienen que llegar?",
        "type": "text",
        "placeholder": "Por ejemplo, la planilla de control",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "automatizar-tarea.cuando",
        "key": "cuando",
        "label": "¿Cada cuánto?",
        "type": "text",
        "placeholder": "Por ejemplo, todos los lunes",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "automatizar-tarea.herramienta",
        "key": "herramienta",
        "label": "¿En qué herramienta está?",
        "type": "select",
        "placeholder": "Elegí una opción",
        "required": true,
        "options": [
          "Google Sheets",
          "Excel",
          "Otra"
        ],
        "helper": ""
      }
    ]
  },
  "comparar-decidir": {
    "categoryIds": [
      "datos"
    ],
    "outputTemplate": "Tengo que tomar una decisión y justificarla con información actual.\n\nDecisión:\n{{decision}}\n\nOpciones:\n{{opciones}}\n\nCriterios:\n{{criterios}}\n\nRestricción: {{restriccion}}\n\nActivá la búsqueda web.\nArmá una tabla comparativa con estos criterios.\nCitá la fuente de cada dato.\nDespués recomendá una opción, decí por qué y qué podría salir mal.\nSi un dato no tiene fuente, no lo uses: escribí SIN FUENTE.",
    "fields": [
      {
        "id": "comparar-decidir.decision",
        "key": "decision",
        "label": "¿Qué tenés que decidir?",
        "type": "textarea",
        "placeholder": "La decisión que tenés que justificar",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "comparar-decidir.opciones",
        "key": "opciones",
        "label": "¿Cuáles son las opciones?",
        "type": "textarea",
        "placeholder": "Dos o tres alternativas",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "comparar-decidir.criterios",
        "key": "criterios",
        "label": "¿Con qué criterios las comparás?",
        "type": "textarea",
        "placeholder": "Precio, soporte, facilidad, integraciones",
        "required": true,
        "options": [],
        "helper": ""
      },
      {
        "id": "comparar-decidir.restriccion",
        "key": "restriccion",
        "label": "¿Hay algo que no puede faltar?",
        "type": "textarea",
        "placeholder": "Una condición obligatoria, si existe",
        "required": false,
        "options": [],
        "helper": ""
      }
    ]
  }
}

// Roles del seed. Se aplican solo mientras la base siga con las categorías anteriores.
export const guidedTools = {
  "ventas-sin-formulas": [
    { "id": "gemini", "name": "Gemini", "role": "primary", "reason": "Integrado en Google Sheets, si el archivo ya está ahí." },
    { "id": "copilot", "name": "Copilot", "role": "primary", "reason": "Integrado en Excel, si el archivo ya está ahí." },
    { "id": "chatgpt", "name": "ChatGPT", "role": "alternative", "reason": "Si preferís pegar un recorte de la planilla." },
    { "id": "claude", "name": "Claude", "role": "alternative", "reason": "Si preferís pegar un recorte de la planilla." }
  ],
  "reporte-campania": [
    { "id": "claude", "name": "Claude", "role": "primary", "reason": "Para el análisis y la redacción. La planilla queda como fuente." },
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Para el análisis y la redacción. La planilla queda como fuente." }
  ],
  "reunion-seguimiento": [
    { "id": "gemini", "name": "Gemini", "role": "primary", "reason": "Si la reunión fue en Google Meet y tiene transcripción." },
    { "id": "copilot", "name": "Copilot", "role": "primary", "reason": "Si la reunión fue en Teams y tiene transcripción." },
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Si la plataforma de la reunión lo tiene integrado, o si pegás tus apuntes." },
    { "id": "claude", "name": "Claude", "role": "alternative", "reason": "Si pegás tus propios apuntes." }
  ],
  "estudiar-material": [
    { "id": "notebooklm", "name": "NotebookLM", "role": "primary", "reason": "Responde solo con los documentos que subís y cita de dónde sale cada dato." },
    { "id": "chatgpt", "name": "ChatGPT", "role": "complement", "reason": "Para armar el plan de estudio y las preguntas de práctica." },
    { "id": "claude", "name": "Claude", "role": "complement", "reason": "Para armar el plan de estudio y las preguntas de práctica." }
  ],
  "documento-presentacion": [
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Para pegar el pedido y armar primero el esquema de la presentación." },
    { "id": "claude", "name": "Claude", "role": "primary", "reason": "Para pegar el pedido y armar primero el esquema de la presentación." },
    { "id": "gemini", "name": "Gemini", "role": "complement", "reason": "Después, para pasar el esquema a diapositivas en Google Slides." },
    { "id": "copilot", "name": "Copilot", "role": "complement", "reason": "Después, para pasar el esquema a diapositivas en PowerPoint." }
  ],
  "imagenes-redes": [
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Para generar las imágenes." },
    { "id": "gemini", "name": "Gemini", "role": "primary", "reason": "Para generar las imágenes." },
    { "id": "diseno", "name": "Canva", "role": "complement", "reason": "Para agregar el texto y el logo fuera de la imagen generada." }
  ],
  "automatizar-tarea": [
    { "id": "claude", "name": "Claude", "role": "primary", "reason": "Para escribir el script y explicarlo paso a paso." },
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Para escribir el script y explicarlo paso a paso." },
    { "id": "apps-script", "name": "Google Apps Script", "role": "complement", "reason": "Para ejecutarlo dentro de Google Sheets sin instalar nada." }
  ],
  "comparar-decidir": [
    { "id": "chatgpt", "name": "ChatGPT", "role": "primary", "reason": "Con búsqueda web o modo de investigación activado, para juntar datos actuales." },
    { "id": "gemini", "name": "Gemini", "role": "primary", "reason": "Con búsqueda web o modo de investigación activado, para juntar datos actuales." },
    { "id": "claude", "name": "Claude", "role": "primary", "reason": "Con búsqueda web activada. Sin búsqueda, sirve para armar la tabla y la recomendación." }
  ]
}
