import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'
import {
  clearCaseSteps,
  completePracticeChallenge,
  fetchSkillbotData,
  markActivityToday,
  saveUseCaseProgress,
  setStepDone,
  toDayString,
  unlockAchievement,
} from '../lib/queries'

const WEEK_LABELS = ['L', 'M', 'X', 'J', 'V', 'S', 'D']

// Los pasos llevan el caso hasta este porcentaje; el 100% solo se alcanza
// resolviendo el desafio.
const STEPS_PROGRESS_CAP = 80

const SkillbotDataContext = createContext(null)

function countStreak(activityDays) {
  const days = new Set(activityDays)
  const cursor = new Date()
  // La racha sigue viva si se practico hoy o si se practico ayer y el dia
  // todavia no se registro.
  if (!days.has(toDayString(cursor))) cursor.setDate(cursor.getDate() - 1)
  let streak = 0
  while (days.has(toDayString(cursor))) {
    streak += 1
    cursor.setDate(cursor.getDate() - 1)
  }
  return streak
}

function buildWeek(activityDays) {
  const days = new Set(activityDays)
  const today = new Date()
  const offsetFromMonday = (today.getDay() + 6) % 7
  return WEEK_LABELS.map((label, index) => {
    const date = new Date(today)
    date.setDate(today.getDate() - offsetFromMonday + index)
    return { label, done: days.has(toDayString(date)) }
  })
}

function derive(raw) {
  // Un caso que paso a reserva deja de venir en el catalogo; su progreso no cuenta.
  const caseIds = new Set(raw.useCases.map((x) => x.id))
  const progress = Object.fromEntries(Object.entries(raw.progress).filter(([id]) => caseIds.has(id)))
  const entries = Object.values(progress)
  const completedCount = entries.filter((x) => x.status === 'completed').length
  const totalCases = raw.useCases.length
  const accumulated = entries.reduce((sum, x) => sum + x.progress, 0)

  return {
    ...raw,
    progress,
    completedCount,
    totalCases,
    overallProgress: totalCases ? Math.round(accumulated / totalCases) : 0,
    practicedSkills: raw.skills.filter((x) => x.value > 0).length,
    levelProgress: raw.level?.next_xp ? Math.round((raw.profile.xp / raw.level.next_xp) * 100) : 100,
    streak: countStreak(raw.activityDays),
    week: buildWeek(raw.activityDays),
  }
}

async function loadWithAchievements() {
  const fresh = derive(await fetchSkillbotData())
  const pending = []
  if (fresh.completedCount >= 1) pending.push('primer-caso')
  if (fresh.streak >= 3) pending.push('racha-3')
  if (Object.keys(fresh.progress).length >= 3) pending.push('explorador')
  if (fresh.completedCount >= 5) pending.push('cinco-casos')

  const toUnlock = pending.filter((id) => !fresh.achievements.find((a) => a.id === id)?.unlocked)
  if (!toUnlock.length) return fresh
  await Promise.all(toUnlock.map(unlockAchievement))
  return derive(await fetchSkillbotData())
}

export function SkillbotDataProvider({ children }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)
  const dataRef = useRef(null)
  dataRef.current = data

  const reload = useCallback(async () => {
    try {
      setError(null)
      setData(derive(await fetchSkillbotData()))
    } catch (e) {
      setError(e)
    }
  }, [])

  useEffect(() => {
    reload()
  }, [reload])

  const toggleStep = useCallback(async ({ useCase, position, done }) => {
    const current = dataRef.current
    await setStepDone(useCase.id, position, done)

    const previous = new Set(current.doneSteps[useCase.id] ?? [])
    if (done) previous.add(position)
    else previous.delete(position)

    const writes = [markActivityToday()]
    if (current.progress[useCase.id]?.status !== 'completed') {
      const value = Math.round((previous.size / useCase.steps.length) * STEPS_PROGRESS_CAP)
      writes.push(saveUseCaseProgress(useCase.id, value))
    }
    await Promise.all(writes)
    setData(await loadWithAchievements())
  }, [])

  const beginPractice = useCallback(async (useCase) => {
    const current = dataRef.current
    if (current?.progress[useCase.id]?.status === 'completed') return
    const currentProgress = current?.progress[useCase.id]?.progress ?? 0
    await saveUseCaseProgress(useCase.id, Math.max(currentProgress, 10))
    await markActivityToday()
    setData(await loadWithAchievements())
  }, [])

  const restartPractice = useCallback(async (useCase) => {
    await clearCaseSteps(useCase.id)
    await saveUseCaseProgress(useCase.id, 10)
    await markActivityToday()
    setData(await loadWithAchievements())
  }, [])

  // El XP lo decide la base, una vez por desafío. Copiar o abrir una IA no pasa por acá.
  const finishChallenge = useCallback(async ({ useCase, position, selectedOption, isCorrect }) => {
    if (!isCorrect) return 0
    const awarded = await completePracticeChallenge({
      useCaseId: useCase.id,
      position,
      selected: selectedOption,
      correct: true,
      day: toDayString(new Date()),
    })
    setData(await loadWithAchievements())
    return Number(awarded) || 0
  }, [])

  const value = useMemo(
    () => ({ data, loading: !data && !error, error, reload, toggleStep, beginPractice, restartPractice, finishChallenge }),
    [data, error, reload, toggleStep, beginPractice, restartPractice, finishChallenge],
  )

  return <SkillbotDataContext.Provider value={value}>{children}</SkillbotDataContext.Provider>
}

export function useSkillbotData() {
  const context = useContext(SkillbotDataContext)
  if (!context) throw new Error('useSkillbotData tiene que usarse dentro de SkillbotDataProvider')
  return context
}
