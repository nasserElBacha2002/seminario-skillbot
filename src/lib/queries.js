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

export async function fetchSkillbotData() {
  const [profile, levels, skills, userSkills, achievements, unlocked, progress, activity] = await Promise.all([
    supabase.from('profiles').select('id, display_name, initials, goal, interests, xp, level_id').eq('id', DEMO_PROFILE_ID).single().then(unwrap),
    supabase.from('levels').select('id, name, min_xp, next_xp, sort_order').order('sort_order').then(unwrap),
    supabase.from('skills').select('id, name, color, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_skills').select('skill_id, value').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('achievements').select('id, title, description, icon, sort_order').order('sort_order').then(unwrap),
    supabase.from('user_achievements').select('achievement_id').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('use_case_progress').select('use_case_slug, progress, status, completed_at').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
    supabase.from('activity_days').select('day').eq('profile_id', DEMO_PROFILE_ID).then(unwrap),
  ])

  const valueBySkill = new Map(userSkills.map((x) => [x.skill_id, x.value]))
  const unlockedIds = new Set(unlocked.map((x) => x.achievement_id))

  return {
    profile: {
      name: profile.display_name,
      initials: profile.initials,
      goal: profile.goal,
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

export function addXp(amount) {
  return supabase.rpc('add_xp', { p_profile_id: DEMO_PROFILE_ID, p_amount: amount }).then(unwrap)
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

export function bumpSkill(skillId, delta) {
  // Lee y vuelve a escribir en lugar de usar un increment atomico porque es un
  // unico usuario demo y no hay escrituras concurrentes.
  return supabase
    .from('user_skills')
    .select('value')
    .eq('profile_id', DEMO_PROFILE_ID)
    .eq('skill_id', skillId)
    .maybeSingle()
    .then(unwrap)
    .then((row) => {
      const value = Math.min(100, (row?.value ?? 0) + delta)
      return supabase
        .from('user_skills')
        .upsert(
          { profile_id: DEMO_PROFILE_ID, skill_id: skillId, value, updated_at: new Date().toISOString() },
          { onConflict: 'profile_id,skill_id' },
        )
        .select('skill_id, value')
        .single()
        .then(unwrap)
    })
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
