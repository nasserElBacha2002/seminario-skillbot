import { isPracticeReady } from './practice.js'

// Pesos: problemas 40, objetivo 25, área 20, herramientas 6 + experiencia 4, tiempo 5.
// Ningún criterio saca un caso de la lista. Un área elegida no alcanza para
// quedarse con todos los casos de esa área.

const PROBLEM_MAX = 40
const GOAL_MAX = 25
const AREA_MAX = 20
const TOOL_MAX = 6
const EXPERIENCE_MAX = 4
const TIME_MAX = 5

const EXPERIENCE_RANK = { nunca: 0, alguna_vez: 1, seguido: 2, en_el_negocio: 3 }

// Tope de la franja: el usuario puede hacer un caso más corto.
// mas_de_60 no tiene techo.
const TIME_CAPACITY = { menos_15: 15, de_15_a_30: 30, de_30_a_60: 60, mas_de_60: Infinity }

// El catálogo de tools usa `diseno` para Canva. Las etiquetas de onboarding usan `canva`.
const TOOL_ALIASES = { diseno: 'canva' }

export const BUSINESS_AREAS = [
  { id: 'marketing', label: 'Marketing' },
  { id: 'finanzas', label: 'Finanzas' },
  { id: 'administracion', label: 'Administración' },
]

const REASON_ORDER = ['problem', 'goal', 'area', 'tool', 'experience', 'time']

function list(value) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string' && item) : []
}

function allowed(options, kind) {
  const values = options?.[kind]
  if (!Array.isArray(values) || !values.length) return null
  return new Set(values.map((option) => option.value))
}

function knownMany(options, kind, values) {
  const vocabulary = allowed(options, kind)
  const items = list(values)
  return vocabulary ? items.filter((item) => vocabulary.has(item)) : items
}

function knownOne(options, kind, value) {
  if (typeof value !== 'string' || !value) return ''
  const vocabulary = allowed(options, kind)
  if (vocabulary && !vocabulary.has(value)) return ''
  return value
}

function tags(useCase, kind) {
  return (useCase?.tags ?? []).filter((tag) => tag?.kind === kind && typeof tag.value === 'string').map((tag) => tag.value)
}

function unique(values) {
  return [...new Set(values)]
}

function caseAreas(useCase) {
  const areas = []
  if (typeof useCase?.area === 'string' && useCase.area) areas.push(useCase.area)
  areas.push(...tags(useCase, 'area'))
  return unique(areas)
}

function canonicalTool(value) {
  return TOOL_ALIASES[value] ?? value
}

function overlap(left, right) {
  const set = new Set(right)
  return left.filter((value) => set.has(value))
}

function experiencePoints(userLevel, caseLevels) {
  if (userLevel == null || !caseLevels.length) return 0
  const caseLevel = Math.max(...caseLevels)
  const gap = caseLevel - userLevel
  if (gap <= 0) return EXPERIENCE_MAX
  if (gap === 1) return 2
  return 1
}

function timePoints(capacity, minutes) {
  if (!Number.isFinite(capacity) && capacity !== Infinity) return 0
  if (typeof minutes !== 'number' || !Number.isFinite(minutes) || minutes <= 0) return 0
  if (capacity === Infinity || minutes <= capacity) return TIME_MAX
  return TIME_MAX * (capacity / minutes)
}

function scoreCase(useCase, profile) {
  const problemHits = overlap(profile.problems, unique(tags(useCase, 'problem')))
  // El primer problema que coincide vale la mitad del peso. El resto se reparte
  // según la fracción de dificultades del usuario que el caso cubre. Así una
  // coincidencia concreta supera a un caso que solo comparte el área, y tener
  // más etiquetas sin coincidir no suma.
  const problemCoverage = profile.problems.length ? problemHits.length / profile.problems.length : 0
  const problems = problemHits.length ? PROBLEM_MAX * (0.5 + 0.5 * problemCoverage) : 0

  const goalHit = profile.goal && tags(useCase, 'goal').includes(profile.goal)
  const goal = goalHit ? GOAL_MAX : 0

  const areaHits = overlap(profile.areas, caseAreas(useCase))
  const area = profile.areas.length ? (areaHits.length / profile.areas.length) * AREA_MAX : 0

  const caseTools = unique(tags(useCase, 'tool').map(canonicalTool).filter((value) => value !== 'ninguna'))
  const toolHits = overlap(profile.tools, caseTools)
  const tools = profile.tools.length && toolHits.length ? (toolHits.length / profile.tools.length) * TOOL_MAX : 0

  const caseExperience = tags(useCase, 'experience').map((value) => EXPERIENCE_RANK[value]).filter((rank) => rank != null)
  const experience = experiencePoints(profile.experience, caseExperience)

  const capacity = TIME_CAPACITY[profile.time]
  const time = capacity == null ? 0 : timePoints(capacity, useCase?.minutes)

  const compatibility = tools + experience
  const score = problems + goal + area + compatibility + time
  const reasons = [
    ...problemHits.map((value) => ({ kind: 'problem', value })),
    ...(goalHit ? [{ kind: 'goal', value: profile.goal }] : []),
    ...areaHits.map((value) => ({ kind: 'area', value })),
    ...toolHits.map((value) => ({ kind: 'tool', value })),
    ...(experience > 0 ? [{ kind: 'experience', value: profile.experienceId }] : []),
    ...(time > 0 ? [{ kind: 'time', value: profile.time }] : []),
  ]

  return {
    id: useCase.id,
    score,
    breakdown: { problems, goal, area, compatibility, time },
    reasons,
    practiceReady: isPracticeReady(useCase),
    sortOrder: Number.isFinite(useCase?.sortOrder) ? useCase.sortOrder : Number.MAX_SAFE_INTEGER,
  }
}

function profileFrom(answers, options) {
  const source = answers ?? {}
  const experienceId = knownOne(options, 'experience', source.aiExperience)
  return {
    areas: unique(knownMany(options, 'area', source.areas)),
    problems: unique(knownMany(options, 'problem', source.problems)),
    tools: unique(knownMany(options, 'tool', source.tools).map(canonicalTool).filter((value) => value !== 'ninguna')),
    goal: knownOne(options, 'goal', source.primaryGoal),
    time: knownOne(options, 'time', source.availableTime),
    experienceId,
    experience: Object.prototype.hasOwnProperty.call(EXPERIENCE_RANK, experienceId) ? EXPERIENCE_RANK[experienceId] : null,
  }
}

export function hasRecommendationInput(answers) {
  if (!answers) return false
  const tools = list(answers.tools).filter((value) => value !== 'ninguna')
  return Boolean(
    list(answers.areas).length
    || list(answers.problems).length
    || tools.length
    || answers.aiExperience
    || answers.primaryGoal
    || answers.availableTime
  )
}

export function rankUseCases(answers, useCases, options) {
  const profile = profileFrom(answers, options)
  return (useCases ?? [])
    .filter((item) => item?.id)
    .map((item) => scoreCase(item, profile))
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score
      if (left.sortOrder !== right.sortOrder) return left.sortOrder - right.sortOrder
      return String(left.id).localeCompare(String(right.id))
    })
    .map(({ sortOrder, ...item }, index) => ({ ...item, position: index + 1 }))
}

export function primaryReason(entry) {
  if (!entry?.reasons?.length) return null
  return REASON_ORDER.map((kind) => entry.reasons.find((reason) => reason.kind === kind)).find(Boolean) ?? null
}

function labelFor(options, kind, value) {
  return (options?.[kind] ?? []).find((option) => option.value === value)?.label ?? ''
}

function lowerFirst(label) {
  if (!label) return ''
  return label.charAt(0).toLocaleLowerCase('es') + label.slice(1)
}

export function recommendationText(reason, options) {
  if (!reason) return ''
  const label = labelFor(options, reason.kind === 'experience' ? 'experience' : reason.kind, reason.value)
  if (reason.kind === 'problem') {
    return label ? `Te recomendamos este caso porque marcaste «${label}».` : ''
  }
  if (reason.kind === 'goal') {
    return label ? `Coincide con tu objetivo de ${lowerFirst(label)}.` : ''
  }
  if (reason.kind === 'area') {
    return label ? `Está relacionado con tu interés en ${label}.` : ''
  }
  if (reason.kind === 'tool') {
    return label ? `Tiene en cuenta que usás ${label}.` : ''
  }
  if (reason.kind === 'experience') return 'Se puede hacer con la experiencia que tenés usando IA.'
  if (reason.kind === 'time') return 'Entra en el tiempo que podés dedicarle.'
  return ''
}
