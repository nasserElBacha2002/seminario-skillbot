// Vocabulario visual: los textos salen de onboarding_options.
// `ninguna` es el id estable de la herramienta exclusiva definido en la migración.

export const EXCLUSIVE_TOOL = 'ninguna'

export const STEPS = [
  {
    key: 'areas',
    kind: 'area',
    multiple: true,
    title: '¿Qué áreas de tu emprendimiento te gustaría mejorar?',
    hint: 'Podés elegir más de una. No hace falta quedarte con un solo rubro.',
  },
  {
    key: 'problems',
    kind: 'problem',
    multiple: true,
    title: '¿Cuáles son las principales dificultades que enfrentás?',
    hint: 'Primero aparecen las áreas que elegiste. Las demás quedan al final y son opcionales.',
  },
  {
    key: 'tools',
    kind: 'tool',
    multiple: true,
    title: '¿Qué herramientas utilizás actualmente?',
    hint: 'Si todavía no usás ninguna, elegí esa opción sola.',
  },
  {
    key: 'aiExperience',
    kind: 'experience',
    multiple: false,
    title: '¿Qué experiencia tenés utilizando inteligencia artificial?',
    hint: 'Elegí la opción que más se parece a hoy.',
  },
  {
    key: 'primaryGoal',
    kind: 'goal',
    multiple: false,
    title: '¿Qué resultado te gustaría conseguir primero?',
    hint: 'Es el primer resultado, no el único.',
  },
  {
    key: 'availableTime',
    kind: 'time',
    multiple: false,
    title: '¿Cuánto tiempo podés dedicarle a resolver un problema con IA?',
    hint: 'Pensalo como el tiempo de una sesión.',
  },
]

export function emptyAnswers() {
  return {
    areas: [],
    problems: [],
    tools: [],
    aiExperience: '',
    primaryGoal: '',
    availableTime: '',
  }
}

export function groupOptions(rows) {
  const options = { area: [], problem: [], goal: [], tool: [], experience: [], time: [] }
  for (const row of rows ?? []) {
    if (!options[row.kind]) continue
    options[row.kind].push({
      value: row.value,
      label: row.label,
      area: row.area ?? null,
      sortOrder: row.sort_order,
    })
  }
  for (const list of Object.values(options)) {
    list.sort((a, b) => a.sortOrder - b.sortOrder)
  }
  return options
}

export function answersFromRow(row) {
  if (!row) return null
  return {
    areas: row.areas ?? [],
    problems: row.problems ?? [],
    tools: row.tools ?? [],
    aiExperience: row.ai_experience ?? '',
    primaryGoal: row.primary_goal ?? '',
    availableTime: row.available_time ?? '',
    updatedAt: row.updated_at ?? null,
  }
}

export function toOnboardingParams(answers) {
  return {
    p_areas: answers.areas,
    p_problems: answers.problems,
    p_tools: answers.tools,
    p_ai_experience: answers.aiExperience,
    p_primary_goal: answers.primaryGoal,
    p_available_time: answers.availableTime,
  }
}

function allowedValues(options, kind) {
  return new Set((options?.[kind] ?? []).map((option) => option.value))
}

export function sanitizeAnswers(answers, options) {
  const source = answers ?? emptyAnswers()
  const pickMany = (kind, values) => (Array.isArray(values) ? values : []).filter((value) => allowedValues(options, kind).has(value))
  const pickOne = (kind, value) => (allowedValues(options, kind).has(value) ? value : '')
  let tools = pickMany('tool', source.tools)
  if (tools.includes(EXCLUSIVE_TOOL)) tools = [EXCLUSIVE_TOOL]
  return {
    areas: pickMany('area', source.areas),
    problems: pickMany('problem', source.problems),
    tools,
    aiExperience: pickOne('experience', source.aiExperience),
    primaryGoal: pickOne('goal', source.primaryGoal),
    availableTime: pickOne('time', source.availableTime),
  }
}

export function toggleAnswer(answers, stepIndex, value) {
  const step = STEPS[stepIndex]
  if (!step.multiple) return { ...answers, [step.key]: value }
  const current = answers[step.key] ?? []
  if (step.key === 'tools') {
    if (value === EXCLUSIVE_TOOL) {
      const onlyExclusive = current.length === 1 && current[0] === EXCLUSIVE_TOOL
      return { ...answers, tools: onlyExclusive ? [] : [EXCLUSIVE_TOOL] }
    }
    const without = current.filter((item) => item !== EXCLUSIVE_TOOL && item !== value)
    return { ...answers, tools: current.includes(value) ? without : [...without, value] }
  }
  const next = current.includes(value) ? current.filter((item) => item !== value) : [...current, value]
  return { ...answers, [step.key]: next }
}

export function stepError(stepIndex, answers) {
  const step = STEPS[stepIndex]
  if (!step) return 'Elegí una opción para seguir.'
  if (step.multiple) {
    const selected = answers[step.key] ?? []
    if (!selected.length) return 'Elegí al menos una opción.'
    if (step.key === 'tools' && selected.includes(EXCLUSIVE_TOOL) && selected.length > 1) {
      return '“Ninguna por ahora” no se combina con otras herramientas.'
    }
    return ''
  }
  return answers[step.key] ? '' : 'Elegí una opción para seguir.'
}

export function problemGroups(options, selectedAreas = []) {
  const areaOrder = (options?.area ?? []).map((option) => option.value)
  const areaName = Object.fromEntries((options?.area ?? []).map((option) => [option.value, option.label]))
  const selected = new Set(selectedAreas ?? [])
  const groups = new Map()
  for (const option of options?.problem ?? []) {
    const id = option.area ?? 'transversal'
    if (!groups.has(id)) {
      groups.set(id, {
        id,
        label: areaName[id] ?? 'Para todo el negocio',
        options: [],
      })
    }
    groups.get(id).options.push(option)
  }
  const rank = (id) => (id === 'transversal' ? areaOrder.length : areaOrder.indexOf(id))
  return [...groups.values()]
    .map((group) => ({
      ...group,
      optional: selected.size > 0 && !selected.has(group.id),
    }))
    .sort((a, b) => {
      if (a.optional !== b.optional) return a.optional ? 1 : -1
      return rank(a.id) - rank(b.id)
    })
}

export function optionLabels(options, kind, values) {
  const selected = Array.isArray(values) ? values : values ? [values] : []
  const byValue = new Map((options?.[kind] ?? []).map((option) => [option.value, option.label]))
  return selected.map((value) => byValue.get(value)).filter(Boolean)
}

export function onboardingErrorMessage(error) {
  const text = String(error?.message ?? '').toLowerCase()
  if (text.includes('ninguna')) return '“Ninguna por ahora” no se combina con otras herramientas.'
  if (text.includes('not authenticated') || error?.code === '42501') {
    return 'Tu sesión venció. Volvé a entrar para guardar.'
  }
  if (error?.name === 'AuthRetryableFetchError' || text.includes('failed to fetch') || text.includes('network')) {
    return 'No pudimos guardar. Revisá tu conexión e intentá de nuevo.'
  }
  return 'No pudimos guardar tus respuestas. Intentá nuevamente.'
}

const DAY_MS = 24 * 60 * 60 * 1000

export function canPostponeOnboarding({ profile, progress, activityDays, achievements, now = Date.now() }) {
  const hasHistory = (profile?.xp ?? 0) > 0
    || Object.keys(progress ?? {}).length > 0
    || (activityDays ?? []).length > 0
    || (achievements ?? []).some((item) => item.unlocked)
  if (hasHistory) return true
  const created = Date.parse(profile?.createdAt ?? '')
  if (!Number.isFinite(created)) return false
  return now - created > DAY_MS
}
