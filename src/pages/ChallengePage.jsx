import { useState } from 'react'
import { ArrowRight, Check, Lightbulb, LoaderCircle, RotateCcw, Sparkles, Trophy, UserRound, Zap } from 'lucide-react'
import { Layout } from '../components/Layout'
import { useSkillbotData } from '../context/SkillbotData'

export function ChallengePage({ setPage, useCase }) {
  const { completeChallenge } = useSkillbotData()
  const challenge = useCase.challenge
  const [selected, setSelected] = useState(null)
  const [result, setResult] = useState(null)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const option = challenge.options.find((item) => item.letter === selected)

  async function confirm() {
    setSaving(true)
    setSaveError(null)
    try {
      const xp = await completeChallenge({ useCase, selectedOption: selected, isCorrect: option.is_correct })
      setResult({ correct: option.is_correct, feedback: option.feedback, xp })
    } catch (error) {
      setSaveError(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout page="desafio" setPage={setPage}>
      <section className="page challenge-page">
        <div className="challenge-top">
          <button type="button" className="back" onClick={() => setPage('detalle')}>← Volver al caso</button>
          <span className="challenge-xp"><Zap size={16} fill="currentColor" /> Práctica opcional</span>
        </div>
        <div className="challenge-content">
          <div className="challenge-label"><Sparkles size={18} /> PRACTICAR LO APRENDIDO</div>
          <h1>{challenge.title}</h1>
          <p className="flow-lead">Este ejercicio no hace falta para usar el resultado que ya generaste.</p>
          <article className="scenario">
            <span><UserRound size={23} /></span>
            <div>
              <p className="eyebrow">EL ESCENARIO</p>
              <p>{challenge.scenario}</p>
            </div>
          </article>
          {!result ? (
            <>
              <h2>{challenge.question}</h2>
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
              {saveError && <p className="save-error">No se pudo guardar tu respuesta: {saveError.message}</p>}
              <button type="button" className="primary confirm" disabled={!selected || saving} onClick={confirm}>
                {saving ? <>Guardando… <LoaderCircle size={17} className="spin" /></> : <>Confirmar respuesta <ArrowRight size={17} /></>}
              </button>
            </>
          ) : (
            <Feedback {...result} onRetry={() => { setSelected(null); setResult(null) }} onBack={() => setPage('detalle')} onProgress={() => setPage('progreso')} />
          )}
        </div>
      </section>
    </Layout>
  )
}

function Feedback({ correct, feedback, xp, onRetry, onBack, onProgress }) {
  return (
    <div className={`feedback ${correct ? 'success' : 'gentle'}`}>
      <span className="feedback-icon">{correct ? <Trophy size={34} /> : <Lightbulb size={32} />}</span>
      <div>
        <p className="eyebrow">{correct ? 'LISTO' : 'BUENA OPORTUNIDAD PARA AJUSTAR EL PEDIDO'}</p>
        <h2>{correct ? 'Esa opción pide mejor el resultado.' : 'Casi, mirá este detalle.'}</h2>
        <p>{feedback}</p>
        {correct && (xp > 0
          ? <span className="earned"><Zap size={17} fill="currentColor" /> +{xp} XP</span>
          : <p className="feedback-note">Este caso ya estaba resuelto, así que esta práctica no suma XP.</p>)}
        <div className="case-actions">
          {correct
            ? <button type="button" className="primary" onClick={onBack}>Volver al caso <ArrowRight size={17} /></button>
            : <button type="button" className="primary" onClick={onRetry}><RotateCcw size={16} /> Intentar de nuevo</button>}
          <button type="button" className="text-button" onClick={onProgress}>Ver progreso</button>
        </div>
      </div>
    </div>
  )
}
