const PLACEHOLDER = /\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/g

function keysIn(line) {
  return [...line.matchAll(PLACEHOLDER)].map((match) => match[1])
}

function isBlank(value) {
  return value == null || !String(value).trim()
}

export function fillTemplate(template, values, optionalKeys = []) {
  if (!template) return ''
  const optional = new Set(optionalKeys)
  const lines = String(template).split('\n').filter((line) => {
    const keys = keysIn(line)
    if (!keys.length) return true
    return !keys.every((key) => optional.has(key) && isBlank(values?.[key]))
  })
  return lines.join('\n').replace(PLACEHOLDER, (_, key) => {
    const text = values?.[key] == null ? '' : String(values[key]).trim()
    return text || 'No especificado'
  })
}

export function unresolvedPlaceholders(text) {
  return text.match(/\{\{[^}]+\}\}/g) ?? []
}
