import assert from 'node:assert/strict'
import test from 'node:test'
import { fichaFallbackActions, fichaSuccessChecks } from './fichaGuide.js'

const sample = {
  description: 'Definí audiencia y presupuesto.',
  situation: 'Querés pagar un anuncio.',
  learning: 'Traducir un presupuesto en una meta, una audiencia y una regla para frenar el gasto.',
  mistake: 'Pedir una campaña creativa sin decir el monto máximo ni qué cuenta como resultado.',
  steps: [
    { position: 1, body: 'Paso uno', checklist: [] },
    { position: 2, body: 'Paso dos', checklist: ['Meta escrita'] },
  ],
}

test('armar acciones por defecto cuando la ficha no tiene pasos en la base', () => {
  const actions = fichaFallbackActions(sample, 'ChatGPT')
  assert.ok(actions.length >= 3)
  assert.ok(actions.some((line) => line.includes('ChatGPT')))
  assert.ok(actions.some((line) => line.includes('audiencia')))
})

test('los criterios de éxito usan el aprendizaje y el checklist del último paso', () => {
  const checks = fichaSuccessChecks(sample)
  assert.ok(checks.includes(sample.learning))
  assert.ok(checks.includes('Meta escrita'))
  assert.ok(checks.some((line) => line.includes('error típico')))
})