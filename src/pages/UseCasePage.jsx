import { useEffect, useState } from 'react'
import { MessagesSquare } from 'lucide-react'
import { caseIcon } from '../components/icons'
import { ContextFormPager } from '../components/ContextFormPager'
import { FichaPager } from '../components/FichaPager'
import { GuidePager } from '../components/GuidePager'
import { PracticeDonePager } from '../components/PracticeDonePager'
import { Layout } from '../components/Layout'
import { PracticeRound } from '../components/PracticeRound'
import { useSkillbotData } from '../context/SkillbotData'
import { isPracticeReady, nextChallengeIndex, practiceFieldsOf, resumePractice } from '../lib/practice'
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

// En una repetición los desafíos ya pagados en la base no cuentan: se vuelven a jugar los tres.
function answeredPositions(useCaseId, serverDone) {
  const session = loadSession(useCaseId)
  const fromServer = session.repeat ? [] : serverDone ?? []
  return [...new Set([...(session.answered ?? []), ...fromServer])]
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
  const ready = isPracticeReady(useCase)

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
      saveSession(useCase.id, { repeat: true, stage: 'context' })
      setRound(0)
      setEarned(0)
      setStage('context')
      restartPractice(useCase).catch((error) => setSaveError(error))
      return
    }
    // El formulario se muestra siempre antes de los pasos, precargado con el borrador.
    const point = currentPoint()
    applyPoint(point.stage === 'keys' ? { stage: 'context', round: 0 } : point)
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

  // Próximo desafío sin resolver después del actual, dando la vuelta. No cuenta el actual,
  // así un error permite saltearlo y volver a él al final.
  function pendingAfter(from) {
    const done = new Set(answeredPositions(useCase.id, data.doneChallenges?.[useCase.id]))
    for (let step = 1; step < challenges.length; step += 1) {
      const index = (from + step) % challenges.length
      if (!done.has(challenges[index].position)) return index
    }
    return -1
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
    let xp
    try {
      xp = await finishChallenge({ useCase, ...payload })
    } catch (error) {
      setAwardError(error)
      throw error
    }
    // Recién con la base confirmada el desafío cuenta como resuelto en este dispositivo.
    if (payload.isCorrect) {
      const answered = [...answeredPositions(useCase.id, data.doneChallenges?.[useCase.id]), payload.position]
      const next = nextChallengeIndex(challenges, answered)
      saveSession(useCase.id, {
        answered,
        stage: next === -1 ? 'done' : 'practice',
        round: next === -1 ? 0 : next,
      })
    }
    setEarned((current) => current + xp)
    return xp
  }

  const isIntroPager = stage === 'intro'
  const isImmersiveFlow = stage === 'intro' || stage === 'context' || stage === 'keys' || stage === 'practice' || stage === 'done'
  const introVariant = ready ? 'practice' : 'ficha'
  const exitToOrigin = () => setPage(origin || 'inicio')

  const caseHeading = (
    <div className={`case-heading${stage !== 'intro' ? ' case-heading-compact' : ''}`}>
      <span className={`hero-tool-icon tool-icon ${useCase.color}`}><Icon size={28} /></span>
      <div>
        {useCase.areaName && <p className="case-kicker">{useCase.areaName}</p>}
        <h1>{useCase.title}</h1>
        <p>{useCase.description}</p>
        <div className="case-meta-pills">
          <span>{useCase.estimatedTime}</span>
          <span>Dificultad {String(useCase.difficulty).toLocaleLowerCase('es')}</span>
        </div>
        {useCase.learning && !isIntroPager && (
          <p className="case-goal"><strong>Objetivo.</strong> {useCase.learning}</p>
        )}
      </div>
    </div>
  )

  const caseAsk = (
    <aside className="case-ask">
      <span><MessagesSquare size={18} /></span>
      <div>
        <b>¿Te trabaste con este caso?</b>
        <p>Preguntá en la comunidad: otros usuarios pueden ayudarte.</p>
      </div>
      <button type="button" className="secondary" onClick={() => onAsk(useCase.id)}>Preguntar</button>
    </aside>
  )

  return (
    <Layout page="detalle" setPage={setPage}>
      <section className={`page case-flow${isImmersiveFlow ? ' case-intro-pager' : ''}`}>
        {!isImmersiveFlow && (
          <button type="button" className="back" onClick={exitToOrigin}>← Volver</button>
        )}

        {isIntroPager ? (
          <>
            <FichaPager
              variant={introVariant}
              useCase={useCase}
              onAsk={onAsk}
              onExit={exitToOrigin}
              onStart={start}
              startLabel={
                completed ? 'Repetir práctica' : progress?.progress > 0 ? 'Continuar práctica' : 'Empezar práctica'
              }
              onShowResult={
                completed && loadResult(useCase.id)?.text ? showResult : undefined
              }
            />
            {saveError && <p className="save-error" role="alert">{saveError.message}</p>}
          </>
        ) : !isImmersiveFlow ? (
          caseHeading
        ) : null}

        {stage === 'context' && (
          <ContextFormPager
            key={`${useCase.id}-context-pager`}
            useCase={practiceCase}
            initialValues={loadDraft(useCase.id)}
            onSubmit={saveContext}
            onExit={exitToOrigin}
            onBackIntro={() => setStage('intro')}
          />
        )}

        {stage === 'keys' && (
          <GuidePager
            useCase={useCase}
            onExit={exitToOrigin}
            onBackIntro={() => setStage('context')}
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
            hasPendingOther={pendingAfter(round) !== -1}
            onExit={exitToOrigin}
            onBack={() => setStage('keys')}
            onAnswer={answer}
            onContinue={() => {
              const next = pendingAfter(round)
              if (next !== -1) {
                setRound(next)
                saveSession(useCase.id, { stage: 'practice', round: next })
              } else if (nextChallengeIndex(challenges, answeredPositions(useCase.id, data.doneChallenges?.[useCase.id])) === -1) {
                showResult()
              }
            }}
          />
        )}

        {stage === 'done' && (
          <PracticeDonePager
            useCase={useCase}
            challenges={challenges}
            earned={earned}
            awardError={awardError}
            resultText={resultText}
            situation={situation}
            tools={useCase.tools}
            saveError={saveError}
            onExit={exitToOrigin}
            onEdit={() => setStage('context')}
            onBackIntro={() => setStage('intro')}
          />
        )}

        {!isImmersiveFlow && caseAsk}
      </section>
    </Layout>
  )
}
