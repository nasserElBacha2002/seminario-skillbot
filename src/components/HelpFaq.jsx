import { FileText, ListChecks, Search, ShieldCheck, Target } from 'lucide-react'

const howItWorks = [
  [Search, 'Elegí un caso', 'Buscá una tarea parecida a la tuya o arrancá por el caso del día.'],
  [ListChecks, 'Seguí la guía', 'Te recomendamos una herramienta y marcás los pasos a medida que los hacés.'],
  [FileText, 'Armá el pedido', 'Completás unos datos y SkillBot arma el pedido para copiarlo en la IA.'],
  [Target, 'Resolvé los desafíos', 'Tres preguntas cortas para practicar. Ahí se gana el XP.'],
]

const topics = [
  {
    id: 'uso',
    title: 'Usar SkillBot',
    questions: [
      ['¿Qué es un caso de uso?', 'Es una tarea cotidiana que se puede resolver con IA, como ordenar una planilla o resumir un PDF. Cada caso trae la situación, la herramienta recomendada, los pasos y el error más común.'],
      ['¿Cómo encuentro un caso para lo que necesito?', 'Usá el buscador de Inicio o de Explorar y escribí la tarea con tus palabras, por ejemplo "resumir un pdf para el parcial". También podés filtrar por categoría.'],
      ['¿Puedo dejar un caso a la mitad?', 'Sí. Tu avance queda guardado y en Inicio aparece "Seguí donde quedaste" para retomarlo.'],
      ['¿Por qué el desafío está bloqueado?', 'Se habilita cuando completás los pasos del caso.'],
    ],
  },
  {
    id: 'progreso',
    title: 'XP, nivel y logros',
    questions: [
      ['¿Cómo gano XP?', 'Respondiendo bien los desafíos de cada caso. Cada desafío suma XP una sola vez y, al terminar los tres, se suma un bonus. Copiar el pedido o abrir la herramienta no suma XP.'],
      ['¿Qué pasa si me equivoco en un desafío?', 'Ves por qué la respuesta no era la mejor y podés volver a intentarlo. El error no resta XP.'],
      ['¿Cómo funciona la racha?', 'Cuenta los días seguidos en los que practicaste. Si hoy todavía no practicaste, la racha de ayer sigue en pie hasta que termine el día.'],
    ],
  },
  {
    id: 'seguridad',
    title: 'Usar la IA con cuidado',
    questions: [
      ['¿Qué datos no tengo que pegar en una IA?', 'Contraseñas, datos bancarios, documentos, y nombres o mails de otras personas. Muchas veces alcanza con los encabezados o con datos de ejemplo.'],
      ['¿Puedo confiar en lo que responde la IA?', 'Revisalo siempre. La IA puede inventar datos, cifras o fuentes con mucha seguridad. Pedile que cite de dónde saca cada dato.'],
      ['¿Conviene probar antes de aplicar un cambio?', 'Sí. Si la IA te da una fórmula o un script, probalo sobre una copia del archivo, nunca sobre el original.'],
    ],
  },
]

export function HelpFaq() {
  return (
    <>
      <h2 className="help-section-title">Cómo funciona</h2>
      <ol className="help-steps">
        {howItWorks.map(([Icon, title, body], index) => (
          <li key={title}>
            <span className="help-step-icon"><Icon size={18} /></span>
            <small>Paso {index + 1}</small>
            <b>{title}</b>
            <p>{body}</p>
          </li>
        ))}
      </ol>
      {topics.map((topic) => (
        <div key={topic.id}>
          <h2 className="help-section-title">
            {topic.id === 'seguridad' && <ShieldCheck size={18} />}
            {topic.title}
          </h2>
          <div className="help-faq">
            {topic.questions.map(([question, answer]) => (
              <details key={question}>
                <summary>{question}</summary>
                <p>{answer}</p>
              </details>
            ))}
          </div>
        </div>
      ))}
    </>
  )
}
