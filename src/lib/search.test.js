import assert from 'node:assert/strict'
import test from 'node:test'
import { searchUseCases } from './search.js'

const cases = [
  {
    id: 'imagenes-redes',
    title: 'Imágenes para redes que no parezcan hechas con IA',
    description: 'Una foto de producto para publicar.',
    situation: 'Necesitás una imagen y no un acceso a una cuenta.',
    category: 'Contenido y redacción',
    categoryNames: ['Contenido y redacción'],
    demand: 20,
  },
  {
    id: 'auditoria-instagram',
    title: 'Auditar una cuenta de Instagram con tus propias métricas',
    description: 'Interpretá el período con los números que copiás de Estadísticas.',
    situation: 'Publicás seguido y no sabés si el alcance justifica las piezas.',
    category: 'Datos y análisis',
    categoryNames: ['Datos y análisis'],
    demand: 4,
  },
  {
    id: 'ventas-sin-formulas',
    title: 'Entender mis ventas sin saber fórmulas',
    description: 'Sacá totales por vendedor desde una planilla.',
    situation: 'Tenés un Excel y no querés escribir la fórmula.',
    category: 'Datos y análisis',
    categoryNames: ['Datos y análisis'],
    demand: 30,
  },
]

test('instagram no arrastra cualquier caso de imágenes', () => {
  const found = searchUseCases(cases, 'instagram').map((item) => item.id)
  assert.deepEqual(found, ['auditoria-instagram'])
})

test('una búsqueda vacía ordena por demanda y no esconde casos', () => {
  const found = searchUseCases(cases, '   ').map((item) => item.id)
  assert.deepEqual(found, ['ventas-sin-formulas', 'imagenes-redes', 'auditoria-instagram'])
})

test('el filtro de texto sigue encontrando por título parcial', () => {
  const found = searchUseCases(cases, 'ventas').map((item) => item.id)
  assert.deepEqual(found, ['ventas-sin-formulas'])
})
