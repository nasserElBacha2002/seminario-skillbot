const draftKey = (id) => `skillbot:draft:${id}`
const resultKey = (id) => `skillbot:result:${id}`
const sessionKey = (id) => `skillbot:session:${id}`
const RECENT_KEY = 'skillbot:recent'

function read(key) {
  try {
    const raw = localStorage.getItem(key)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

function write(key, value) {
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
  try {
    localStorage.removeItem(sessionKey(useCaseId))
    return true
  } catch {
    return false
  }
}

export function rememberCase(useCaseId) {
  return write(RECENT_KEY, useCaseId)
}

export function recentCaseId() {
  try {
    return localStorage.getItem(RECENT_KEY)
  } catch {
    return null
  }
}
