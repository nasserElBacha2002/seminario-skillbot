import { useState } from 'react'
import { Check, Copy, Lock, TriangleAlert } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { copyText } from '../lib/clipboard'
import { stepStates } from '../lib/steps'

export function CaseSteps({ useCase }) {
  const { data, toggleStep } = useSkillbotData()
  const [copied, setCopied] = useState(null)
  const [copyError, setCopyError] = useState(null)
  const [busy, setBusy] = useState(null)
  const [saveError, setSaveError] = useState(null)
  const { steps, blockedBy } = stepStates(useCase, data.doneSteps[useCase.id])

  async function copy(position, text) {
    setCopyError(null)
    const ok = await copyText(text)
    if (!ok) {
      setCopyError(position)
      setCopied(null)
      return
    }
    setCopied(position)
    setTimeout(() => setCopied((current) => (current === position ? null : current)), 1600)
  }

  async function toggle(step) {
    if (step.locked || busy !== null) return
    setBusy(step.position)
    setSaveError(null)
    try {
      await toggleStep({ useCase, position: step.position, done: !step.done })
    } catch (error) {
      setSaveError(error)
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="guide-checks">
      <ol className="guide-steps">
        {steps.map((step) => (
          <li key={step.position} className={`guide-step ${step.done ? 'done' : ''} ${step.locked ? 'locked' : ''}`}>
            <b aria-hidden="true">{step.done ? <Check size={14} /> : step.position}</b>
            <div>
              <p>{step.body}</p>
              {step.prompt && (
                <div className="step-prompt">
                  <p>“{step.prompt}”</p>
                  <button type="button" onClick={() => copy(step.position, step.prompt)}>
                    <Copy size={14} />{copied === step.position ? 'Copiado' : 'Copiar ejemplo'}
                  </button>
                </div>
              )}
              {copyError === step.position && <small className="field-error">No se pudo copiar. Seleccioná el texto del ejemplo.</small>}
              {step.locked ? (
                <small className="step-locked"><Lock size={12} /> Confirmá el paso {blockedBy} para seguir.</small>
              ) : (
                <button
                  type="button"
                  className={`step-toggle ${step.done ? 'checked' : ''}`}
                  disabled={busy !== null}
                  onClick={() => toggle(step)}
                >
                  <i>{step.done && <Check size={13} />}</i>
                  {busy === step.position ? 'Guardando…' : step.done ? 'Listo' : (step.gate ?? 'Listo')}
                </button>
              )}
            </div>
          </li>
        ))}
      </ol>
      {saveError && <p className="save-error"><TriangleAlert size={15} /> No se pudo guardar el paso: {saveError.message}</p>}
    </div>
  )
}
