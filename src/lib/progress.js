import { isPracticeReady } from './practice.js'

// El porcentaje sale solo de las prácticas que se pueden terminar.
// Una ficha nueva no agranda el denominador ni el numerador.
export function summarizePracticeProgress(useCases, progress) {
  const practices = (useCases ?? []).filter(isPracticeReady)
  const ids = new Set(practices.map((item) => item.id))
  let accumulated = 0
  let completedCount = 0
  for (const [id, entry] of Object.entries(progress ?? {})) {
    if (!ids.has(id) || !entry) continue
    accumulated += Number(entry.progress) || 0
    if (entry.status === 'completed') completedCount += 1
  }
  const totalCases = practices.length
  return {
    completedCount,
    totalCases,
    overallProgress: totalCases ? Math.round(accumulated / totalCases) : 0,
  }
}
