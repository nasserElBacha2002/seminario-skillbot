import { ArrowRight, Bot, TriangleAlert } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { stepStates } from '../lib/steps'
import { CaseSteps } from './CaseSteps'

export function arrangeTools(tools) {
  const list = tools ?? []
  const usable = list.filter((tool) => tool.url)
  const primaries = usable.filter((tool) => tool.role === 'primary')
  const recommended = primaries[0] || usable[0] || list[0] || null
  return { recommended, others: list.filter((tool) => tool !== recommended) }
}

export function CaseGuide({ useCase, onContinue }) {
  const { data } = useSkillbotData()
  const keys = useCase.keys ?? []
  const steps = useCase.steps?.length ? useCase.steps : keys.map((body, index) => ({
    position: index + 1,
    body,
    checklist: [],
    prompt: null,
  }))
  const guideCase = { ...useCase, steps }
  const { steps: states } = stepStates(guideCase, data.doneSteps[useCase.id])
  const remaining = states.filter((step) => !step.done).length
  const ready = states.length > 0 && remaining === 0
  const { recommended, others } = arrangeTools(useCase.tools)

  return (
    <section className="case-guide">
      <h2 className="flow-title">Cómo resolverlo</h2>
      <p className="flow-lead">Marcá cada paso como listo. El desafío se habilita cuando terminás el recorrido.</p>

      {recommended && (
        <article className="guide-tool">
          <span className="guide-tool-icon"><Bot size={22} /></span>
          <div>
            <p className="case-kicker">Herramienta recomendada</p>
            <h3>{recommended.name}</h3>
            {recommended.reason && <p>{recommended.reason}</p>}
            {others.length > 0 && (
              <p className="guide-tool-alt">
                También sirve {others.map((tool) => tool.name).join(', ')}.
              </p>
            )}
          </div>
        </article>
      )}

      <h3 className="guide-steps-title">Paso a paso</h3>
      <CaseSteps useCase={guideCase} />

      {useCase.mistake && (
        <p className="guide-mistake"><TriangleAlert size={16} /> {useCase.mistake}</p>
      )}

      <button type="button" className="primary" disabled={!ready} onClick={onContinue}>
        {ready
          ? <>Seguir a los desafíos <ArrowRight size={16} /></>
          : remaining === 1
            ? 'Falta marcar 1 paso'
            : `Faltan ${remaining} pasos`}
      </button>
    </section>
  )
}
