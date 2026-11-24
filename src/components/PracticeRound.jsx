import { useState } from 'react'
import { ArrowRight, Check, Zap } from 'lucide-react'
import { CaseFlowScene } from './CaseFlowScene'
import { PagerChrome } from './PagerChrome'

import { challengeClosingLine } from '../lib/practiceFlow'

export function closingLine(challenge) {
  return challengeClosingLine(challenge)
}

export function PracticeRound({
  challenge,
  index,
  total,
  hasPendingOther,
  onAnswer,
  onContinue,
  onExit,
  onBack,
}) {
  const [selected, setSelected] = useState(null)
  const [result, setResult] = useState(null)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const option = challenge.options.find((item) => item.letter === selected)
  const progress = Math.round(((index + 1) / total) * 100)

  async function confirm() {
    if (!option || saving) return
    setSaving(true)
    setSaveError(null)
    let xp = 0
    try {
      xp = await onAnswer({
        position: challenge.position,
        selectedOption: option.letter,
        isCorrect: option.is_correct,
      })
    } catch (error) {
      setSaveError(error)
      setSaving(false)
      return
    }
    setSaving(false)
    const feedback = option.feedback || (option.is_correct ? challenge.feedbackCorrect : challenge.feedbackIncorrect)
    setResult({ correct: option.is_correct, feedback, xp })
  }

  function retry() {
    setSelected(null)
    setResult(null)
    setSaveError(null)
  }

  function handlePrimary() {
    if (!result) {
      confirm()
      return
    }
    if (!result.correct) {
      retry()
      return
    }
    onContinue()
  }

  function handleBack() {
    if (result) {
      retry()
      return
    }
    onBack?.()
  }

  const primaryLabel = !result
    ? (saving ? 'Guardando…' : 'Siguiente')
    : result.correct
      ? 'Siguiente'
      : 'Intentar de nuevo'

  const primaryDisabled = !result ? (!selected || saving) : false

  const secondaryAction = result && !result.correct && hasPendingOther ? (
    <button type="button" className="secondary ficha-pager-secondary" onClick={onContinue}>
      Saltear <ArrowRight size={16} />
    </button>
  ) : null

  return (
    <CaseFlowScene panelClass="is-practice-round">
      <PagerChrome
        page={index}
        total={total}
        progress={progress}
        onExit={onExit}
        onBack={handleBack}
        backDisabled={saving}
        onPrimary={handlePrimary}
        primaryLabel={primaryLabel}
        primaryDisabled={primaryDisabled}
        secondaryAction={secondaryAction}
      >
        <article className="ficha-pager-slide tone-practice">
          <div className="ficha-pager-slide-head">
            <span className="ficha-pager-badge tone-practice-start" aria-hidden><Zap size={18} /></span>
            <p className="ficha-pager-label">Desafío {index + 1} de {total}</p>
          </div>
          <h2 className="ficha-pager-slide-title">{challenge.title}</h2>
          <p className="ficha-pager-lead">{challenge.instruction}</p>

          <article className="scenario practice-scenario practice-scenario-pager">
            <p>{challenge.scenario}</p>
          </article>

          {!result ? (
            <>
              <h3 className="practice-question">{challenge.question}</h3>
              <div className="options" role="radiogroup" aria-label={challenge.question}>
                {challenge.options.map((item) => (
                  <button
                    type="button"
                    key={item.letter}
                    role="radio"
                    aria-checked={selected === item.letter}
                    onClick={() => setSelected(item.letter)}
                    className={`option prompt-option ${selected === item.letter ? 'selected' : ''}`}
                  >
                    <span className="prompt-letter">{item.letter.toUpperCase()}</span>
                    <div><b>{item.body}</b></div>
                    <i>{selected === item.letter && <Check size={16} />}</i>
                  </button>
                ))}
              </div>
              {saveError && (
                <p className="save-error" role="alert">
                  No se pudo guardar el XP de este desafío: {saveError.message}
                  {/complete_practice_challenge|PGRST202/i.test(String(saveError.message ?? '')) && ' Falta aplicar la migración 20261027140000_secure_progress_writes.sql.'}
                </p>
              )}
            </>
          ) : (
            <div className={`feedback practice-feedback-pager ${result.correct ? 'success' : 'gentle'}`}>
              <h3>{result.correct ? 'Bien visto' : 'Mirá este detalle'}</h3>
              <p>{result.feedback}</p>
              {result.correct && result.xp > 0 && <p className="earned">+{result.xp} XP</p>}
              {!result.correct && <p className="feedback-hint">Este intento no suma XP. Corregilo para ganarlo.</p>}
            </div>
          )}
        </article>
      </PagerChrome>
    </CaseFlowScene>
  )
}