import { useMemo, useState } from 'react'
import { useSkillbotData } from '../context/SkillbotData'
import { BUSINESS_AREAS } from '../lib/matching'
import { searchUseCases } from '../lib/search'
import { SearchBar } from './SearchBar'
import { UseCaseCard } from './UseCaseCard'

export function CaseBrowser({ onOpen, searchId, area = 'todos', onAreaChange }) {
  const { data } = useSkillbotData()
  const [term, setTerm] = useState('')
  const areas = [{ id: 'todos', label: 'Todas' }, ...BUSINESS_AREAS]
  const shown = useMemo(() => {
    const found = searchUseCases(data.useCases, term)
    if (area === 'todos') return found
    return found.filter((item) => item.area === area)
  }, [data.useCases, term, area])
  const suggestions = useMemo(
    () => [...data.useCases].sort((a, b) => b.demand - a.demand).slice(0, 3),
    [data.useCases],
  )
  const searching = term.trim().length > 0

  return (
    <div className="case-browser">
      <SearchBar id={searchId} value={term} onChange={setTerm} />
      <p className="filter-label" id={`${searchId}-areas`}>Área del negocio</p>
      <div className="filters" role="group" aria-labelledby={`${searchId}-areas`}>
        {areas.map((item) => (
          <button
            key={item.id}
            type="button"
            className={area === item.id ? 'selected' : ''}
            aria-pressed={area === item.id}
            onClick={() => onAreaChange?.(item.id)}
          >
            {item.label}
          </button>
        ))}
      </div>
      {shown.length > 0 ? (
        <div className="use-cases-grid">
          {shown.map((item) => <UseCaseCard key={item.id} item={item} onOpen={onOpen} />)}
        </div>
      ) : (
        <div className="empty-results" role="status">
          <h2>No encontramos un caso exactamente para eso.</h2>
          <p>Probá con otra área o con palabras más cortas, como presentación, excel o mail.</p>
          {searching && (
            <button type="button" className="secondary" onClick={() => setTerm('')}>
              Limpiar búsqueda
            </button>
          )}
          <div className="empty-suggestions">
            <p>Estos casos suelen servir como punto de partida.</p>
            <div className="use-cases-grid">
              {suggestions.map((item) => <UseCaseCard key={item.id} item={item} onOpen={onOpen} />)}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
