export function practiceFieldsOf(useCase) {
  const fields = (useCase?.fields ?? []).filter((field) => field.practice)
  const source = fields.length ? fields : (useCase?.fields ?? []).slice(0, 3)
  return [...source].sort((a, b) => (a.practiceOrder ?? 99) - (b.practiceOrder ?? 99))
}

// Misma condición que la pantalla del caso: hay campos para practicar,
// exactamente tres desafíos y una plantilla de pedido.
export function isPracticeReady(useCase) {
  if (!useCase) return false
  const challenges = useCase.challenges ?? []
  return practiceFieldsOf(useCase).length > 0 && challenges.length === 3 && Boolean(useCase.outputTemplate)
}

export function draftIsReady(useCase, values) {
  return practiceFieldsOf(useCase).every((field) => {
    if (!field.required) return true
    return String(values?.[field.key] ?? '').trim().length > 0
  })
}

export function nextChallengeIndex(challenges, donePositions) {
  const done = new Set(donePositions)
  return challenges.findIndex((challenge) => !done.has(challenge.position))
}

export function resumePractice({ useCase, values, doneSteps, donePositions }) {
  const challenges = useCase.challenges ?? []
  const steps = useCase.steps ?? []
  const marked = new Set(doneSteps ?? [])
  if (!draftIsReady(useCase, values)) return { stage: 'context', round: 0 }
  if (steps.length && !steps.every((step) => marked.has(step.position))) return { stage: 'keys', round: 0 }
  const index = nextChallengeIndex(challenges, donePositions ?? [])
  if (index === -1) return { stage: 'done', round: 0 }
  return { stage: 'practice', round: index }
}
