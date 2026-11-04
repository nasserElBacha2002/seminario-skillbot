import { useEffect, useId, useRef, useState } from 'react'
import { LoaderCircle } from 'lucide-react'
import { Logo, ProgressBar } from './Layout'
import {
  STEPS,
  emptyAnswers,
  onboardingErrorMessage,
  problemGroups,
  sanitizeAnswers,
  stepError,
  toggleAnswer,
} from '../lib/onboarding'
import { loadOnboardingDraft, saveOnboardingDraft } from '../lib/storage'

function initialState(mode, serverAnswers, options) {
  if (mode === 'edit' && serverAnswers) {
    return { answers: sanitizeAnswers(serverAnswers, options), step: 0 }
  }
  const draft = loadOnboardingDraft()
  if (draft?.answers) {
    const step = Math.min(Math.max(draft.step, 0), STEPS.length - 1)
    return { answers: sanitizeAnswers(draft.answers, options), step }
  }
  return { answers: sanitizeAnswers(serverAnswers ?? emptyAnswers(), options), step: 0 }
}

function Choice({ option, pressed, describedBy, onToggle }) {
  return (
    <button
      type="button"
      className="choice"
      aria-pressed={pressed}
      aria-describedby={describedBy}
      onClick={() => onToggle(option.value)}
      onKeyDown={(event) => {
        if (!['ArrowDown', 'ArrowUp', 'ArrowRight', 'ArrowLeft'].includes(event.key)) return
        const buttons = [...event.currentTarget.closest('[data-choices]').querySelectorAll('.choice')]
        const index = buttons.indexOf(event.currentTarget)
        const forward = event.key === 'ArrowDown' || event.key === 'ArrowRight'
        const next = buttons[(index + (forward ? 1 : -1) + buttons.length) % buttons.length]
        event.preventDefault()
        next?.focus()
      }}
    >
      <span className="choice-mark" aria-hidden="true" />
      <span>{option.label}</span>
    </button>
  )
}

export function OnboardingWizard({
  mode = 'start',
  options,
  serverAnswers = null,
  allowLater = false,
  onSubmit,
  onLater,
  onCancel,
}) {
  const headingId = useId()
  const toolHintId = useId()
  const headingRef = useRef(null)
  const lock = useRef(false)
  const [{ answers, step }, setState] = useState(() => initialState(mode, serverAnswers, options))
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const current = STEPS[step]
  const multiple = current.multiple
  const selected = multiple ? answers[current.key] : answers[current.key]
  const progress = Math.round(((step + 1) / STEPS.length) * 100)
  const last = step === STEPS.length - 1

  useEffect(() => {
    if (mode === 'edit' && serverAnswers) return
    saveOnboardingDraft(answers, step)
  }, [answers, step, mode, serverAnswers])

  useEffect(() => {
    headingRef.current?.focus()
  }, [step])

  function choose(value) {
    if (submitting) return
    setError('')
    setState((currentState) => ({
      ...currentState,
      answers: toggleAnswer(currentState.answers, currentState.step, value),
    }))
  }

  function back() {
    if (submitting || step === 0) return
    setError('')
    setState((currentState) => ({ ...currentState, step: currentState.step - 1 }))
  }

  async function finish(nextAnswers) {
    if (lock.current) return
    lock.current = true
    setSubmitting(true)
    setError('')
    try {
      await onSubmit(nextAnswers)
    } catch (submitError) {
      setError(onboardingErrorMessage(submitError))
      lock.current = false
      setSubmitting(false)
    }
  }

  function forward(event) {
    event.preventDefault()
    if (submitting) return
    const message = stepError(step, answers)
    if (message) {
      setError(message)
      return
    }
    if (!last) {
      setError('')
      setState((currentState) => ({ ...currentState, step: currentState.step + 1 }))
      return
    }
    finish(answers)
  }

  const choices = current.kind === 'problem' ? null : (options?.[current.kind] ?? [])
  const groups = current.kind === 'problem' ? problemGroups(options) : []

  const form = (
    <form className="onboarding-form" onSubmit={forward} noValidate>
      <p className="eyebrow">PREGUNTA {step + 1} DE {STEPS.length}</p>
      <ProgressBar value={progress} />
      {mode === 'edit' ? (
        <h2 id={headingId} ref={headingRef} tabIndex={-1} className="onboarding-title embedded">{current.title}</h2>
      ) : (
        <h1 id={headingId} ref={headingRef} tabIndex={-1} className="onboarding-title">{current.title}</h1>
      )}
      <p className="onboarding-hint">{current.hint}</p>
      <div
        data-choices
        role="group"
        aria-labelledby={headingId}
        aria-describedby={current.kind === 'tool' ? toolHintId : undefined}
      >
        {current.kind === 'problem' ? groups.map((group) => (
          <div key={group.id} className="choice-group">
            <h2>{group.label}</h2>
            <div className="choice-list">
              {group.options.map((option) => (
                <Choice
                  key={option.value}
                  option={option}
                  pressed={selected.includes(option.value)}
                  onToggle={choose}
                />
              ))}
            </div>
          </div>
        )) : (
          <div className="choice-list">
            {choices.map((option) => (
              <Choice
                key={option.value}
                option={option}
                pressed={multiple ? selected.includes(option.value) : selected === option.value}
                describedBy={option.value === 'ninguna' ? toolHintId : undefined}
                onToggle={choose}
              />
            ))}
          </div>
        )}
      </div>
      {current.kind === 'tool' && (
        <p id={toolHintId} className="onboarding-note">“Ninguna por ahora” reemplaza al resto. Si elegís otra herramienta, esa opción se suelta.</p>
      )}
      {error && <p className="save-error" role="alert">{error}</p>}
      <div className="onboarding-nav">
        {step > 0 ? (
          <button type="button" className="secondary" onClick={back} disabled={submitting}>Anterior</button>
        ) : <span />}
        <button type="submit" className="primary" disabled={submitting} aria-busy={submitting}>
          {submitting ? <LoaderCircle size={17} className="spin" /> : null}
          {submitting ? 'Guardando…' : last ? 'Guardar' : 'Siguiente'}
        </button>
      </div>
      {mode === 'start' && allowLater && (
        <button type="button" className="onboarding-later" onClick={onLater} disabled={submitting}>
          Ahora no
        </button>
      )}
      {mode === 'edit' && (
        <button type="button" className="onboarding-later" onClick={onCancel} disabled={submitting}>
          Volver
        </button>
      )}
    </form>
  )

  if (mode === 'edit') return form

  return (
    <section className="onboarding-screen">
      <div className="onboarding-card">
        <Logo />
        {form}
      </div>
    </section>
  )
}
