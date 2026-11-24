import { ShieldCheck } from 'lucide-react'

function isPrivateNote(helper) {
  return /no pegues|datos bancarios|mails|sensible/i.test(helper)
}

export function CaseFieldInput({ field, id, value, error, onChange }) {
  const describedBy = [field.helper ? `${id}-help` : '', error ? `${id}-error` : ''].filter(Boolean).join(' ')
  const privateNote = field.helper && isPrivateNote(field.helper)

  return (
    <div className="field field-pager">
      {field.helper && (
        <p id={`${id}-help`} className={privateNote ? 'field-help field-note' : 'field-help'}>
          {privateNote && <ShieldCheck size={14} aria-hidden="true" />}
          {field.helper}
        </p>
      )}
      {field.type === 'textarea' ? (
        <textarea
          id={id}
          name={field.key}
          rows={4}
          value={value}
          placeholder={field.placeholder}
          aria-invalid={Boolean(error)}
          aria-describedby={describedBy || undefined}
          onChange={(event) => onChange(event.target.value)}
        />
      ) : field.type === 'select' ? (
        <select
          id={id}
          name={field.key}
          className={value ? '' : 'is-placeholder'}
          value={value}
          aria-invalid={Boolean(error)}
          aria-describedby={describedBy || undefined}
          onChange={(event) => onChange(event.target.value)}
        >
          <option value="">{field.placeholder || 'Elegí una opción'}</option>
          {field.options.map((option) => <option key={option} value={option}>{option}</option>)}
        </select>
      ) : (
        <input
          id={id}
          name={field.key}
          type="text"
          value={value}
          placeholder={field.placeholder}
          aria-invalid={Boolean(error)}
          aria-describedby={describedBy || undefined}
          onChange={(event) => onChange(event.target.value)}
        />
      )}
      {error && <p id={`${id}-error`} className="field-error">{error}</p>}
    </div>
  )
}