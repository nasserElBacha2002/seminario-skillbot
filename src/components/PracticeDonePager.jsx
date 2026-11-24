import { useEffect, useMemo, useRef, useState } from 'react'
import { CircleCheck, ClipboardCopy, Sparkles } from 'lucide-react'
import { CaseFlowScene } from './CaseFlowScene'
import { PagerChrome } from './PagerChrome'
import { CaseResult } from './CaseResult'
import {
  CHALLENGE_TONE,
  challengeClosingLine,
} from '../lib/practiceFlow'

function xpMessage(earned, awardError) {
  if (earned > 0) return null
  if (awardError) {
    return 'Terminaste la práctica. El XP no se pudo guardar: falta aplicar la migración de desafíos. Cuando esté, repetí la práctica para sumarlo una sola vez.'
  }
  return 'Esta práctica no sumó XP nuevo. La recompensa de cada desafío se entrega una sola vez.'
}

export function PracticeDonePager({
  useCase,
  challenges,
  earned,
  awardError,
  resultText,
  situation,
  tools,
  saveError,
  onExit,
  onEdit,
  onBackIntro,
}) {
  const slides = useMemo(() => {
    const list = [{ kind: 'celebrate' }]
    if (resultText) list.push({ kind: 'result' })
    return list
  }, [resultText])

  const [page, setPage] = useState(0)
  const [anim, setAnim] = useState('fwd')
  const focusRef = useRef(null)
  const slide = slides[page]
  const last = page >= slides.length - 1
  const progress = Math.round(((page + 1) / slides.length) * 100)
  const xpNote = xpMessage(earned, awardError)

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
    if (page === 0) onBackIntro?.()
    else go(page - 1)
  }

  function handlePrimary() {
    if (last) onExit?.()
    else go(page + 1)
  }

  const primaryLabel = last ? 'Listo' : 'Ver pedido'

  return (
    <CaseFlowScene panelClass="is-practice-done">
      <PagerChrome
        page={page}
        total={slides.length}
        progress={progress}
        onExit={onExit}
        onBack={handleBack}
        backDisabled={false}
        onPrimary={handlePrimary}
        primaryLabel={primaryLabel}
        primaryDisabled={false}
      >
        <article className={`ficha-pager-slide tone-${slide.kind} ficha-anim-${anim}`} key={page}>
          {slide.kind === 'celebrate' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-finish practice-done-spark" aria-hidden>
                  <Sparkles size={18} />
                </span>
                <p className="ficha-pager-label">Práctica completada</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">
                Terminaste los 3 desafíos
              </h2>
              <p className="ficha-pager-lead">
                Ya sabés qué mirar antes de confiar en un pedido o en una respuesta de IA.
              </p>
              <ul className="ficha-pager-checks practice-done-checks">
                {challenges.map((challenge, index) => {
                  const tone = CHALLENGE_TONE[challenge.type] || 'checks'
                  return (
                    <li
                      key={challenge.position}
                      className={`practice-done-check tone-${tone}`}
                      style={{ animationDelay: `${0.12 + index * 0.1}s` }}
                    >
                      <CircleCheck size={17} aria-hidden />
                      {challengeClosingLine(challenge)}
                    </li>
                  )
                })}
              </ul>
              {earned > 0 ? (
                <p className="earned practice-done-xp" aria-live="polite">+{earned} XP</p>
              ) : (
                <p className="ficha-pager-hint">{xpNote}</p>
              )}
            </>
          )}

          {slide.kind === 'result' && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-objective" aria-hidden>
                  <ClipboardCopy size={18} />
                </span>
                <p className="ficha-pager-label">Ponelo en práctica</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">
                Tu pedido listo
              </h2>
              <CaseResult
                embedded
                text={resultText}
                situation={situation}
                tools={tools}
                saveError={saveError}
                onEdit={onEdit}
                onBack={onBackIntro}
              />
            </>
          )}
        </article>
      </PagerChrome>
    </CaseFlowScene>
  )
}