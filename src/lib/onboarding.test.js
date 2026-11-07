import assert from 'node:assert/strict'
import test from 'node:test'
import {
  STEPS,
  answersFromRow,
  canPostponeOnboarding,
  emptyAnswers,
  problemGroups,
  sanitizeAnswers,
  stepError,
  toggleAnswer,
  toOnboardingParams,
} from './onboarding.js'

const options = {
  area: [
    { value: 'marketing', label: 'Marketing', area: null, sortOrder: 1 },
    { value: 'finanzas', label: 'Finanzas', area: null, sortOrder: 2 },
    { value: 'administracion', label: 'Administración', area: null, sortOrder: 3 },
  ],
  problem: [
    { value: 'atraer_clientes', label: 'Conseguir clientes', area: 'marketing', sortOrder: 1 },
    { value: 'controlar_gastos', label: 'Controlar gastos', area: 'finanzas', sortOrder: 2 },
    { value: 'decidir_con_informacion', label: 'Decidir con información', area: null, sortOrder: 3 },
  ],
  tool: [
    { value: 'instagram', label: 'Instagram', area: null, sortOrder: 1 },
    { value: 'excel', label: 'Excel', area: null, sortOrder: 2 },
    { value: 'ninguna', label: 'Ninguna por ahora', area: null, sortOrder: 3 },
  ],
  experience: [{ value: 'alguna_vez', label: 'La probé alguna vez', area: null, sortOrder: 1 }],
  goal: [{ value: 'conseguir_clientes', label: 'Conseguir clientes', area: null, sortOrder: 1 }],
  time: [{ value: 'de_30_a_60', label: 'De 30 a 60 minutos', area: null, sortOrder: 1 }],
}

test('el cuestionario tiene las seis preguntas y no inventa opciones', () => {
  assert.deepEqual(STEPS.map((step) => step.kind), ['area', 'problem', 'tool', 'experience', 'goal', 'time'])
  assert.equal(STEPS.filter((step) => step.multiple).length, 3)
})

test('ninguna no se combina con otras herramientas', () => {
  const toolsStep = STEPS.findIndex((step) => step.key === 'tools')
  let answers = emptyAnswers()
  answers = toggleAnswer(answers, toolsStep, 'instagram')
  answers = toggleAnswer(answers, toolsStep, 'excel')
  answers = toggleAnswer(answers, toolsStep, 'ninguna')
  assert.deepEqual(answers.tools, ['ninguna'])
  answers = toggleAnswer(answers, toolsStep, 'excel')
  assert.deepEqual(answers.tools, ['excel'])
  assert.equal(stepError(toolsStep, { ...emptyAnswers(), tools: ['ninguna', 'excel'] }), '“Ninguna por ahora” no se combina con otras herramientas.')
})

test('no se puede avanzar sin una elección y se pueden mezclar áreas', () => {
  const areasStep = 0
  const problemsStep = 1
  assert.match(stepError(areasStep, emptyAnswers()), /al menos una/)
  const mixed = toggleAnswer(toggleAnswer(emptyAnswers(), problemsStep, 'atraer_clientes'), problemsStep, 'controlar_gastos')
  assert.deepEqual(mixed.problems, ['atraer_clientes', 'controlar_gastos'])
  const groups = problemGroups(options).map((group) => group.id)
  assert.deepEqual(groups, ['marketing', 'finanzas', 'transversal'])
  const ordered = problemGroups(options, ['finanzas'])
  assert.deepEqual(ordered.map((group) => group.id), ['finanzas', 'marketing', 'transversal'])
  assert.deepEqual(ordered.map((group) => group.optional), [false, true, true])
})

test('las respuestas se normalizan con los ids reales y se descartan las desconocidas', () => {
  const clean = sanitizeAnswers({
    areas: ['marketing', 'finanzas', 'inventada'],
    problems: ['controlar_gastos'],
    tools: ['excel', 'ninguna'],
    aiExperience: 'alguna_vez',
    primaryGoal: 'conseguir_clientes',
    availableTime: 'de_30_a_60',
  }, options)
  assert.deepEqual(clean, {
    areas: ['marketing', 'finanzas'],
    problems: ['controlar_gastos'],
    tools: ['ninguna'],
    aiExperience: 'alguna_vez',
    primaryGoal: 'conseguir_clientes',
    availableTime: 'de_30_a_60',
  })
  assert.deepEqual(toOnboardingParams(clean), {
    p_areas: ['marketing', 'finanzas'],
    p_problems: ['controlar_gastos'],
    p_tools: ['ninguna'],
    p_ai_experience: 'alguna_vez',
    p_primary_goal: 'conseguir_clientes',
    p_available_time: 'de_30_a_60',
  })
})

test('una fila de Supabase vuelve como objeto de preferencias', () => {
  const answers = answersFromRow({
    areas: ['marketing'],
    problems: ['atraer_clientes'],
    tools: ['instagram'],
    ai_experience: 'alguna_vez',
    primary_goal: 'conseguir_clientes',
    available_time: 'de_30_a_60',
    updated_at: '2026-11-07T12:00:00Z',
  })
  assert.equal(answers.aiExperience, 'alguna_vez')
  assert.equal(answers.primaryGoal, 'conseguir_clientes')
  assert.equal(answers.availableTime, 'de_30_a_60')
  assert.equal(answersFromRow(null), null)
})

test('posponer no equivale a completar: solo cuentas con historia o de más de un día', () => {
  const now = Date.parse('2026-11-07T15:00:00Z')
  assert.equal(canPostponeOnboarding({
    profile: { xp: 0, createdAt: '2026-11-07T14:00:00Z' },
    progress: {},
    activityDays: [],
    achievements: [],
    now,
  }), false)
  assert.equal(canPostponeOnboarding({
    profile: { xp: 10, createdAt: '2026-11-07T14:00:00Z' },
    progress: {},
    activityDays: [],
    achievements: [],
    now,
  }), true)
  assert.equal(canPostponeOnboarding({
    profile: { xp: 0, createdAt: '2026-11-05T14:00:00Z' },
    progress: {},
    activityDays: [],
    achievements: [],
    now,
  }), true)
})
