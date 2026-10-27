import { fallbackCategories, guidedCases, guidedTools, toolUrls } from '../data/guidedCases.js'
import { practiceChallenges, practiceFieldKeys, practiceKeys } from '../data/practiceChallenges.js'
import { isLegacySchemaError } from './schemaError.js'
import { supabase } from './supabase'

async function currentUserId() {
  const { data: { session } } = await supabase.auth.getSession()
  const userId = session?.user?.id
  if (!userId) throw new Error('Tenés que iniciar sesión para continuar.')
  return userId
}

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
  fields:use_case_fields(id, key, label, type, placeholder, required, position, options, helper_text, in_practice),
  challenges:use_case_challenges(position, type, title, instruction, scenario, question, feedback_correct, feedback_incorrect, xp, options:challenge_options(letter, body, is_correct, feedback))
`

const LEGACY_CATEGORIES = new Set(['administracion', 'vinculacion', 'explicacion-ia', 'diseno', 'programacion'])

let fallbackWarned = false

function warnFallback(detail) {
  if (fallbackWarned) return
  fallbackWarned = true
  console.warn(
    '[skillbot] Catálogo en respaldo temporal (src/data/guidedCases.js). No es la fuente de verdad. Aplicá las migraciones 20261020210000, 20261020223000 y 20261021010000, corré el seed y eliminá ese archivo.',
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
    practice: Boolean(field.in_practice ?? field.practice),
  }))
}

function mapChallenges(rows) {
  const list = Array.isArray(rows) ? rows : rows ? [rows] : []
  return list
    .filter((item) => item?.type)
    .sort(byKey('position'))
    .map((item) => ({
      position: item.position,
      type: item.type,
      title: item.title,
      instruction: item.instruction || '',
      scenario: item.scenario,
      question: item.question,
      feedbackCorrect: item.feedback_correct || item.feedbackCorrect || '',
      feedbackIncorrect: item.feedback_incorrect || item.feedbackIncorrect || '',
      xp: item.xp ?? 10,
      options: [...(item.options ?? [])].sort((a, b) => a.letter.localeCompare(b.letter)).map((option) => ({
        letter: option.letter,
        body: option.body,
        is_correct: option.is_correct,
        feedback: option.feedback || '',
      })),
    }))
}

function applyPractice(id, fields) {
  const keys = practiceFieldKeys[id] ?? []
  const order = new Map(keys.map((key, index) => [key, index]))
  return fields.map((field) => ({
    ...field,
    practice: field.practice || order.has(field.key),
    practiceOrder: order.get(field.key) ?? 99,
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
      fields: applyPractice(item.id, useFixture && !item.fields.length ? (guide?.fields ?? []) : item.fields),
      challenges: useFixture ? (practiceChallenges[item.id] ?? []) : item.challenges,
      keys: practiceKeys[item.id] ?? [],
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
  const challengeRows = row.challenges ?? row.challenge
  const challenges = mapChallenges(challengeRows)
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
    challenges,
    keys: [],
  }
}

async function fetchDoneChallenges(userId) {
  const { data, error } = await supabase
    .from('practice_rewards')
    .select('use_case_id, position')
    .eq('profile_id', userId)
  if (error) {
    if (isLegacySchemaError(error)) return {}
    throw error
  }
  const doneChallenges = {}
  for (const row of data ?? []) {
    if (row.position >= 1 && row.position <= 3) (doneChallenges[row.use_case_id] ??= []).push(row.position)
  }
  return doneChallenges
}

export async function fetchSkillbotData() {
  const userId = await currentUserId()
  const profileQuery = supabase
    .from('profiles')
    .select('id, display_name, initials, goal, interests, xp, level_id')
    .eq('id', userId)
    .maybeSingle()
    .then(({ data, error }) => {
      if (error) throw error
      if (!data) {
        throw new Error('No encontramos tu perfil. Si acabás de crear la cuenta, recargá la página. Si el error sigue, falta aplicar la migración de autenticación.')
      }
      return data
    })

  const [catalogRows, categories, profile, levels, skills, userSkills, achievements, unlocked, progress, stepProgress, activity, doneChallenges] = await Promise.all([
    fetchUseCaseRows(),
    supabase.from('categories').select('id, name').order('sort_order').then(unwrap),
    profileQuery,
    supabase.from('levels').select('id, name, min_xp, next_xp, sort_order').order('sort_order').then(unwrap),
    supabase.from('skills').select('id, name, color, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_skills').select('skill_id, value').eq('profile_id', userId).then(unwrap),
    supabase.from('achievements').select('id, title, description, icon, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_achievements').select('achievement_id').eq('profile_id', userId).then(unwrap),
    supabase.from('use_case_progress').select('use_case_slug, progress, status, completed_at, updated_at').eq('profile_id', userId).then(unwrap),
    supabase.from('use_case_step_progress').select('use_case_id, position').eq('profile_id', userId).then(unwrap),
    supabase.from('activity_days').select('day').eq('profile_id', userId).then(unwrap),
    fetchDoneChallenges(userId),
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
    doneChallenges,
    profile: {
      name: profile.display_name,
      initials: profile.initials,
      goal: profile.goal || 'Resolver tareas concretas usando IA, sin tener que saber de antemano qué herramienta elegir.',
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

export function completePracticeChallenge({ useCaseId, position, selected, day }) {
  return supabase.rpc('complete_practice_challenge', {
    p_use_case_id: useCaseId,
    p_position: position,
    p_selected: selected,
    p_day: day,
  }).then(unwrap)
}

export async function clearCaseSteps(useCaseId) {
  const userId = await currentUserId()
  return supabase
    .from('use_case_step_progress')
    .delete()
    .eq('profile_id', userId)
    .eq('use_case_id', useCaseId)
    .then(unwrap)
}

export async function setStepDone(useCaseId, position, done) {
  const userId = await currentUserId()
  const table = supabase.from('use_case_step_progress')
  const request = done
    ? table.upsert(
        { profile_id: userId, use_case_id: useCaseId, position },
        { onConflict: 'profile_id,use_case_id,position', ignoreDuplicates: true },
      )
    : table.delete().eq('profile_id', userId).eq('use_case_id', useCaseId).eq('position', position)
  return request.then(unwrap)
}

export async function saveUseCaseProgress(useCaseSlug, progress) {
  const userId = await currentUserId()
  const completed = progress >= 100
  return supabase
    .from('use_case_progress')
    .upsert(
      {
        profile_id: userId,
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

export async function recordChallengeAttempt({ useCaseSlug, selectedOption, isCorrect, xpEarned }) {
  const userId = await currentUserId()
  return supabase
    .from('challenge_attempts')
    .insert({
      profile_id: userId,
      use_case_slug: useCaseSlug,
      selected_option: selectedOption,
      is_correct: isCorrect,
      xp_earned: xpEarned,
    })
    .select('id')
    .single()
    .then(unwrap)
}

export async function markActivityToday() {
  const userId = await currentUserId()
  return supabase
    .from('activity_days')
    .upsert({ profile_id: userId, day: toDayString(new Date()) }, { onConflict: 'profile_id,day' })
    .then(unwrap)
}

export async function unlockAchievement(achievementId) {
  const userId = await currentUserId()
  return supabase
    .from('user_achievements')
    .upsert(
      { profile_id: userId, achievement_id: achievementId },
      { onConflict: 'profile_id,achievement_id', ignoreDuplicates: true },
    )
    .then(unwrap)
}
