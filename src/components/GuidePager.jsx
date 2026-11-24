import { useEffect, useMemo, useRef, useState } from 'react'
import { Bot, Flag, Sparkles, TriangleAlert } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { stepStates } from '../lib/steps'
import { guideStepGroups, isCondensedPracticeGuide } from '../lib/practiceFlow'
import { arrangeTools } from './CaseGuide'
import { CaseFlowScene } from './CaseFlowScene'
import { CaseSteps } from './CaseSteps'
import { PagerChrome } from './PagerChrome'

export function GuidePager({ useCase, onContinue, onExit, onBackIntro }) {
  const { data, toggleStep } = useSkillbotData()
  const [advancing, setAdvancing] = useState(false)
  const [stepError, setStepError] = useState(null)
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

  const condensed = isCondensedPracticeGuide(useCase)
  const slides = useMemo(() => {
    const { recommended } = arrangeTools(useCase.tools)
    const list = [{ kind: 'intro' }]
    if (recommended && !condensed) list.push({ kind: 'tool', tool: recommended })
    for (const group of guideStepGroups(steps)) {
      list.push(group)
    }
    if (useCase.mistake && !condensed) list.push({ kind: 'mistake' })
    list.push({ kind: 'finish' })
    return list
  }, [useCase, steps, condensed])

  const [page, setPage] = useState(0)
  const [anim, setAnim] = useState('fwd')
  const focusRef = useRef(null)
  const slide = slides[page]
  const last = page >= slides.length - 1
  const progress = Math.round(((page + 1) / slides.length) * 100)

  useEffect(() => {
    setPage(0)
    setAnim('fwd')
  }, [useCase.id])

  useEffect(() => {
    focusRef.current?.focus()
  }, [page])

  function go(next) {
    const target = Math.max(0, Math.min(slides.length - 1, next))
    if (target === page) return
    setAnim(target > page ? 'fwd' : 'back')
    setPage(target)
  }

  function handleBack() {
    if (page === 0) onBackIntro()
    else go(page - 1)
  }

  async function handlePrimary() {
    if (last) {
      if (ready) onContinue()
      return
    }
    if (slide.kind === 'step' || slide.kind === 'step-group') {
      const positions = slide.positions ?? [slide.position]
      const locked = positions.some((position) => states.find((item) => item.position === position)?.locked)
      if (locked) return
      setAdvancing(true)
      setStepError(null)
      try {
        for (const position of positions) {
          const state = states.find((item) => item.position === position)
          if (state && !state.done) {
            await toggleStep({ useCase, position, done: true })
          }
        }
        go(page + 1)
      } catch (error) {
        setStepError(error)
      } finally {
        setAdvancing(false)
      }
      return
    }
    go(page + 1)
  }

  const stepState = slide.kind === 'step' || slide.kind === 'step-group'
    ? states.find((item) => item.position === (slide.positions?.[0] ?? slide.position))
    : null

  const primaryLabel = last
    ? (ready ? 'Seguir a los desafíos' : remaining === 1 ? 'Falta marcar 1 paso' : `Faltan ${remaining} pasos`)
    : advancing
      ? 'Guardando…'
      : 'Siguiente'

  return (
    <CaseFlowScene panelClass="is-guide">
      <PagerChrome
        page={page}
        total={slides.length}
        progress={progress}
        onExit={onExit}
        onBack={handleBack}
        backDisabled={false}
        onPrimary={handlePrimary}
        primaryLabel={primaryLabel}
        primaryDisabled={(last && !ready) || advancing || Boolean(stepState?.locked)}
      >
        <article className={`ficha-pager-slide tone-${slide.kind} ficha-anim-${anim}`} key={page}>
          {slide.kind === 'intro' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-objective" aria-hidden><Flag size={18} /></span>
                <p className="ficha-pager-label">Recorrido guiado</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">Cómo resolverlo</h2>
              <p className="ficha-pager-lead">
                Con <b>Siguiente</b> confirmás cada paso. Los desafíos se habilitan al terminar.
              </p>
            </>
          )}

          {slide.kind === 'tool' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-tool" aria-hidden><Bot size={18} /></span>
                <p className="ficha-pager-label">Herramienta recomendada</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">{slide.tool.name}</h2>
              {slide.tool.reason && (
                <article className="guide-tool ficha-pager-tool">
                  <span className="guide-tool-icon"><Bot size={24} /></span>
                  <p>{slide.tool.reason}</p>
                </article>
              )}
            </>
          )}

          {(slide.kind === 'step' || slide.kind === 'step-group') && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-guided-step" aria-hidden><Flag size={18} /></span>
                <p className="ficha-pager-label">
                  {slide.kind === 'step-group' ? slide.label : `Paso ${slide.position} de ${slide.total}`}
                </p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">
                {slide.kind === 'step-group' ? 'Avanzá con este bloque' : 'Hacé este paso'}
              </h2>
              <div className="ficha-pager-guided">
                <CaseSteps
                  useCase={guideCase}
                  onlyPosition={slide.kind === 'step' ? slide.position : null}
                  onlyPositions={slide.kind === 'step-group' ? slide.positions : null}
                  hideToggle
                />
              </div>
              {stepError && (
                <p className="save-error" role="alert">No se pudo guardar el paso: {stepError.message}</p>
              )}
            </>
          )}

          {slide.kind === 'mistake' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-mistake" aria-hidden><TriangleAlert size={18} /></span>
                <p className="ficha-pager-label">Error frecuente</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">Evitá esto</h2>
              <article className="ficha-mistake ficha-pager-mistake">
                <span aria-hidden><TriangleAlert size={20} /></span>
                <p>{useCase.mistake}</p>
              </article>
            </>
          )}

          {slide.kind === 'finish' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-finish" aria-hidden><Sparkles size={18} /></span>
                <p className="ficha-pager-label">Listo para desafíos</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">Terminaste los pasos</h2>
              <p className="ficha-pager-lead">
                {ready
                  ? 'Podés seguir con los 3 desafíos y sumar XP.'
                  : 'Volvé atrás y marcá los pasos que falten.'}
              </p>
            </>
          )}
        </article>
      </PagerChrome>
    </CaseFlowScene>
  )
}