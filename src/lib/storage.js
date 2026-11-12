let ownerId = null

export function setStorageOwner(userId) {
  ownerId = userId || null
}

const draftKey = (id) => ownerKey('draft', id)
const resultKey = (id) => ownerKey('result', id)
const sessionKey = (id) => ownerKey('session', id)
const recentKey = () => ownerKey('recent')
const onboardingKey = () => ownerKey('onboarding')
const laterKey = (userId) => (userId ? `skillbot:${userId}:onboarding-later` : null)

function ownerKey(kind, useCaseId) {
  if (!ownerId) return null
  return useCaseId ? `skillbot:${ownerId}:${kind}:${useCaseId}` : `skillbot:${ownerId}:${kind}`
}

function read(key) {
  if (!key) return null
  try {
    const raw = localStorage.getItem(key)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

function write(key, value) {
  if (!key) return false
  try {
    localStorage.setItem(key, value)
    return true
  } catch (error) {
    console.warn('No se pudo guardar en este dispositivo. El caso sigue disponible.', error)
    return false
  }
}

export function loadDraft(useCaseId) {
  const draft = read(draftKey(useCaseId))
  return draft?.values && typeof draft.values === 'object' ? draft.values : {}
}

export function saveDraft(useCaseId, values) {
  return write(draftKey(useCaseId), JSON.stringify({ values, updatedAt: new Date().toISOString() }))
}

export function loadResult(useCaseId) {
  const saved = read(resultKey(useCaseId))
  if (!saved?.text) return null
  return saved
}

export function saveResult(useCaseId, text, values) {
  return write(
    resultKey(useCaseId),
    JSON.stringify({ text, values, updatedAt: new Date().toISOString() }),
  )
}

export function loadSession(useCaseId) {
  const session = read(sessionKey(useCaseId))
  if (!session || typeof session !== 'object') return { answered: [] }
  const answered = Array.isArray(session.answered)
    ? session.answered.map(Number).filter((position) => position >= 1 && position <= 3)
    : []
  return { ...session, answered }
}

export function saveSession(useCaseId, patch) {
  const current = loadSession(useCaseId)
  return write(sessionKey(useCaseId), JSON.stringify({
    ...current,
    ...patch,
    answered: patch.answered ?? current.answered,
    updatedAt: new Date().toISOString(),
  }))
}

export function clearSession(useCaseId) {
  const key = sessionKey(useCaseId)
  if (!key) return false
  try {
    localStorage.removeItem(key)
    return true
  } catch {
    return false
  }
}

export function rememberCase(useCaseId) {
  const key = recentKey()
  if (!key) return false
  try {
    localStorage.setItem(key, useCaseId)
    return true
  } catch {
    return false
  }
}

export function recentCaseId() {
  const key = recentKey()
  if (!key) return null
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

export function loadOnboardingDraft() {
  const saved = read(onboardingKey())
  if (!saved?.answers || typeof saved.answers !== 'object') return null
  const step = Number.isInteger(saved.step) ? saved.step : 0
  return { answers: saved.answers, step }
}

export function saveOnboardingDraft(answers, step) {
  return write(onboardingKey(), JSON.stringify({
    answers,
    step,
    updatedAt: new Date().toISOString(),
  }))
}

export function clearOnboardingDraft() {
  const key = onboardingKey()
  if (!key) return false
  try {
    localStorage.removeItem(key)
    return true
  } catch {
    return false
  }
}

export function loadOnboardingLater(userId) {
  const key = laterKey(userId)
  if (!key) return false
  try {
    return sessionStorage.getItem(key) === '1'
  } catch {
    return false
  }
}

export function saveOnboardingLater(userId) {
  const key = laterKey(userId)
  if (!key) return false
  try {
    sessionStorage.setItem(key, '1')
    return true
  } catch {
    return false
  }
}

export function clearOnboardingLater(userId) {
  const key = laterKey(userId)
  if (!key) return false
  try {
    sessionStorage.removeItem(key)
    return true
  } catch {
    return false
  }
}

