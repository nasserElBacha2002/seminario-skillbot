import assert from 'node:assert/strict'
import test from 'node:test'
import { hasRecommendationInput, rankUseCases, selectRecommendations } from './matching.js'

const options = {
  area: [
    { value: 'marketing', label: 'Marketing' },
    { value: 'finanzas', label: 'Finanzas' },
    { value: 'administracion', label: 'Administración' },
  ],
  problem: [
    { value: 'atraer_clientes', label: 'Conseguir clientes' },
    { value: 'controlar_gastos', label: 'Controlar gastos' },
    { value: 'medir_resultados', label: 'Medir si funciona' },
  ],
  goal: [
    { value: 'conseguir_clientes', label: 'Conseguir clientes' },
    { value: 'ordenar_finanzas', label: 'Ordenar las finanzas' },
  ],
  tool: [
    { value: 'excel', label: 'Excel' },
    { value: 'instagram', label: 'Instagram' },
    { value: 'canva', label: 'Canva' },
    { value: 'copilot', label: 'Copilot' },
    { value: 'ninguna', label: 'Ninguna por ahora' },
  ],
  experience: [
    { value: 'nunca', label: 'Nunca usé IA' },
    { value: 'alguna_vez', label: 'La probé alguna vez' },
    { value: 'en_el_negocio', label: 'La uso en el negocio' },
  ],
  time: [
    { value: 'menos_15', label: 'Menos de 15 minutos' },
    { value: 'de_30_a_60', label: 'De 30 a 60 minutos' },
  ],
}

function useCase({ id, area = null, tags = [], minutes = 30, sortOrder = 10, practice = false }) {
  return {
    id,
    area,
    tags,
    minutes,
    sortOrder,
    fields: practice ? [{ key: 'dato', practice: true }] : [],
    challenges: practice ? [{}, {}, {}] : [],
    outputTemplate: practice ? '{{dato}}' : '',
  }
}

function answers(extra = {}) {
  return {
    areas: [],
    problems: [],
    tools: [],
    aiExperience: '',
    primaryGoal: '',
    availableTime: '',
    ...extra,
  }
}

function find(ranked, id) {
  return ranked.find((item) => item.id === id)
}

function assertScore(entry) {
  const { problems, goal, area, compatibility, time } = entry.breakdown
  assert.equal(entry.score, problems + goal + area + compatibility + time)
  assert.ok(entry.score >= 0 && entry.score <= 100)
  for (const value of Object.values(entry.breakdown)) assert.ok(value >= 0)
}

test('una sola área suma 20 y no se lleva los casos de otra', () => {
  const ranked = rankUseCases(answers({ areas: ['finanzas'] }), [
    useCase({ id: 'finanzas-caso', area: 'finanzas', sortOrder: 2 }),
    useCase({ id: 'marketing-caso', area: 'marketing', sortOrder: 1 }),
  ], options)
  assert.equal(find(ranked, 'finanzas-caso').breakdown.area, 20)
  assert.equal(find(ranked, 'marketing-caso').breakdown.area, 0)
  assert.equal(ranked[0].id, 'finanzas-caso')
  ranked.forEach(assertScore)
})

test('varias áreas reparten los 20 puntos sin duplicar columna y etiqueta', () => {
  const ranked = rankUseCases(answers({ areas: ['marketing', 'finanzas'] }), [
    useCase({
      id: 'mixto',
      area: 'marketing',
      tags: [{ kind: 'area', value: 'marketing' }, { kind: 'area', value: 'finanzas' }],
    }),
    useCase({ id: 'solo-marketing', area: 'marketing' }),
  ], options)
  assert.equal(find(ranked, 'mixto').breakdown.area, 20)
  assert.equal(find(ranked, 'solo-marketing').breakdown.area, 10)
})

test('un caso de otra área gana si responde el problema', () => {
  const ranked = rankUseCases(answers({
    areas: ['marketing'],
    problems: ['controlar_gastos', 'atraer_clientes'],
  }), [
    useCase({ id: 'area-sola', area: 'marketing', sortOrder: 1 }),
    useCase({ id: 'gastos', area: 'finanzas', tags: [{ kind: 'problem', value: 'controlar_gastos' }], sortOrder: 50 }),
  ], options)
  assert.equal(ranked[0].id, 'gastos')
  assert.equal(find(ranked, 'gastos').breakdown.problems, 30)
  assert.equal(find(ranked, 'gastos').breakdown.area, 0)
  assert.equal(find(ranked, 'area-sola').breakdown.problems, 0)
  assert.equal(find(ranked, 'area-sola').breakdown.area, 20)
  assert.ok(find(ranked, 'gastos').score > find(ranked, 'area-sola').score)
})

test('dos casos del mismo rubro se ordenan por la coincidencia concreta', () => {
  const ranked = rankUseCases(answers({
    areas: ['finanzas'],
    problems: ['controlar_gastos'],
    primaryGoal: 'ordenar_finanzas',
  }), [
    useCase({ id: 'solo-area', area: 'finanzas', sortOrder: 1 }),
    useCase({
      id: 'gastos-y-objetivo',
      area: 'finanzas',
      sortOrder: 8,
      tags: [
        { kind: 'problem', value: 'controlar_gastos' },
        { kind: 'goal', value: 'ordenar_finanzas' },
      ],
    }),
  ], options)
  assert.equal(ranked[0].id, 'gastos-y-objetivo')
  assert.equal(find(ranked, 'gastos-y-objetivo').breakdown.goal, 25)
  assert.equal(find(ranked, 'solo-area').breakdown.goal, 0)
  assert.ok(find(ranked, 'gastos-y-objetivo').score > find(ranked, 'solo-area').score)
})

test('el objetivo exacto vale 25 y otro objetivo no suma', () => {
  const ranked = rankUseCases(answers({ primaryGoal: 'conseguir_clientes' }), [
    useCase({ id: 'clientes', tags: [{ kind: 'goal', value: 'conseguir_clientes' }] }),
    useCase({ id: 'finanzas', tags: [{ kind: 'goal', value: 'ordenar_finanzas' }] }),
  ], options)
  assert.equal(find(ranked, 'clientes').breakdown.goal, 25)
  assert.equal(find(ranked, 'finanzas').breakdown.goal, 0)
})

test('el mismo problema reparte el mismo puntaje y no premia etiquetas de más', () => {
  const ranked = rankUseCases(answers({ problems: ['controlar_gastos'] }), [
    useCase({
      id: 'una',
      tags: [{ kind: 'problem', value: 'controlar_gastos' }],
      sortOrder: 3,
    }),
    useCase({
      id: 'varias',
      tags: [
        { kind: 'problem', value: 'controlar_gastos' },
        { kind: 'problem', value: 'atraer_clientes' },
        { kind: 'problem', value: 'medir_resultados' },
      ],
      sortOrder: 4,
    }),
  ], options)
  assert.equal(find(ranked, 'una').breakdown.problems, 40)
  assert.equal(find(ranked, 'varias').breakdown.problems, 40)
})

test('la experiencia inicial no elimina el caso y suma menos que la avanzada', () => {
  const catalog = [useCase({
    id: 'negocio',
    tags: [{ kind: 'experience', value: 'en_el_negocio' }],
  })]
  const beginner = rankUseCases(answers({ aiExperience: 'nunca' }), catalog, options)[0]
  const advanced = rankUseCases(answers({ aiExperience: 'en_el_negocio' }), catalog, options)[0]
  assert.equal(beginner.breakdown.compatibility, 1)
  assert.equal(advanced.breakdown.compatibility, 4)
  assert.equal(beginner.practiceReady, false)
  assertScore(beginner)
  assertScore(advanced)
})

test('ninguna no suma herramientas y una herramienta sin cobertura tampoco', () => {
  const catalog = [useCase({ id: 'excel', tags: [{ kind: 'tool', value: 'excel' }] })]
  const none = rankUseCases(answers({ tools: ['ninguna'] }), catalog, options)[0]
  const missing = rankUseCases(answers({ tools: ['copilot'] }), catalog, options)[0]
  const hit = rankUseCases(answers({ tools: ['excel'] }), catalog, options)[0]
  assert.equal(none.breakdown.compatibility, 0)
  assert.equal(missing.breakdown.compatibility, 0)
  assert.equal(hit.breakdown.compatibility, 6)
  assert.deepEqual(none.reasons, [])
})

test('canva del onboarding coincide con la etiqueta diseno del catálogo viejo', () => {
  const ranked = rankUseCases(answers({ tools: ['canva'] }), [
    useCase({ id: 'pieza', tags: [{ kind: 'tool', value: 'diseno' }] }),
  ], options)
  assert.equal(ranked[0].breakdown.compatibility, 6)
  assert.deepEqual(ranked[0].reasons, [{ kind: 'tool', value: 'canva' }])
})

test('un caso más corto entra en el tiempo y uno más largo queda compatible pero más abajo', () => {
  const short = rankUseCases(answers({ availableTime: 'de_30_a_60' }), [
    useCase({ id: 'corto', minutes: 20 }),
  ], options)[0]
  const long = rankUseCases(answers({ availableTime: 'menos_15' }), [
    useCase({ id: 'largo', minutes: 60 }),
  ], options)[0]
  assert.equal(short.breakdown.time, 5)
  assert.equal(long.breakdown.time, 1.25)
  assert.equal(long.score > 0, true)
})

test('una ficha sin práctica compite igual y el estado queda aparte', () => {
  const ranked = rankUseCases(answers({ problems: ['medir_resultados'] }), [
    useCase({
      id: 'guia',
      practice: true,
      sortOrder: 4,
      tags: [{ kind: 'problem', value: 'medir_resultados' }],
    }),
    useCase({
      id: 'ficha',
      practice: false,
      sortOrder: 2,
      tags: [{ kind: 'problem', value: 'medir_resultados' }],
    }),
  ], options)
  assert.equal(find(ranked, 'guia').score, find(ranked, 'ficha').score)
  assert.equal(find(ranked, 'guia').practiceReady, true)
  assert.equal(find(ranked, 'ficha').practiceReady, false)
  assert.equal(ranked[0].id, 'ficha')
})

test('el empate usa sort_order y después el id', () => {
  const byOrder = rankUseCases(answers({ areas: ['marketing'] }), [
    useCase({ id: 'tarde', area: 'marketing', sortOrder: 9 }),
    useCase({ id: 'temprano', area: 'marketing', sortOrder: 2 }),
  ], options)
  assert.deepEqual(byOrder.map((item) => item.id), ['temprano', 'tarde'])

  const byId = rankUseCases(answers({ areas: ['marketing'] }), [
    useCase({ id: 'b-caso', area: 'marketing', sortOrder: 4 }),
    useCase({ id: 'a-caso', area: 'marketing', sortOrder: 4 }),
  ], options)
  assert.deepEqual(byId.map((item) => item.id), ['a-caso', 'b-caso'])
  assert.deepEqual(byId.map((item) => item.position), [1, 2])
})

test('sin respuestas, con ids inválidos o sin etiquetas no se inventa un puntaje', () => {
  const catalog = [
    useCase({ id: 'vacio', sortOrder: 2 }),
    useCase({ id: 'con-area', area: 'finanzas', sortOrder: 1, tags: [{ kind: 'problem', value: 'controlar_gastos' }] }),
  ]
  const empty = rankUseCases(null, catalog, options)
  assert.deepEqual(empty.map((item) => item.score), [0, 0])
  assert.deepEqual(empty.map((item) => item.id), ['con-area', 'vacio'])
  assert.equal(hasRecommendationInput(null), false)
  assert.equal(hasRecommendationInput(answers()), false)
  assert.equal(hasRecommendationInput(answers({ tools: ['ninguna'] })), false)

  const invalid = rankUseCases(answers({
    areas: ['no-existe'],
    problems: ['controlar_gastos', 'inventado'],
    primaryGoal: 'otro',
    aiExperience: 'experto',
    availableTime: 'un-rato',
  }), catalog, options)
  assert.equal(find(invalid, 'con-area').breakdown.problems, 40)
  assert.equal(find(invalid, 'con-area').breakdown.area, 0)
  assert.equal(find(invalid, 'con-area').breakdown.goal, 0)
  assert.equal(find(invalid, 'vacio').score, 0)
  assert.equal(hasRecommendationInput(answers({ problems: ['controlar_gastos'] })), true)
})

test('el mismo perfil produce el mismo orden', () => {
  const catalog = [
    useCase({ id: 'b', area: 'marketing', minutes: 40, sortOrder: 3, tags: [{ kind: 'problem', value: 'atraer_clientes' }] }),
    useCase({ id: 'a', area: 'finanzas', minutes: 15, sortOrder: 1, tags: [{ kind: 'tool', value: 'excel' }] }),
  ]
  const profile = answers({
    areas: ['marketing', 'finanzas'],
    problems: ['atraer_clientes'],
    tools: ['excel'],
    aiExperience: 'alguna_vez',
    primaryGoal: 'conseguir_clientes',
    availableTime: 'de_30_a_60',
  })
  assert.deepEqual(rankUseCases(profile, catalog, options), rankUseCases(profile, catalog, options))
})

const gastos = [{ kind: 'problem', value: 'controlar_gastos' }]
const gastosYObjetivo = [...gastos, { kind: 'goal', value: 'ordenar_finanzas' }]

test('una práctica que coincide con un problema entra al inicio y va primero sin cambiar el puntaje', () => {
  const ranking = rankUseCases(answers({ areas: ['finanzas'], problems: ['controlar_gastos'], primaryGoal: 'ordenar_finanzas' }), [
    ...Array.from({ length: 6 }, (_, index) => useCase({ id: `ficha-${index}`, area: 'finanzas', sortOrder: index, tags: gastosYObjetivo })),
    useCase({ id: 'practica', sortOrder: 20, practice: true, tags: gastos }),
  ], options)
  const practice = find(ranking, 'practica')
  assert.equal(practice.position, 7)

  const selected = selectRecommendations(ranking)
  assert.equal(selected.length, 6)
  assert.equal(selected[0], practice)
  assert.deepEqual(selected.slice(1).map((item) => item.id), ['ficha-0', 'ficha-1', 'ficha-2', 'ficha-3', 'ficha-4'])
  assertScore(selected[0])
})

test('una práctica que solo comparte área, herramienta o tiempo no se adelanta', () => {
  const ranking = rankUseCases(answers({ areas: ['finanzas'], problems: ['controlar_gastos'], tools: ['excel'], availableTime: 'de_30_a_60' }), [
    ...Array.from({ length: 6 }, (_, index) => useCase({ id: `ficha-${index}`, sortOrder: index, tags: gastos })),
    useCase({ id: 'practica', area: 'finanzas', sortOrder: 20, practice: true, tags: [{ kind: 'tool', value: 'excel' }] }),
  ], options)
  const selected = selectRecommendations(ranking)
  assert.ok(find(ranking, 'practica').score > 0)
  assert.equal(find(selected, 'practica'), undefined)
})

test('las prácticas ocupan como mucho la mitad y el resto sigue el puntaje', () => {
  const ranking = rankUseCases(answers({ problems: ['controlar_gastos'], primaryGoal: 'ordenar_finanzas' }), [
    ...Array.from({ length: 3 }, (_, index) => useCase({ id: `ficha-${index}`, sortOrder: index, tags: gastosYObjetivo })),
    ...Array.from({ length: 5 }, (_, index) => useCase({ id: `practica-${index}`, sortOrder: 10 + index, practice: true, tags: gastos })),
  ], options)
  const selected = selectRecommendations(ranking)
  assert.deepEqual(selected.map((item) => item.id), ['practica-0', 'practica-1', 'practica-2', 'ficha-0', 'ficha-1', 'ficha-2'])

  const more = selectRecommendations(ranking, { practiceSlots: 6 })
  assert.equal(more.filter((item) => item.practiceReady).length, 5)
})

test('la selección no incluye casos sin puntaje ni pasa el límite', () => {
  const ranking = rankUseCases(answers({ problems: ['controlar_gastos'] }), [
    useCase({ id: 'practica', practice: true, tags: gastos }),
    useCase({ id: 'sin-coincidencia', practice: true }),
    useCase({ id: 'ficha', tags: gastos }),
  ], options)
  assert.deepEqual(selectRecommendations(ranking).map((item) => item.id), ['practica', 'ficha'])
  assert.deepEqual(selectRecommendations(ranking, { limit: 1 }).map((item) => item.id), ['practica'])
  assert.deepEqual(selectRecommendations(null), [])
})
