import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { useCases } from '../data'
import {
  addXp,
  bumpSkill,
  fetchSkillbotData,
  markActivityToday,
  recordChallengeAttempt,
  saveUseCaseProgress,
  toDayString,
  unlockAchievement,
} from '../lib/queries'

const WEEK_LABELS = ['L', 'M', 'X', 'J', 'V', 'S', 'D']

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
  const entries = Object.values(raw.progress)
  const completedCount = entries.filter((x) => x.status === 'completed').length
  const totalCases = useCases.length
  const accumulated = entries.reduce((sum, x) => sum + x.progress, 0)

  return {
    ...raw,
    completedCount,
    totalCases,
    overallProgress: totalCases ? Math.round(accumulated / totalCases) : 0,
    practicedSkills: raw.skills.filter((x) => x.value > 0).length,
    levelProgress: raw.level?.next_xp ? Math.round((raw.profile.xp / raw.level.next_xp) * 100) : 100,
    streak: countStreak(raw.activityDays),
    week: buildWeek(raw.activityDays),
  }
}

export function SkillbotDataProvider({ children }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)

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

  const completeChallenge = useCallback(
    async ({ useCaseSlug, selectedOption, isCorrect, xpReward, skillId }) => {
      await recordChallengeAttempt({
        useCaseSlug,
        selectedOption,
        isCorrect,
        xpEarned: isCorrect ? xpReward : 0,
      })

      if (isCorrect) {
        await Promise.all([
          addXp(xpReward),
          saveUseCaseProgress(useCaseSlug, 100),
          markActivityToday(),
          skillId ? bumpSkill(skillId, 5) : Promise.resolve(),
        ])
      }

      const fresh = derive(await fetchSkillbotData())
      const pending = []
      if (fresh.completedCount >= 1) pending.push('primer-caso')
      if (fresh.streak >= 3) pending.push('racha-3')
      if (Object.keys(fresh.progress).length >= 3) pending.push('explorador')
      if (fresh.completedCount >= 5) pending.push('cinco-casos')

      const toUnlock = pending.filter((id) => !fresh.achievements.find((a) => a.id === id)?.unlocked)
      if (toUnlock.length) {
        await Promise.all(toUnlock.map(unlockAchievement))
        setData(derive(await fetchSkillbotData()))
      } else {
        setData(fresh)
      }
    },
    [],
  )

  const value = useMemo(
    () => ({ data, loading: !data && !error, error, reload, completeChallenge }),
    [data, error, reload, completeChallenge],
  )

  return <SkillbotDataContext.Provider value={value}>{children}</SkillbotDataContext.Provider>
}

export function useSkillbotData() {
  const context = useContext(SkillbotDataContext)
  if (!context) throw new Error('useSkillbotData tiene que usarse dentro de SkillbotDataProvider')
  return context
}
