import { Bot, CircleCheck, TriangleAlert } from 'lucide-react'
import { stepStates } from '../lib/steps'
import { useSkillbotData } from '../context/SkillbotData'
import { fichaFallbackActions, fichaSuccessChecks } from '../lib/fichaGuide'
import { arrangeTools } from './CaseGuide'
import { CaseSteps } from './CaseSteps'

export function FichaGuide({ useCase }) {
  const { data } = useSkillbotData()
  const { recommended } = arrangeTools(useCase.tools)
  const hasSteps = (useCase.steps?.length ?? 0) > 0
  const { steps } = stepStates(useCase, data.doneSteps[useCase.id] ?? [])
  const doneCount = steps.filter((step) => step.done).length
  const fallback = fichaFallbackActions(useCase, recommended?.name)
  const success = fichaSuccessChecks(useCase)

  return (
    <section className="ficha-guide">
      <h2 className="flow-title">Qué hacer ahora</h2>
      <p className="flow-lead">
        Leíste el contexto. Seguí los pasos en orden; al final compará tu entregable con el resultado esperado.
      </p>

      {recommended && (
        <article className="guide-tool">
          <span className="guide-tool-icon"><Bot size={22} /></span>
          <div>
            <p className="case-kicker">Empezá acá</p>
            <h3>{recommended.name}</h3>
            {recommended.reason && <p>{recommended.reason}</p>}
          </div>
        </article>
      )}

      {hasSteps ? (
        <>
          <h3 className="guide-steps-title">Paso a paso</h3>
          <CaseSteps useCase={useCase} />
          {steps.length > 0 && (
            <p className="guide-done">
              {doneCount === steps.length
                ? 'Marcaste todos los pasos. Revisá el resultado esperado abajo.'
                : `${doneCount} de ${steps.length} pasos marcados`}
            </p>
          )}
        </>
      ) : (
        <ol className="ficha-actions">
          {fallback.map((body) => (
            <li key={body}>{body}</li>
          ))}
        </ol>
      )}

      {useCase.learning && (
        <article className="ficha-outcome">
          <p className="case-kicker">Resultado esperado</p>
          <p>{useCase.learning}</p>
        </article>
      )}

      {success.length > 0 && (
        <article className="guide-checklist ficha-success">
          <p className="case-kicker">Sabés que te sirvió cuando…</p>
          <ul>
            {success.map((line) => (
              <li key={line}><CircleCheck size={14} aria-hidden /> {line}</li>
            ))}
          </ul>
        </article>
      )}

      {useCase.mistake && (
        <p className="guide-mistake"><TriangleAlert size={16} /> {useCase.mistake}</p>
      )}
    </section>
  )
}