import assert from 'node:assert/strict'
import test from 'node:test'
import { caseOfTheDay } from './daily.js'
import { isPracticeReady } from './practice.js'

function practice(id) {
  return {
    id,
    fields: [{ key: 'dato', practice: true }],
    challenges: [{}, {}, {}],
    outputTemplate: '{{dato}}',
  }
}

function ficha(id) {
  return { id, title: `Ficha ${id}`, fields: [], challenges: [], outputTemplate: '' }
}

const catalog = [
  ficha('zzz-ficha'),
  practice('pedidos-multicanal'),
  practice('auditoria-instagram'),
  ficha('aaa-ficha'),
]

test('el caso del día es siempre una práctica y no cambia dentro de la misma fecha', () => {
  const date = new Date(2026, 10, 7)
  const first = caseOfTheDay(catalog, date)
  const second = caseOfTheDay(catalog, date)
  assert.equal(first.id, second.id)
  assert.equal(isPracticeReady(first), true)
  assert.equal(String(first.id).includes('ficha'), false)
})

test('sin prácticas no hay caso del día', () => {
  assert.equal(caseOfTheDay([ficha('solo-ficha')], new Date(2026, 10, 7)), null)
  assert.equal(caseOfTheDay([], new Date(2026, 10, 7)), null)
})

test('otra fecha puede elegir otra práctica, nunca una ficha', () => {
  const seen = new Set()
  for (let day = 1; day <= 14; day += 1) {
    const chosen = caseOfTheDay(catalog, new Date(2026, 10, day))
    seen.add(chosen.id)
    assert.equal(isPracticeReady(chosen), true)
  }
  assert.deepEqual([...seen].sort(), ['auditoria-instagram', 'pedidos-multicanal'])
})
