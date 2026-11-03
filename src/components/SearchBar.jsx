import { Search } from 'lucide-react'

export function SearchBar({
  value,
  onChange,
  id = 'case-search',
  label = 'Buscar un problema o una tarea',
  placeholder = 'Buscá un problema o una tarea...',
}) {
  return (
    <div className="search-box">
      <Search size={20} aria-hidden="true" />
      <label className="sr-only" htmlFor={id}>{label}</label>
      <input
        id={id}
        type="search"
        value={value}
        enterKeyHint="search"
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
      />
    </div>
  )
}
