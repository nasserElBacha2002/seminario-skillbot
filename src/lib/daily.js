import { isPracticeReady } from './practice.js'

// Un caso por día, estable para el mismo catálogo y la misma fecha.
// Solo entran prácticas que se pueden completar. Una ficha nunca sale.
export function caseOfTheDay(useCases, date = new Date()) {
  const practices = (useCases ?? []).filter(isPracticeReady)
  if (!practices.length) return null
  const sorted = [...practices].sort((a, b) => String(a.id).localeCompare(String(b.id)))
  const day = Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86400000)
  return sorted[day % sorted.length]
}
