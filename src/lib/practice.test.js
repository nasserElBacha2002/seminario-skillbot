import assert from 'node:assert/strict'
import test from 'node:test'
import { isPracticeReady } from './practice.js'

function practice(id) {
  return {
    id,
    fields: [{ key: 'dato', practice: true, required: true }],
    challenges: [{ position: 1 }, { position: 2 }, { position: 3 }],
    outputTemplate: 'Usá solo {{dato}}.',
  }
}

function ficha(id) {
  return { id, fields: [], challenges: [], outputTemplate: '' }
}

test('una práctica necesita campos, tres desafíos y plantilla', () => {
  assert.equal(isPracticeReady(practice('auditoria-instagram')), true)
  assert.equal(isPracticeReady({ ...practice('x'), challenges: [{ position: 1 }, { position: 2 }] }), false)
  assert.equal(isPracticeReady({ ...practice('x'), outputTemplate: '' }), false)
  assert.equal(isPracticeReady({ ...practice('x'), fields: [] }), false)
})

test('una ficha no se puede practicar', () => {
  assert.equal(isPracticeReady(ficha('calendario-contenidos')), false)
})

test('los campos del caso original cuentan aunque no traigan la marca de práctica', () => {
  const original = {
    id: 'ventas-sin-formulas',
    fields: [
      { key: 'objetivo', required: true },
      { key: 'columnas', required: true },
    ],
    challenges: [{ position: 1 }, { position: 2 }, { position: 3 }],
    outputTemplate: 'Columnas: {{columnas}}',
  }
  assert.equal(isPracticeReady(original), true)
})
