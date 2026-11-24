import { test } from 'node:test'
import assert from 'node:assert/strict'
import { parsePath, pathForRoute } from './routes.js'

test('parsea la home y un caso con origen', () => {
  assert.deepEqual(parsePath('/'), { page: 'inicio', caseId: null, origin: 'inicio', area: 'todos', askCaseId: null })
  assert.deepEqual(parsePath('/caso/ventas-sin-formulas'), {
    page: 'detalle',
    caseId: 'ventas-sin-formulas',
    origin: 'inicio',
    area: 'todos',
    askCaseId: null,
  })
  assert.equal(
    parsePath('/caso/foo', '?from=explorar').origin,
    'explorar',
  )
})

test('arma rutas canónicas', () => {
  assert.equal(pathForRoute({ page: 'explorar', area: 'finanzas' }), '/explorar?area=finanzas')
  assert.equal(
    pathForRoute({ page: 'detalle', caseId: 'auditoria-instagram', origin: 'ayuda' }),
    '/caso/auditoria-instagram?from=ayuda',
  )
})