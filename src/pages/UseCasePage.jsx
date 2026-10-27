import { useEffect, useState } from 'react'
import { MessagesSquare } from 'lucide-react'
import { caseIcon } from '../components/icons'
import { CaseGuide } from '../components/CaseGuide'
import { CaseResult } from '../components/CaseResult'
import { DynamicCaseForm } from '../components/DynamicCaseForm'
import { Layout } from '../components/Layout'
import { closingLine, PracticeRound } from '../components/PracticeRound'
import { useSkillbotData } from '../context/SkillbotData'
import { nextChallengeIndex, practiceFieldsOf, resumePractice } from '../lib/practice'
import { fillTemplate, unresolvedPlaceholders } from '../lib/template'
import { clearSession, loadDraft, loadResult, loadSession, rememberCase, saveResult, saveSession } from '../lib/storage'

function openAnswer(useCase, values) {
  const field = practiceFieldsOf(useCase).find((item) => item.type === 'textarea')
  return field ? String(values?.[field.key] ?? '').trim() : ''
}

function buildPrompt(useCase, values) {
  const shown = new Set(practiceFieldsOf(useCase).map((field) => field.key))
  const optionalKeys = useCase.fields
    .filter((field) => !shown.has(field.key) || !field.required)
    .map((field) => field.key)
  return fillTemplate(useCase.outputTemplate, values, optionalKeys).trim()
}

function answeredPositions(useCaseId, serverDone) {
  return [...new Set([...(loadSession(useCaseId).answered ?? []), ...(serverDone ?? [])])]
}

export function UseCasePage({ setPage, useCase, origin, onAsk }) {
  const { data, beginPractice, restartPractice, finishChallenge } = useSkillbotData()
  const Icon = caseIcon(useCase)
  const progress = data.progress[useCase.id]
  const completed = progress?.status === 'completed' || progress?.progress === 100
  const practiceFields = practiceFieldsOf(useCase)
  const practiceCase = { ...useCase, fields: practiceFields }
  const challenges = useCase.challenges ?? []
  const [stage, setStage] = useState('intro')
  const [round, setRound] = useState(0)
  const [earned, setEarned] = useState(0)
  const [awardError, setAwardError] = useState(null)
  const [resultText, setResultText] = useState('')
  const [situation, setSituation] = useState('')
  const [saveError, setSaveError] = useState(null)
  const ready = practiceFields.length > 0 && challenges.length === 3 && Boolean(useCase.outputTemplate)

  useEffect(() => {
    rememberCase(useCase.id)
    setStage('intro')
    setRound(0)
    setEarned(0)
    setAwardError(null)
    setResultText('')
    setSituation('')
    setSaveError(null)
  }, [useCase.id])

  function applyPoint(point) {
    setRound(point.round)
    if (point.stage === 'done') {
      showResult()
      return
    }
    setStage(point.stage)
    saveSession(useCase.id, { stage: point.stage, round: point.round })
  }

  function currentPoint() {
    return resumePractice({
      useCase,
      values: loadDraft(useCase.id),
      doneSteps: data.doneSteps[useCase.id] ?? [],
      donePositions: answeredPositions(useCase.id, data.doneChallenges?.[useCase.id]),
    })
  }

  function start() {
    setSaveError(null)
    if (completed) {
      clearSession(useCase.id)
      setRound(0)
      setEarned(0)
      setStage('context')
      restartPractice(useCase).catch((error) => setSaveError(error))
      return
    }
    applyPoint(currentPoint())
    beginPractice(useCase).catch((error) => setSaveError(error))
  }

  function saveContext(values) {
    const text = buildPrompt(useCase, values)
    if (!text || unresolvedPlaceholders(text).length) {
      setSaveError({ message: 'No se pudo preparar el caso con estos datos.' })
      return
    }
    setSituation(openAnswer(useCase, values))
    setStage('keys')
    saveSession(useCase.id, { stage: 'keys' })
  }

  function showResult() {
    const values = loadDraft(useCase.id) ?? {}
    const text = buildPrompt(useCase, values)
    const stored = !text || unresolvedPlaceholders(text).length ? loadResult(useCase.id)?.text ?? '' : text
    if (stored) saveResult(useCase.id, stored, values)
    setResultText(stored)
    setSituation(openAnswer(useCase, values))
    setStage('done')
    saveSession(useCase.id, { stage: 'done' })
  }

  async function answer(payload) {
    if (payload.isCorrect) {
      const answered = [...answeredPositions(useCase.id, data.doneChallenges?.[useCase.id]), payload.position]
      const next = nextChallengeIndex(challenges, answered)
      saveSession(useCase.id, {
        answered,
        stage: next === -1 ? 'done' : 'practice',
        round: next === -1 ? 0 : next,
      })
    }
    try {
      const xp = await finishChallenge({ useCase, ...payload })
      setEarned((current) => current + xp)
      return xp
    } catch (error) {
      setAwardError(error)
      throw error
    }
  }

  const compact = stage !== 'intro'
  const hideTitle = stage === 'done'

  return (
    <Layout page="detalle" setPage={setPage}>
      <section className="page case-flow">
        <button type="button" className="back" onClick={() => setPage(origin || 'inicio')}>← Volver</button>
        <div className={`case-heading${compact ? ' case-heading-compact' : ''}${hideTitle ? ' case-heading-result' : ''}`}>
          <span className={`hero-tool-icon tool-icon ${useCase.color}`}><Icon size={28} /></span>
          <div>
            <p className="case-kicker">{useCase.category}</p>
            <h1>{useCase.title}</h1>
            <p>{useCase.description}</p>
            <p className="case-facts">{useCase.estimatedTime} · Dificultad {String(useCase.difficulty).toLocaleLowerCase('es')}</p>
            {useCase.learning && <p className="case-outcome">Vas a aprender: {useCase.learning}</p>}
          </div>
        </div>

        {stage === 'intro' && (
          <>
            <article className="example-box">
              <p className="case-kicker">Por ejemplo</p>
              <p>{useCase.situation}</p>
            </article>
            {ready ? (
              <div className="case-actions">
                <button type="button" className="primary" onClick={start}>
                  {completed ? 'Repetir práctica' : progress?.progress > 0 ? 'Continuar práctica' : 'Empezar práctica'}
                </button>
                {completed && loadResult(useCase.id)?.text && (
                  <button type="button" className="secondary" onClick={showResult}>Ver mi pedido</button>
                )}
              </div>
            ) : (
              <p className="save-error">Este caso todavía no tiene la práctica armada.</p>
            )}
            {saveError && <p className="save-error" role="alert">{saveError.message}</p>}
          </>
        )}

        {stage === 'context' && (
          <>
            <h2 className="flow-title">Contanos tu caso</h2>
            <p className="flow-lead">Con esto practicamos sobre tu situación. El pedido se arma después de los desafíos.</p>
            <DynamicCaseForm
              key={`${useCase.id}-context`}
              useCase={practiceCase}
              initialValues={loadDraft(useCase.id)}
              submitLabel="Continuar"
              onSubmit={saveContext}
              onCancel={() => setStage('intro')}
            />
          </>
        )}

        {stage === 'keys' && (
          <CaseGuide
            useCase={useCase}
            onContinue={() => {
              const point = currentPoint()
              applyPoint(point.stage === 'keys' ? { stage: 'practice', round: 0 } : point)
            }}
          />
        )}

        {stage === 'practice' && challenges[round] && (
          <PracticeRound
            key={`${useCase.id}-${round}`}
            challenge={challenges[round]}
            index={round}
            total={challenges.length}
            onAnswer={answer}
            onContinue={() => {
              const next = nextChallengeIndex(challenges, answeredPositions(useCase.id, data.doneChallenges?.[useCase.id]))
              if (next === -1) showResult()
              else {
                setRound(next)
                saveSession(useCase.id, { stage: 'practice', round: next })
              }
            }}
          />
        )}

        {stage === 'done' && (
          <>
            <section className="practice-close">
              <h2>Práctica completada</h2>
              <p>Terminaste los 3 desafíos y ya sabés qué mirar antes de confiar en un pedido o en una respuesta de IA.</p>
              <ul>
                {challenges.map((challenge) => <li key={challenge.position}>✓ {closingLine(challenge)}</li>)}
              </ul>
              {earned > 0 ? (
                <p className="earned">+{earned} XP</p>
              ) : awardError ? (
                <p className="result-note">Terminaste la práctica. El XP no se pudo guardar: falta aplicar la migración de desafíos. Cuando esté, repetí la práctica para sumarlo una sola vez.</p>
              ) : (
                <p className="result-note">Esta práctica no sumó XP nuevo. La recompensa de cada desafío se entrega una sola vez.</p>
              )}
            </section>
            {resultText && (
              <CaseResult
                text={resultText}
                situation={situation}
                tools={useCase.tools}
                saveError={saveError}
                onEdit={() => setStage('context')}
                onBack={() => setStage('intro')}
              />
            )}
          </>
        )}

        <aside className="case-ask">
          <span><MessagesSquare size={18} /></span>
          <div>
            <b>¿Te trabaste con este caso?</b>
            <p>Preguntá en la comunidad: otros usuarios pueden ayudarte.</p>
          </div>
          <button type="button" className="secondary" onClick={() => onAsk(useCase.id)}>Preguntar</button>
        </aside>
      </section>
    </Layout>
  )
}
