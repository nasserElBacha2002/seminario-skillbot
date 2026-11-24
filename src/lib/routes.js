const ORIGINS = new Set(['inicio', 'explorar', 'ayuda'])

function normalizePath(pathname) {
  const path = (pathname || '/').replace(/\/+$/, '')
  return path || '/'
}

export function parsePath(pathname = '', search = '') {
  const path = normalizePath(pathname)
  const params = new URLSearchParams(search || '')

  const caseMatch = path.match(/^\/caso\/([^/]+)$/)
  if (caseMatch) {
    const from = params.get('from')
    return {
      page: 'detalle',
      caseId: decodeURIComponent(caseMatch[1]),
      origin: ORIGINS.has(from) ? from : 'inicio',
      area: 'todos',
      askCaseId: null,
    }
  }

  if (path === '/' || path === '/inicio') {
    return { page: 'inicio', caseId: null, origin: 'inicio', area: 'todos', askCaseId: null }
  }
  if (path === '/explorar') {
    const area = params.get('area') || 'todos'
    return { page: 'explorar', caseId: null, origin: 'inicio', area, askCaseId: null }
  }
  if (path === '/progreso') {
    return { page: 'progreso', caseId: null, origin: 'inicio', area: 'todos', askCaseId: null }
  }
  if (path === '/perfil') {
    return { page: 'perfil', caseId: null, origin: 'inicio', area: 'todos', askCaseId: null }
  }
  if (path === '/ayuda') {
    const caso = params.get('caso')
    return { page: 'ayuda', caseId: null, origin: 'inicio', area: 'todos', askCaseId: caso || null }
  }

  return { page: 'inicio', caseId: null, origin: 'inicio', area: 'todos', askCaseId: null }
}

export function pathForRoute(route) {
  const { page, caseId, origin, area, askCaseId } = route

  if ((page === 'detalle' || page === 'desafio') && caseId) {
    const query = origin && origin !== 'inicio' ? `?from=${encodeURIComponent(origin)}` : ''
    return `/caso/${encodeURIComponent(caseId)}${query}`
  }
  if (page === 'explorar') {
    return area && area !== 'todos' ? `/explorar?area=${encodeURIComponent(area)}` : '/explorar'
  }
  if (page === 'ayuda') {
    return askCaseId ? `/ayuda?caso=${encodeURIComponent(askCaseId)}` : '/ayuda'
  }
  if (page === 'progreso') return '/progreso'
  if (page === 'perfil') return '/perfil'
  return '/'
}

export function defaultRoute() {
  return parsePath('/', '')
}