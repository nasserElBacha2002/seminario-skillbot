import { useEffect, useId, useRef, useState } from 'react'
import { ShieldCheck } from 'lucide-react'
import { saveDraft } from '../lib/storage'

function isPrivateNote(helper) {
  return /no pegues|datos bancarios|mails|sensible/i.test(helper)
}

function fieldId(formId, key) {
  return `${formId}-${key}`
}

export function DynamicCaseForm({ useCase, initialValues, submitLabel, onSubmit, onCancel }) {
  const formId = useId()
  const submittingRef = useRef(false)
  const [values, setValues] = useState(initialValues ?? {})
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState('')

  useEffect(() => {
    saveDraft(useCase.id, values)
  }, [useCase.id, values])

  function update(key, value) {
    setValues((current) => ({ ...current, [key]: value }))
    setErrors((current) => {
      if (!current[key]) return current
      const next = { ...current }
      delete next[key]
      return next
    })
  }

  async function submit(event) {
    event.preventDefault()
    if (submittingRef.current) return
    const data = new FormData(event.currentTarget)
    const nextValues = { ...values }
    const nextErrors = {}
    for (const field of useCase.fields) {
      const value = String(data.get(field.key) ?? '')
      nextValues[field.key] = value
      if (field.required && !value.trim()) {
        nextErrors[field.key] = 'Completá este dato para poder armar el pedido.'
      }
    }
    setValues(nextValues)
    setErrors(nextErrors)
    const firstInvalid = useCase.fields.find((field) => nextErrors[field.key])
    if (firstInvalid) {
      document.getElementById(fieldId(formId, firstInvalid.key))?.focus()
      return
    }
    submittingRef.current = true
    setSubmitting(true)
    setSubmitError('')
    try {
      await onSubmit(nextValues)
    } catch {
      setSubmitError('No se pudo armar el pedido. Intentá de nuevo.')
    } finally {
      submittingRef.current = false
      setSubmitting(false)
    }
  }

  return (
    <form className="case-form" onSubmit={submit} noValidate autoComplete="off">
      {Object.keys(errors).length > 0 && (
        <p className="save-error" role="alert">Revisá los datos marcados para poder armar el pedido.</p>
      )}
      {submitError && <p className="save-error" role="alert">{submitError}</p>}
      <div className="form-card">
        {useCase.fields.map((field) => {
          const id = fieldId(formId, field.key)
          const value = values[field.key] ?? ''
          const describedBy = [field.helper ? `${id}-help` : '', errors[field.key] ? `${id}-error` : ''].filter(Boolean).join(' ')
          const privateNote = field.helper && isPrivateNote(field.helper)
          return (
            <div className="field" key={field.key}>
              <label htmlFor={id}>
                {field.label}
                {!field.required && <span className="field-optional"> Opcional</span>}
              </label>
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
                  rows={3}
                  value={value}
                  placeholder={field.placeholder}
                  aria-invalid={Boolean(errors[field.key])}
                  aria-describedby={describedBy || undefined}
                  onChange={(event) => update(field.key, event.target.value)}
                />
              ) : field.type === 'select' ? (
                <select
                  id={id}
                  name={field.key}
                  className={value ? '' : 'is-placeholder'}
                  value={value}
                  aria-invalid={Boolean(errors[field.key])}
                  aria-describedby={describedBy || undefined}
                  onChange={(event) => update(field.key, event.target.value)}
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
                  aria-invalid={Boolean(errors[field.key])}
                  aria-describedby={describedBy || undefined}
                  onChange={(event) => update(field.key, event.target.value)}
                />
              )}
              {errors[field.key] && <p id={`${id}-error`} className="field-error">{errors[field.key]}</p>}
            </div>
          )
        })}
      </div>
      <div className="case-actions form-actions">
        <button type="submit" className="primary" disabled={submitting} aria-busy={submitting}>
          {submitting ? 'Armando…' : submitLabel}
        </button>
        <button type="button" className="secondary" onClick={onCancel} disabled={submitting}>Volver</button>
      </div>
    </form>
  )
}
