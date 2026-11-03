import { useMemo, useState } from 'react'
import { useSkillbotData } from '../context/SkillbotData'
import { searchUseCases } from '../lib/search'
import { SearchBar } from './SearchBar'
import { UseCaseCard } from './UseCaseCard'

export function CaseBrowser({ onOpen, searchId }) {
  const { data } = useSkillbotData()
  const [filter, setFilter] = useState('todos')
  const [term, setTerm] = useState('')
  const filters = [{ id: 'todos', name: 'Todos' }, ...data.categories]
  const shown = useMemo(() => {
    const found = searchUseCases(data.useCases, term)
    if (filter === 'todos') return found
    return found.filter((item) => item.categoryIds.includes(filter))
  }, [data.useCases, term, filter])
  const suggestions = useMemo(
    () => [...data.useCases].sort((a, b) => b.demand - a.demand).slice(0, 3),
    [data.useCases],
  )
  const searching = term.trim().length > 0 || filter !== 'todos'

  return (
    <div className="case-browser">
      <SearchBar id={searchId} value={term} onChange={setTerm} />
      <div className="filters" role="group" aria-label="Filtrar por tipo de tarea">
        {filters.map((item) => (
          <button
            key={item.id}
            type="button"
            className={filter === item.id ? 'selected' : ''}
            aria-pressed={filter === item.id}
            onClick={() => setFilter(item.id)}
          >
            {item.name}
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
          <p>Probá con palabras más cortas, como presentación, excel o mail.</p>
          {searching && (
            <button type="button" className="secondary" onClick={() => { setTerm(''); setFilter('todos') }}>
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
