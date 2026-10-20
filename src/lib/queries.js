import { fallbackCategories, guidedCases, guidedTools, toolUrls } from '../data/guidedCases.js'
import { isLegacySchemaError } from './schemaError.js'
import { DEMO_PROFILE_ID, supabase } from './supabase'

// Fecha local en formato YYYY-MM-DD. No se usa toISOString porque convierte a
// UTC y correria el dia para zonas con offset negativo.
export function toDayString(date) {
  const y = date.getFullYear()
  const m = `${date.getMonth() + 1}`.padStart(2, '0')
  const d = `${date.getDate()}`.padStart(2, '0')
  return `${y}-${m}-${d}`
}

function unwrap({ data, error }) {
  if (error) throw error
  return data
}

const USE_CASE_BASE = `
  id, title, summary, situation, skill_id, difficulty, estimated_minutes, icon, color,
  common_mistake, learning_outcome, xp_reward, sort_order,
  categories:use_case_categories(is_primary, category:categories(id, name, sort_order)),
  tools:use_case_tools(role, reason, sort_order, tool:tools(id, name)),
  steps:use_case_steps(position, body, example_prompt, checklist, requires_confirmation, confirmation_label),
  survey:use_case_survey_tasks(position, task, mentions),
  challenge:use_case_challenges(title, scenario, question, options:challenge_options(letter, body, is_correct, feedback))
`

const USE_CASE_COLUMNS = `
  id, title, summary, situation, skill_id, difficulty, estimated_minutes, icon, color,
  common_mistake, learning_outcome, xp_reward, sort_order, output_template,
  categories:use_case_categories(is_primary, category:categories(id, name, sort_order)),
  tools:use_case_tools(role, reason, sort_order, tool:tools(id, name, url)),
  steps:use_case_steps(position, body, example_prompt, checklist, requires_confirmation, confirmation_label),
  survey:use_case_survey_tasks(position, task, mentions),
  fields:use_case_fields(id, key, label, type, placeholder, required, position, options, helper_text),
  challenge:use_case_challenges(title, scenario, question, options:challenge_options(letter, body, is_correct, feedback))
`

const LEGACY_CATEGORIES = new Set(['administracion', 'vinculacion', 'explicacion-ia', 'diseno', 'programacion'])

let fallbackWarned = false

function warnFallback(detail) {
  if (fallbackWarned) return
  fallbackWarned = true
  console.warn(
    '[skillbot] Catálogo en respaldo temporal (src/data/guidedCases.js). No es la fuente de verdad. Aplicá las migraciones 20261020210000 y 20261020223000, corré el seed y eliminá ese archivo.',
    detail,
  )
}

async function fetchUseCaseRows() {
  const extended = await supabase.from('use_cases').select(USE_CASE_COLUMNS).eq('status', 'published').order('sort_order')
  if (!extended.error) return { rows: extended.data, legacySchema: false }
  if (!isLegacySchemaError(extended.error)) throw extended.error
  const base = await supabase.from('use_cases').select(USE_CASE_BASE).eq('status', 'published').order('sort_order')
  if (base.error) throw base.error
  return { rows: base.data, legacySchema: true }
}

function mapFields(fields) {
  return [...fields].sort(byKey('position')).map((field) => ({
    id: field.id,
    key: field.key,
    label: field.label,
    type: field.type,
    placeholder: field.placeholder ?? '',
    required: field.required,
    options: field.options ?? [],
    helper: field.helper_text ?? field.helper ?? '',
  }))
}

function withGuidance(useCases, categories, legacySchema) {
  const legacyCategories = categories.length > 0 && categories.every((category) => LEGACY_CATEGORIES.has(category.id))
  const useFixture = legacySchema || legacyCategories
  if (useFixture) warnFallback(legacySchema ? 'schema anterior' : 'categorías anteriores')
  const resolvedCategories = useFixture ? fallbackCategories : categories
  const resolvedCases = useCases.map((item) => {
    const guide = useFixture ? guidedCases[item.id] : null
    const categoryIds = useFixture && guide?.categoryIds?.length ? guide.categoryIds : item.categoryIds
    const categoryNames = categoryIds.map((id) => resolvedCategories.find((category) => category.id === id)?.name).filter(Boolean)
    return {
      ...item,
      categoryIds,
      categoryNames: categoryNames.length ? categoryNames : item.categoryNames,
      category: categoryNames[0] || item.category,
      outputTemplate: useFixture ? (item.outputTemplate || guide?.outputTemplate || '') : item.outputTemplate,
      fields: useFixture && !item.fields.length ? (guide?.fields ?? []) : item.fields,
      tools: useFixture && guidedTools[item.id]
        ? guidedTools[item.id].map((tool) => ({ ...tool, url: toolUrls[tool.id] || '' }))
        : item.tools.map((tool) => ({ ...tool, url: tool.url || '' })),
    }
  })
  return { useCases: resolvedCases, categories: resolvedCategories }
}

const byKey = (key) => (a, b) => a[key] - b[key]

function toUseCase(row) {
  const categories = [...row.categories].sort((a, b) => b.is_primary - a.is_primary || a.category.sort_order - b.category.sort_order)
  // PostgREST devuelve objeto en las relaciones uno a uno, pero se normaliza por si llega como lista.
  const challenge = Array.isArray(row.challenge) ? row.challenge[0] : row.challenge
  return {
    id: row.id,
    title: row.title,
    description: row.summary,
    situation: row.situation,
    category: categories[0]?.category.name ?? '',
    categoryNames: categories.map((x) => x.category.name),
    categoryIds: categories.map((x) => x.category.id),
    estimatedTime: `${row.estimated_minutes} min`,
    difficulty: row.difficulty,
    icon: row.icon,
    color: row.color,
    skill: row.skill_id,
    xpReward: row.xp_reward,
    mistake: row.common_mistake,
    learning: row.learning_outcome,
    outputTemplate: row.output_template ?? '',
    tools: [...row.tools].sort(byKey('sort_order')).map((x) => ({ id: x.tool.id, name: x.tool.name, role: x.role, reason: x.reason, url: x.tool?.url ?? '' })),
    steps: [...row.steps].sort(byKey('position')).map((x) => ({
      position: x.position,
      body: x.body,
      prompt: x.example_prompt,
      checklist: x.checklist ?? [],
      gate: x.requires_confirmation ? x.confirmation_label : null,
    })),
    survey: [...row.survey].sort(byKey('position')),
    demand: [...row.survey].reduce((sum, task) => sum + (task.mentions || 0), 0),
    fields: mapFields(row.fields ?? []),
    challenge: challenge && {
      title: challenge.title,
      scenario: challenge.scenario,
      question: challenge.question,
      options: [...challenge.options].sort((a, b) => a.letter.localeCompare(b.letter)),
    },
  }
}

export async function fetchSkillbotData() {
  const [catalogRows, categories, profile, levels, skills, userSkills, achievements, unlocked, progress, stepProgress, activity] = await Promise.all([
    fetchUseCaseRows(),
    supabase.from('categories').select('id, name').order('sort_order').then(unwrap),
    supabase.from('profiles').select('id, display_name, initials, goal, interests, xp, level_id').eq('id', DEMO_PROFILE_ID).single().then(unwrap),
    supabase.from('levels').select('id, name, min_xp, next_xp, sort_order').order('sort_order').then(unwrap),
    supabase.from('skills').select('id, name, color, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_skills').select('skill_id, value').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('achievements').select('id, title, description, icon, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_achievements').select('achievement_id').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('use_case_progress').select('use_case_slug, progress, status, completed_at, updated_at').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('use_case_step_progress').select('use_case_id, position').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('activity_days').select('day').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
  ])

  const valueBySkill = new Map(userSkills.map((x) => [x.skill_id, x.value]))
  const unlockedIds = new Set(unlocked.map((x) => x.achievement_id))
  const doneSteps = {}
  for (const x of stepProgress) (doneSteps[x.use_case_id] ??= []).push(x.position)

  const catalog = withGuidance(catalogRows.rows.map(toUseCase), categories, catalogRows.legacySchema)

  return {
    useCases: catalog.useCases,
    categories: catalog.categories,
    doneSteps,
    profile: {
      name: profile.display_name,
      initials: profile.initials,
      goal: profile.goal === 'Aprender a elegir y utilizar herramientas de IA para resolver tareas cotidianas.'
        ? 'Resolver tareas concretas usando IA, sin tener que saber de antemano qué herramienta elegir.'
        : profile.goal,
      interests: profile.interests ?? [],
      xp: profile.xp,
    },
    level: levels.find((x) => x.id === profile.level_id) ?? levels[0],
    skills: skills.map((x) => ({ ...x, value: valueBySkill.get(x.id) ?? 0 })),
    achievements: achievements.map((x) => ({ ...x, unlocked: unlockedIds.has(x.id) })),
    progress: Object.fromEntries(progress.map((x) => [x.use_case_slug, x])),
    activityDays: activity.map((x) => x.day),
  }
}

export function resolveUseCase(useCaseId, day) {
  return supabase.rpc('resolve_use_case', { p_use_case_id: useCaseId, p_day: day }).then(unwrap)
}

export function setStepDone(useCaseId, position, done) {
  const table = supabase.from('use_case_step_progress')
  const request = done
    ? table.upsert(
        { profile_id: DEMO_PROFILE_ID, use_case_id: useCaseId, position },
        { onConflict: 'profile_id,use_case_id,position', ignoreDuplicates: true },
      )
    : table.delete().eq('profile_id', DEMO_PROFILE_ID).eq('use_case_id', useCaseId).eq('position', position)
  return request.then(unwrap)
}

export function saveUseCaseProgress(useCaseSlug, progress) {
  const completed = progress >= 100
  return supabase
    .from('use_case_progress')
    .upsert(
      {
        profile_id: DEMO_PROFILE_ID,
        use_case_slug: useCaseSlug,
        progress,
        status: completed ? 'completed' : 'in_progress',
        completed_at: completed ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'profile_id,use_case_slug' },
    )
    .select('use_case_slug, progress, status, completed_at')
    .single()
    .then(unwrap)
}

export function recordChallengeAttempt({ useCaseSlug, selectedOption, isCorrect, xpEarned }) {
  return supabase
    .from('challenge_attempts')
    .insert({
      profile_id: DEMO_PROFILE_ID,
      use_case_slug: useCaseSlug,
      selected_option: selectedOption,
      is_correct: isCorrect,
      xp_earned: xpEarned,
    })
    .select('id')
    .single()
    .then(unwrap)
}

export function markActivityToday() {
  return supabase
    .from('activity_days')
    .upsert({ profile_id: DEMO_PROFILE_ID, day: toDayString(new Date()) }, { onConflict: 'profile_id,day' })
    .then(unwrap)
}

export function unlockAchievement(achievementId) {
  return supabase
    .from('user_achievements')
    .upsert(
      { profile_id: DEMO_PROFILE_ID, achievement_id: achievementId },
      { onConflict: 'profile_id,achievement_id', ignoreDuplicates: true },
    )
    .then(unwrap)
}
