import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ArrowRight,
  BookOpen,
  Bot,
  CircleCheck,
  Flag,
  Lightbulb,
  MessagesSquare,
  Sparkles,
  Target,
  TriangleAlert,
  Zap,
} from 'lucide-react'
import { caseIcon } from './icons'
import { arrangeTools } from './CaseGuide'
import { CaseSteps } from './CaseSteps'
import { fichaFallbackActions, fichaSuccessChecks } from '../lib/fichaGuide'
import { shouldSkipObjectiveSlide, shouldSkipScenarioSlide } from '../lib/practiceFlow'
import { CaseFlowScene } from './CaseFlowScene'

function buildPracticeSlides(useCase, recommended) {
  const slides = [{ id: 'welcome', kind: 'welcome' }]
  if (!shouldSkipScenarioSlide(useCase)) slides.push({ id: 'scenario', kind: 'scenario' })
  if (!shouldSkipObjectiveSlide(useCase)) slides.push({ id: 'objective', kind: 'objective' })
  if (recommended) slides.push({ id: 'tool', kind: 'tool', tool: recommended })
  if (useCase.mistake) slides.push({ id: 'mistake', kind: 'mistake' })
  slides.push({ id: 'practice-start', kind: 'practice-start' })
  return slides
}

function buildFichaSlides(useCase, recommended, fallback, success, hasSteps) {
  const slides = [{ id: 'welcome', kind: 'welcome' }]
  if (!shouldSkipScenarioSlide(useCase)) slides.push({ id: 'scenario', kind: 'scenario' })
  if (!shouldSkipObjectiveSlide(useCase)) slides.push({ id: 'objective', kind: 'objective' })
  if (recommended) slides.push({ id: 'tool', kind: 'tool', tool: recommended })
  if (hasSteps) {
    const total = useCase.steps.length
    for (const step of useCase.steps) {
      slides.push({ id: `step-${step.position}`, kind: 'guided-step', position: step.position, total })
    }
  } else {
    fallback.forEach((body, index) => {
      slides.push({
        id: `action-${index}`,
        kind: 'action',
        index: index + 1,
        total: fallback.length,
        body,
      })
    })
  }
  if (success.length > 0) slides.push({ id: 'checks', kind: 'checks', items: success })
  if (useCase.mistake) slides.push({ id: 'mistake', kind: 'mistake' })
  slides.push({ id: 'finish', kind: 'finish' })
  return slides
}

function slideTitle(slide, isPractice) {
  switch (slide.kind) {
    case 'welcome':
      return 'Presentación del caso'
    case 'scenario':
      return 'Ejemplo concreto'
    case 'objective':
      return isPractice ? 'Qué vas a practicar' : 'Tu objetivo'
    case 'tool':
      return 'Herramienta recomendada'
    case 'action':
      return `Paso ${slide.index} de ${slide.total}`
    case 'guided-step':
      return `Paso ${slide.position} de ${slide.total}`
    case 'checks':
      return 'Cómo sabés que te sirvió'
    case 'mistake':
      return 'Error frecuente'
    case 'practice-start':
      return 'Antes de empezar'
    case 'finish':
      return 'Resumen del caso'
    default:
      return 'Caso de uso'
  }
}

function SlideBadge({ kind }) {
  const icons = {
    scenario: Lightbulb,
    objective: Target,
    tool: Bot,
    action: Flag,
    'guided-step': Flag,
    checks: CircleCheck,
    mistake: TriangleAlert,
    'practice-start': Zap,
    finish: Sparkles,
  }
  const Icon = icons[kind]
  if (!Icon) return null
  return (
    <span className={`ficha-pager-badge tone-${kind}`} aria-hidden>
      <Icon size={18} />
    </span>
  )
}

export function FichaPager({
  useCase,
  onAsk,
  onExit,
  variant = 'ficha',
  onStart,
  startLabel = 'Empezar práctica',
  onShowResult,
}) {
  const Icon = caseIcon(useCase)
  const isPractice = variant === 'practice'
  const slides = useMemo(() => {
    const { recommended } = arrangeTools(useCase.tools)
    if (variant === 'practice') return buildPracticeSlides(useCase, recommended)
    const hasSteps = (useCase.steps?.length ?? 0) > 0
    const fallback = fichaFallbackActions(useCase, recommended?.name)
    const success = fichaSuccessChecks(useCase).filter((line) => line !== useCase.learning)
    return buildFichaSlides(useCase, recommended, fallback, success, hasSteps)
  }, [useCase, variant])
  const [page, setPage] = useState(0)
  const [anim, setAnim] = useState('fwd')
  const focusRef = useRef(null)
  const last = page >= slides.length - 1
  const slide = slides[page]
  const progress = Math.round(((page + 1) / slides.length) * 100)

  useEffect(() => {
    setPage(0)
    setAnim('fwd')
  }, [useCase.id])

  useEffect(() => {
    focusRef.current?.focus()
  }, [page])

  useEffect(() => {
    function onKey(event) {
      if (event.key !== 'Enter' || event.shiftKey || event.metaKey || event.ctrlKey || event.altKey) return
      const tag = event.target?.tagName
      if (tag === 'TEXTAREA' || tag === 'INPUT' || tag === 'SELECT' || tag === 'BUTTON') return
      event.preventDefault()
      if (page >= slides.length - 1) {
        if (isPractice) onStart?.()
        else onExit?.()
        return
      }
      setAnim('fwd')
      setPage((current) => Math.min(slides.length - 1, current + 1))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [page, slides.length, isPractice, onStart, onExit])

  function go(next) {
    const target = Math.max(0, Math.min(slides.length - 1, next))
    if (target === page) return
    setAnim(target > page ? 'fwd' : 'back')
    setPage(target)
  }

  const heading = slide.kind === 'welcome'
    ? useCase.title
    : slide.kind === 'tool'
      ? slide.tool.name
      : slideTitle(slide, isPractice)

  return (
    <CaseFlowScene panelClass={isPractice ? 'is-practice' : 'is-ficha'}>
      <header className="ficha-pager-top">
        <button type="button" className="ficha-pager-exit" onClick={onExit}>
          ← Salir
        </button>
        <p className="ficha-pager-count">
          <BookOpen size={14} aria-hidden />
          {page + 1} de {slides.length}
        </p>
      </header>

      <div
        className="ficha-pager-progress"
        role="progressbar"
        aria-valuenow={progress}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={`Progreso del caso: ${progress}%`}
      >
        <span className="ficha-pager-progress-fill" style={{ width: `${progress}%` }} />
      </div>

      <div className="ficha-pager-body">
        <article
          className={`ficha-pager-slide tone-${slide.kind} ficha-anim-${anim}`}
          key={page}
          aria-live="polite"
        >
          {slide.kind !== 'welcome' && (
            <div className="ficha-pager-slide-head">
              <SlideBadge kind={slide.kind} />
              <p className="ficha-pager-label">{slideTitle(slide, isPractice)}</p>
            </div>
          )}

          {slide.kind !== 'welcome' && (
            <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">
              {heading}
            </h2>
          )}

          <div className="ficha-pager-slide-body">
            {slide.kind === 'welcome' && (
              <div className="ficha-pager-welcome">
                <div className="ficha-pager-welcome-row">
                  <span className={`ficha-pager-icon tool-icon ${useCase.color}`}><Icon size={28} /></span>
                  <div className="ficha-pager-welcome-meta">
                    {useCase.areaName && <p className="case-kicker">{useCase.areaName}</p>}
                    <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-welcome-title">{useCase.title}</h2>
                  </div>
                </div>
                <p className="ficha-pager-lead">{useCase.description}</p>
                {slide.kind === 'welcome' && shouldSkipScenarioSlide(useCase) && useCase.situation && (
                  <p className="ficha-pager-copy">{useCase.situation}</p>
                )}
                {slide.kind === 'welcome' && shouldSkipObjectiveSlide(useCase) && useCase.learning && (
                  <p className="ficha-pager-hint"><strong>Objetivo.</strong> {useCase.learning}</p>
                )}
                <div className="case-meta-pills ficha-pager-pills">
                  <span>{useCase.estimatedTime}</span>
                  <span>Dificultad {String(useCase.difficulty).toLocaleLowerCase('es')}</span>
                  <span className="pill-mode">{isPractice ? 'Práctica guiada' : 'Ficha de referencia'}</span>
                </div>
              </div>
            )}

            {slide.kind === 'scenario' && <p className="ficha-pager-copy">{useCase.situation}</p>}

            {slide.kind === 'objective' && (
              <>
                <p className="ficha-pager-highlight">{useCase.learning}</p>
                <p className="ficha-pager-hint">
                  {isPractice
                    ? 'Usalo como criterio cuando respondas los desafíos.'
                    : 'Compará tu resultado con esto antes de darlo por cerrado.'}
                </p>
              </>
            )}

            {slide.kind === 'tool' && slide.tool.reason && (
              <article className="guide-tool ficha-pager-tool">
                <span className="guide-tool-icon"><Bot size={24} /></span>
                <p>{slide.tool.reason}</p>
              </article>
            )}

            {slide.kind === 'action' && (
              <div className="ficha-pager-step-card">
                <span className="ficha-step-num" aria-hidden>{slide.index}</span>
                <p>{slide.body}</p>
              </div>
            )}

            {slide.kind === 'guided-step' && (
              <div className="ficha-pager-guided">
                <CaseSteps useCase={useCase} onlyPosition={slide.position} />
              </div>
            )}

            {slide.kind === 'checks' && (
              <ul className="ficha-pager-checks">
                {slide.items.map((line) => (
                  <li key={line}><CircleCheck size={17} aria-hidden /> {line}</li>
                ))}
              </ul>
            )}

            {slide.kind === 'mistake' && (
              <article className="ficha-mistake ficha-pager-mistake">
                <span aria-hidden><TriangleAlert size={20} /></span>
                <p>{useCase.mistake}</p>
              </article>
            )}

            {slide.kind === 'practice-start' && (
              <ol className="ficha-pager-practice-plan">
                <li><span>1</span><p>Contás tu situación con un formulario corto.</p></li>
                <li><span>2</span><p>Seguís los pasos con la herramienta.</p></li>
                <li><span>3</span><p>Respondés 3 desafíos y sumás XP.</p></li>
              </ol>
            )}

            {slide.kind === 'finish' && (
              <>
                <p className="ficha-pager-lead">
                  Ya tenés el mapa del caso. Probá aplicarlo con tus números y mensajes reales.
                </p>
                <button type="button" className="text-button ficha-pager-ask-link" onClick={() => onAsk(useCase.id)}>
                  <MessagesSquare size={15} /> ¿Te trabaste? Preguntá en la comunidad
                </button>
              </>
            )}
          </div>
        </article>
      </div>

      <footer className="ficha-pager-foot">
        <button
          type="button"
          className="ficha-pager-back"
          disabled={page === 0}
          onClick={() => go(page - 1)}
        >
          Atrás
        </button>
        <div className="ficha-pager-actions">
          {last && !isPractice && (
            <button type="button" className="secondary ficha-pager-secondary" onClick={() => onAsk(useCase.id)}>
              Preguntar
            </button>
          )}
          {last && onShowResult && (
            <button type="button" className="secondary ficha-pager-secondary" onClick={onShowResult}>
              Ver pedido
            </button>
          )}
          <button
            type="button"
            className="primary ficha-pager-continue"
            onClick={last ? (isPractice ? onStart : onExit) : () => go(page + 1)}
          >
            {last ? (isPractice ? startLabel : 'Listo') : 'Continuar'}
            <ArrowRight size={18} />
          </button>
        </div>
      </footer>
    </CaseFlowScene>
  )
}