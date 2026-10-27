const STOPWORDS = new Set([
  'a', 'al', 'algo', 'con', 'como', 'de', 'del', 'el', 'en', 'es', 'esa', 'ese', 'eso', 'esta', 'este', 'esto',
  'hacer', 'hago', 'hay', 'hoy', 'la', 'las', 'le', 'les', 'lo', 'los', 'manana', 'mas', 'me', 'mi', 'mis',
  'necesito', 'o', 'para', 'pero', 'por', 'que', 'queres', 'quiero', 'se', 'sin', 'sobre', 'son', 'su', 'sus',
  'te', 'tenes', 'tengo', 'tu', 'tus', 'un', 'una', 'unas', 'uno', 'unos', 'y', 'ya',
])

const SYNONYM_GROUPS = [
  ['ppt', 'pptx', 'powerpoint', 'slides', 'slide', 'diapositiva', 'diapositivas', 'presentacion', 'presentaciones'],
  ['excel', 'xlsx', 'sheets', 'planilla', 'planillas'],
  ['mail', 'email', 'correo', 'mails', 'correos'],
  ['estudiar', 'estudio', 'examen', 'parcial', 'certificacion', 'pdf'],
  ['resumen', 'resumir', 'resumime', 'sintesis'],
  ['imagen', 'imagenes', 'foto', 'fotos', 'instagram', 'redes'],
  ['reunion', 'minuta', 'seguimiento', 'acta'],
  ['automatizar', 'automatizacion', 'script', 'macro', 'macros'],
]

const FIELD_WEIGHT = {
  title: 10,
  category: 5,
  description: 3,
  situation: 2,
  survey: 1,
  mistake: 1,
}

const TITLE_SYNONYM_WEIGHT = 8
const MISSING_TOKEN_PENALTY = 1

export function normalize(value) {
  return String(value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

export function significantTokens(value) {
  return normalize(value)
    .split(' ')
    .filter((token) => token.length > 1 && !STOPWORDS.has(token))
}

function expand(token) {
  const group = SYNONYM_GROUPS.find((words) => words.includes(token))
  return group ?? [token]
}

function fieldText(item, field) {
  if (field === 'category') return [item.category, ...(item.categoryNames ?? [])].filter(Boolean).join(' ')
  if (field === 'survey') return (item.survey ?? []).map((task) => task.task).join(' ')
  if (field === 'description') return item.description ?? ''
  return item[field] ?? ''
}

function weightFor(item, token) {
  const alternatives = expand(token).map((word) => normalize(word))
  const direct = normalize(token)
  let best = 0
  for (const [field, weight] of Object.entries(FIELD_WEIGHT)) {
    const text = normalize(fieldText(item, field))
    if (!text) continue
    if (text.includes(direct)) {
      best = Math.max(best, weight)
      continue
    }
    const synonymHit = alternatives.some((word) => word !== direct && text.includes(word))
    if (!synonymHit) continue
    best = Math.max(best, field === 'title' ? TITLE_SYNONYM_WEIGHT : weight)
  }
  return best
}

function scoreCase(item, tokens) {
  let score = 0
  let hits = 0
  for (const token of tokens) {
    const weight = weightFor(item, token)
    if (weight > 0) {
      score += weight
      hits += 1
    } else {
      score -= MISSING_TOKEN_PENALTY
    }
  }
  if (hits === 0 || score <= 0) return 0
  return score
}

export function searchUseCases(useCases, term) {
  const tokens = significantTokens(term)
  if (!tokens.length) {
    return [...useCases].sort((a, b) => b.demand - a.demand)
  }
  return useCases
    .map((item) => ({ item, score: scoreCase(item, tokens) }))
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score || b.item.demand - a.item.demand)
    .map((entry) => entry.item)
}
