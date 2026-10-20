// Un caso por día, estable para todos los que usen el mismo catálogo.
export function caseOfTheDay(useCases, date = new Date()) {
  if (!useCases?.length) return null
  const sorted = [...useCases].sort((a, b) => String(a.id).localeCompare(String(b.id)))
  const day = Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86400000)
  return sorted[day % sorted.length]
}
