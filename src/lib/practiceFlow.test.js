import assert from 'node:assert/strict'
import test from 'node:test'
import {
  contextFieldsForPager,
  guideStepGroups,
  shouldSkipObjectiveSlide,
  shouldSkipScenarioSlide,
  textOverlapRatio,
} from './practiceFlow.js'
import { practiceFieldsOf } from './practice.js'

test('textOverlapRatio detecta textos muy parecidos', () => {
  const a = 'Tenés ventas en Sheets y querés una fórmula sin inventar columnas.'
  const b = 'Tenés ventas en Google Sheets y querés la fórmula sin inventar columnas.'
  assert.ok(textOverlapRatio(a, b) >= 0.5)
})

test('shouldSkipScenarioSlide omite escenario redundante', () => {
  const useCase = {
    description: 'Armá un pedido claro para calcular ventas por vendedor en Google Sheets con tus columnas reales.',
    situation: 'Armá un pedido para calcular ventas por vendedor en Google Sheets con tus columnas reales.',
  }
  assert.equal(shouldSkipScenarioSlide(useCase), true)
})

test('shouldSkipObjectiveSlide conserva objetivos distintos', () => {
  const useCase = {
    description: 'Caso sobre ventas.',
    learning: 'Saber pedir una fórmula verificable antes de confiar en la respuesta.',
  }
  assert.equal(shouldSkipObjectiveSlide(useCase), false)
})

test('guideStepGroups compacta listas largas', () => {
  const steps = [1, 2, 3, 4, 5, 6].map((position) => ({ position, body: `Paso ${position}` }))
  const groups = guideStepGroups(steps)
  assert.ok(groups.length <= 3)
  assert.equal(groups.reduce((n, g) => n + g.positions.length, 0), 6)
})

test('contextFieldsForPager omite opcionales redundantes', () => {
  const useCase = {
    fields: [
      { key: 'objetivo', practice: true, required: true, practiceOrder: 1 },
      { key: 'columnas', practice: true, required: true, practiceOrder: 2 },
      { key: 'filas', practice: true, required: false, practiceOrder: 3 },
    ],
  }
  assert.equal(practiceFieldsOf(useCase).length, 3)
  assert.equal(contextFieldsForPager(useCase, { objetivo: 'Quiero total por vendedor con 600 filas de ventas' }).length, 2)
})