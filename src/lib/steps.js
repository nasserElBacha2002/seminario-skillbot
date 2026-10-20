export function stepStates(useCase, doneSteps) {
  const done = new Set(doneSteps)
  let blockedBy = null
  const steps = useCase.steps.map((step) => {
    const state = { ...step, done: done.has(step.position), locked: blockedBy !== null }
    if (step.gate && !state.done && blockedBy === null) blockedBy = step.position
    return state
  })
  return { steps, blockedBy }
}
