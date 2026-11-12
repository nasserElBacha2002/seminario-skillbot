import assert from 'node:assert/strict'
import test from 'node:test'
import {
  clearOnboardingDraft,
  loadOnboardingDraft,
  loadOnboardingLater,
  saveOnboardingDraft,
  saveOnboardingLater,
  setStorageOwner,
} from './storage.js'

function memoryStorage() {
  const data = new Map()
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: (key) => data.delete(key),
  }
}

test('el borrador queda por usuario y no cuenta como onboarding terminado', () => {
  globalThis.localStorage = memoryStorage()
  globalThis.sessionStorage = memoryStorage()
  const answers = { areas: ['marketing'], problems: ['atraer_clientes'], tools: [] }

  setStorageOwner('usuario-a')
  assert.equal(saveOnboardingDraft(answers, 2), true)
  assert.deepEqual(loadOnboardingDraft(), { answers, step: 2 })
  assert.equal(loadOnboardingLater('usuario-a'), false)

  setStorageOwner('usuario-b')
  assert.equal(loadOnboardingDraft(), null)
  saveOnboardingDraft({ areas: ['finanzas'] }, 0)

  setStorageOwner('usuario-a')
  assert.deepEqual(loadOnboardingDraft().answers.areas, ['marketing'])
  assert.equal(clearOnboardingDraft(), true)
  assert.equal(loadOnboardingDraft(), null)

  setStorageOwner('usuario-b')
  assert.deepEqual(loadOnboardingDraft().answers.areas, ['finanzas'])
})

test('ahora no vive en la sesión de esa cuenta', () => {
  globalThis.sessionStorage = memoryStorage()
  assert.equal(saveOnboardingLater('usuario-a'), true)
  assert.equal(loadOnboardingLater('usuario-a'), true)
  assert.equal(loadOnboardingLater('usuario-b'), false)
})
