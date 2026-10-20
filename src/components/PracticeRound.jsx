import { useState } from 'react'
import { ArrowRight, Check, LoaderCircle } from 'lucide-react'

const CLOSING = {
  detect_error: 'Detectaste un pedido incompleto',
  missing_information: 'Identificaste qué información faltaba',
  judge_result: 'Evaluaste críticamente una respuesta de IA',
}

export function closingLine(challenge) {
  return CLOSING[challenge.type] || challenge.title
}

export function PracticeRound({ challenge, index, total, onAnswer, onContinue }) {
  const [selected, setSelected] = useState(null)
  const [result, setResult] = useState(null)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const option = challenge.options.find((item) => item.letter === selected)
  const last = index === total - 1

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
    } finally {
      setSaving(false)
    }
    const feedback = option.feedback || (option.is_correct ? challenge.feedbackCorrect : challenge.feedbackIncorrect)
    setResult({ correct: option.is_correct, feedback, xp })
  }

  return (
    <div className="practice-round">
      <div className="practice-progress" aria-label={`Desafío ${index + 1} de ${total}`}>
        <span>Desafío {index + 1} de {total}</span>
        <i>
          {Array.from({ length: total }, (_, dot) => (
            <b key={dot} className={dot <= index ? 'on' : ''} />
          ))}
        </i>
      </div>
      <h2 className="flow-title">{challenge.title}</h2>
      <p className="flow-lead">{challenge.instruction}</p>
      <article className="scenario practice-scenario">
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
              {/complete_practice_challenge|PGRST202/i.test(String(saveError.message ?? '')) && ' Falta aplicar la migración 20261021010000_practice_challenges.sql.'}
            </p>
          )}
          <button type="button" className="primary confirm" disabled={!selected || saving} onClick={confirm}>
            {saving ? <>Guardando… <LoaderCircle size={17} className="spin" /></> : <>Ver feedback <ArrowRight size={17} /></>}
          </button>
        </>
      ) : (
        <div className={`feedback ${result.correct ? 'success' : 'gentle'}`}>
          <div>
            <h2>{result.correct ? 'Bien visto' : 'Mirá este detalle'}</h2>
            <p>{result.feedback}</p>
            {result.xp > 0 && <p className="earned">+{result.xp} XP</p>}
            <div className="case-actions">
              <button type="button" className="primary" onClick={onContinue}>
                {last ? 'Ver el cierre' : 'Siguiente desafío'} <ArrowRight size={17} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
