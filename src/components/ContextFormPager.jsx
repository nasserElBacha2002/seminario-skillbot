import { useEffect, useId, useMemo, useRef, useState } from 'react'
import { ClipboardList } from 'lucide-react'
import { saveDraft } from '../lib/storage'
import { contextFieldsForPager } from '../lib/practiceFlow'
import { CaseFlowScene } from './CaseFlowScene'
import { CaseFieldInput } from './CaseFieldInput'
import { PagerChrome } from './PagerChrome'

function fieldId(formId, key) {
  return `${formId}-${key}`
}

export function ContextFormPager({ useCase, initialValues, onSubmit, onExit, onBackIntro }) {
  const formId = useId()
  const [page, setPage] = useState(0)
  const [anim, setAnim] = useState('fwd')
  const [values, setValues] = useState(initialValues ?? {})
  const fields = useMemo(() => contextFieldsForPager(useCase, values), [useCase, values])
  const total = 1 + fields.length
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const focusRef = useRef(null)
  const last = page >= total - 1
  const fieldIndex = page - 1
  const field = fieldIndex >= 0 ? fields[fieldIndex] : null
  const progress = Math.round(((page + 1) / total) * 100)

  useEffect(() => {
    saveDraft(useCase.id, values)
  }, [useCase.id, values])

  useEffect(() => {
    focusRef.current?.focus()
  }, [page])

  function go(next) {
    const target = Math.max(0, Math.min(total - 1, next))
    if (target === page) return
    setAnim(target > page ? 'fwd' : 'back')
    setPage(target)
  }

  function validateField(targetField) {
    if (!targetField?.required) return true
    const value = String(values[targetField.key] ?? '').trim()
    if (value) return true
    setErrors((current) => ({ ...current, [targetField.key]: 'Completá este dato para poder armar el pedido.' }))
    return false
  }

  async function handlePrimary() {
    if (page === 0) {
      go(1)
      return
    }
    if (!validateField(field)) return

    if (!last) {
      go(page + 1)
      return
    }

    const nextErrors = {}
    for (const item of fields) {
      const value = String(values[item.key] ?? '').trim()
      if (item.required && !value) nextErrors[item.key] = 'Completá este dato para poder armar el pedido.'
    }
    if (Object.keys(nextErrors).length > 0) {
      setErrors(nextErrors)
      const firstKey = fields.find((item) => nextErrors[item.key])?.key
      const jump = fields.findIndex((item) => item.key === firstKey)
      if (jump >= 0) go(jump + 1)
      return
    }

    setSubmitting(true)
    try {
      await onSubmit(values)
    } finally {
      setSubmitting(false)
    }
  }

  function handleBack() {
    if (page === 0) onBackIntro()
    else go(page - 1)
  }

  const primaryLabel = page === 0
    ? 'Empezar'
    : last
      ? (submitting ? 'Armando…' : 'Continuar')
      : 'Siguiente'

  return (
    <CaseFlowScene panelClass="is-context">
      <PagerChrome
        page={page}
        total={total}
        progress={progress}
        onExit={onExit}
        onBack={handleBack}
        backDisabled={submitting}
        onPrimary={handlePrimary}
        primaryLabel={primaryLabel}
        primaryDisabled={submitting}
      >
        <article className={`ficha-pager-slide tone-context ficha-anim-${anim}`} key={page}>
          {page === 0 && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-objective" aria-hidden><ClipboardList size={18} /></span>
                <p className="ficha-pager-label">Tu situación</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">Contanos tu caso</h2>
              <p className="ficha-pager-lead">
                Son {fields.length} datos cortos. Con eso personalizamos los desafíos y el pedido final.
              </p>
            </>
          )}

          {field && (
            <>
              <div className="ficha-pager-slide-head">
                <span className="ficha-pager-badge tone-action" aria-hidden><ClipboardList size={18} /></span>
                <p className="ficha-pager-label">Dato {fieldIndex + 1} de {fields.length}</p>
              </div>
              <h2 ref={focusRef} tabIndex={-1} className="ficha-pager-slide-title">
                {field.label}
                {!field.required && <span className="field-optional"> Opcional</span>}
              </h2>
              <CaseFieldInput
                field={field}
                id={fieldId(formId, field.key)}
                value={values[field.key] ?? ''}
                error={errors[field.key]}
                onChange={(value) => {
                  setValues((current) => ({ ...current, [field.key]: value }))
                  if (errors[field.key]) {
                    setErrors((current) => {
                      const next = { ...current }
                      delete next[field.key]
                      return next
                    })
                  }
                }}
              />
            </>
          )}
        </article>
      </PagerChrome>
    </CaseFlowScene>
  )
}