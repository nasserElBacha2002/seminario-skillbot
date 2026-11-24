export function fichaSuccessChecks(useCase) {
  const checks = []
  if (useCase?.learning) checks.push(useCase.learning)
  const lastStep = useCase?.steps?.[useCase.steps.length - 1]
  for (const item of lastStep?.checklist ?? []) {
    if (item && !checks.includes(item)) checks.push(item)
  }
  if (useCase?.mistake) {
    checks.push(`Evitaste el error típico: ${useCase.mistake.charAt(0).toLocaleLowerCase('es')}${useCase.mistake.slice(1)}`)
  }
  return checks.slice(0, 4)
}

export function fichaFallbackActions(useCase, toolName = 'tu asistente de IA') {
  const actions = []
  if (useCase?.situation) {
    actions.push('Reuní los datos de tu caso real (números, plazos o mensajes) en una nota o planilla.')
  }
  if (toolName) {
    actions.push(`Abrí ${toolName} y contale tu situación con esos datos. No le pidas que entre a cuentas que no conectaste.`)
  }
  if (useCase?.description) {
    actions.push(`Pedile que te ayude con esto: ${useCase.description.charAt(0).toLocaleLowerCase('es')}${useCase.description.slice(1)}`)
  }
  if (useCase?.learning) {
    actions.push(`Revisá la respuesta: tiene que acercarte a ${useCase.learning.charAt(0).toLocaleLowerCase('es')}${useCase.learning.slice(1)}`)
  }
  return actions.slice(0, 4)
}