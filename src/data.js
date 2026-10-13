import { BriefcaseBusiness, BookOpen, CalendarCheck, ClipboardList, FileText, Lightbulb, ListTodo, MessagesSquare, Presentation, Search, SlidersHorizontal, Table2 } from 'lucide-react'

// El catalogo vive en el frontend porque va a ser reemplazado por casos
// avanzados. El progreso en Supabase referencia cada caso por su id, asi que
// cambiar este archivo no requiere migrar la base. El campo skill apunta a un
// id de la tabla skills.
export const categories = ['Todos', 'Trabajo', 'Estudio', 'Contenido', 'Investigación', 'Organización', 'Datos']
export const useCases = [
  { id:'mail-profesional', title:'Redactar un mail profesional', category:'Trabajo', description:'Convertí una idea o mensaje informal en un correo claro y profesional.', estimatedTime:'5 min', difficulty:'Fácil', icon:MessagesSquare, color:'violet', recommendedTool:'ChatGPT', alternatives:['Gemini','Claude'], skill:'comunicacion' },
  { id:'resumir-reunion', title:'Resumir una reunión', category:'Trabajo', description:'Transformá notas o una transcripción en puntos y decisiones importantes.', estimatedTime:'5 min', difficulty:'Fácil', icon:ClipboardList, color:'blue', recommendedTool:'ChatGPT', skill:'comunicacion' },
  { id:'presentacion', title:'Preparar una presentación', category:'Trabajo', description:'Organizá tus ideas y creá una estructura clara para presentar un tema.', estimatedTime:'10 min', difficulty:'Media', icon:Presentation, color:'orange', recommendedTool:'ChatGPT', skill:'organizacion' },
  { id:'texto-largo', title:'Resumir un texto largo', category:'Estudio', description:'Identificá conceptos importantes y obtené un resumen para estudiar más rápido.', estimatedTime:'5 min', difficulty:'Fácil', icon:FileText, color:'blue', recommendedTool:'ChatGPT', skill:'analisis' },
  { id:'tema-dificil', title:'Entender un tema difícil', category:'Estudio', description:'Obtené explicaciones adaptadas a tu nivel y ejemplos concretos.', estimatedTime:'10 min', difficulty:'Media', icon:Lightbulb, color:'yellow', recommendedTool:'ChatGPT', skill:'analisis' },
  { id:'preguntas-examen', title:'Preparar preguntas para un examen', category:'Estudio', description:'Convertí tus apuntes en preguntas para practicar antes de una evaluación.', estimatedTime:'10 min', difficulty:'Media', icon:BookOpen, color:'violet', recommendedTool:'ChatGPT', skill:'organizacion' },
  { id:'ideas-redes', title:'Crear ideas para redes sociales', category:'Contenido', description:'Generá ideas de publicaciones a partir de un tema, producto u objetivo.', estimatedTime:'5 min', difficulty:'Fácil', icon:CalendarCheck, color:'pink', recommendedTool:'ChatGPT', skill:'creatividad' },
  { id:'mejorar-texto', title:'Mejorar un texto', category:'Contenido', description:'Corregí claridad, tono, gramática y estructura manteniendo tu idea original.', estimatedTime:'5 min', difficulty:'Fácil', icon:SlidersHorizontal, color:'pink', recommendedTool:'ChatGPT', skill:'comunicacion' },
  { id:'investigar', title:'Investigar un tema', category:'Investigación', description:'Encontrá información, compará fuentes y organizá los hallazgos.', estimatedTime:'10 min', difficulty:'Media', icon:Search, color:'blue', recommendedTool:'Perplexity', skill:'investigacion' },
  { id:'comparar', title:'Comparar alternativas', category:'Investigación', description:'Organizá ventajas, desventajas y diferencias entre distintas opciones.', estimatedTime:'10 min', difficulty:'Media', icon:BriefcaseBusiness, color:'orange', recommendedTool:'Perplexity', skill:'investigacion' },
  { id:'organizar', title:'Organizar tareas pendientes', category:'Organización', description:'Convertí una lista desordenada de pendientes en un plan de acción.', estimatedTime:'5 min', difficulty:'Fácil', icon:ListTodo, color:'violet', recommendedTool:'Notion AI', skill:'organizacion' },
  { id:'planilla', title:'Analizar una planilla', category:'Datos', description:'Detectá tendencias y obtené conclusiones claras a partir de tus datos.', estimatedTime:'10 min', difficulty:'Media', icon:Table2, color:'blue', recommendedTool:'ChatGPT', skill:'analisis' }
]

// El caso que tiene el recorrido detallado y el desafio implementados.
export const featuredUseCaseId = 'mail-profesional'
export const challengeXpReward = 30
