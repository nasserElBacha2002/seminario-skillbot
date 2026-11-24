import { practiceFieldsOf } from './practice.js'

function normalizeText(text) {
  return String(text ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function wordSet(text) {
  const normalized = normalizeText(text)
  if (!normalized) return new Set()
  return new Set(normalized.split(' ').filter((word) => word.length > 2))
}

export function textOverlapRatio(a, b) {
  const left = wordSet(a)
  const right = wordSet(b)
  if (!left.size || !right.size) return 0
  let shared = 0
  for (const word of left) {
    if (right.has(word)) shared += 1
  }
  return shared / Math.min(left.size, right.size)
}

export function shouldSkipScenarioSlide(useCase) {
  if (!useCase?.situation) return true
  return textOverlapRatio(useCase.description, useCase.situation) >= 0.42
}

export function shouldSkipObjectiveSlide(useCase) {
  if (!useCase?.learning) return true
  return textOverlapRatio(useCase.description, useCase.learning) >= 0.5
}

export function isCondensedPracticeGuide(useCase) {
  const challenges = useCase?.challenges ?? []
  return Boolean(useCase?.outputTemplate) && challenges.length === 3 && practiceFieldsOf(useCase).length > 0
}

/** Agrupa pasos largos en bloques de ~3 pantallas para el pager guiado. */
export function guideStepGroups(steps) {
  if (!steps?.length) return []
  if (steps.length <= 4) {
    return steps.map((step) => ({
      kind: 'step',
      positions: [step.position],
      position: step.position,
      total: steps.length,
    }))
  }
  const targetScreens = 3
  const groupSize = Math.max(2, Math.ceil(steps.length / targetScreens))
  const groups = []
  for (let index = 0; index < steps.length; index += groupSize) {
    const chunk = steps.slice(index, index + groupSize)
    const from = chunk[0].position
    const to = chunk[chunk.length - 1].position
    groups.push({
      kind: 'step-group',
      positions: chunk.map((step) => step.position),
      position: from,
      to,
      total: steps.length,
      label: chunk.length > 1 ? `Pasos ${from} a ${to}` : `Paso ${from}`,
    })
  }
  return groups
}

const PAGER_OPTIONAL_KEYS = new Set(['filas', 'idioma', 'cantidad_filas', 'filas_aprox'])

function situationText(values, fields) {
  const textarea = fields.find((field) => field.type === 'textarea')
  if (textarea) return String(values?.[textarea.key] ?? '').trim()
  return String(values?.situacion ?? values?.objetivo ?? values?.contexto ?? '').trim()
}

export function contextFieldsForPager(useCase, values = {}) {
  const fields = practiceFieldsOf(useCase)
  const situation = situationText(values, fields)
  return fields.filter((field) => {
    if (!field.required && PAGER_OPTIONAL_KEYS.has(field.key)) return false
    if (field.key === 'filas' && /\d+\s*(filas|registros|ventas|renglones)/i.test(situation)) return false
    return true
  })
}

export const CHALLENGE_CLOSING = {
  detect_error: 'Detectaste un pedido incompleto',
  missing_information: 'Identificaste qué información faltaba',
  judge_result: 'Evaluaste críticamente una respuesta de IA',
}

export function challengeClosingLine(challenge) {
  return CHALLENGE_CLOSING[challenge.type] || challenge.title
}

export const CHALLENGE_TONE = {
  detect_error: 'mistake',
  missing_information: 'objective',
  judge_result: 'tool',
}