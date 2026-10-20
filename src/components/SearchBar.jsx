import { Search } from 'lucide-react'

export function SearchBar({ value, onChange, id = 'case-search' }) {
  return (
    <div className="search-box">
      <Search size={20} aria-hidden="true" />
      <label className="sr-only" htmlFor={id}>Buscar un problema o una tarea</label>
      <input
        id={id}
        type="search"
        value={value}
        enterKeyHint="search"
        onChange={(event) => onChange(event.target.value)}
        placeholder="Buscá un problema o una tarea..."
      />
    </div>
  )
}
