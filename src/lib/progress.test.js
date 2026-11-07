import assert from 'node:assert/strict'
import test from 'node:test'
import { summarizePracticeProgress } from './progress.js'

function practice(id) {
  return {
    id,
    fields: [{ key: 'dato', practice: true }],
    challenges: [{}, {}, {}],
    outputTemplate: '{{dato}}',
  }
}

function ficha(id) {
  return { id, fields: [], challenges: [], outputTemplate: '' }
}

const catalog = [practice('ventas-sin-formulas'), practice('auditoria-instagram'), ficha('calendario-contenidos')]

test('sin progreso el porcentaje es cero y las fichas no entran en el total', () => {
  const summary = summarizePracticeProgress(catalog, {})
  assert.deepEqual(summary, { completedCount: 0, totalCases: 2, overallProgress: 0 })
})

test('una práctica iniciada no se diluye con fichas', () => {
  const summary = summarizePracticeProgress(catalog, {
    'auditoria-instagram': { progress: 40, status: 'in_progress' },
    'calendario-contenidos': { progress: 100, status: 'completed' },
  })
  assert.equal(summary.completedCount, 0)
  assert.equal(summary.totalCases, 2)
  assert.equal(summary.overallProgress, 20)
})

test('una práctica completada cuenta una sola vez', () => {
  const summary = summarizePracticeProgress(catalog, {
    'ventas-sin-formulas': { progress: 100, status: 'completed' },
  })
  assert.equal(summary.completedCount, 1)
  assert.equal(summary.overallProgress, 50)
})

test('agregar fichas no cambia el porcentaje de quien ya practicó', () => {
  const before = summarizePracticeProgress(
    [practice('ventas-sin-formulas'), practice('auditoria-instagram')],
    { 'ventas-sin-formulas': { progress: 100, status: 'completed' } },
  )
  const after = summarizePracticeProgress(
    [...catalog, ficha('gastos-que-se-repiten'), ficha('embudo-consultas')],
    { 'ventas-sin-formulas': { progress: 100, status: 'completed' } },
  )
  assert.equal(before.overallProgress, after.overallProgress)
  assert.equal(after.totalCases, 2)
})
