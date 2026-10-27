import { useState } from 'react'
import { ArrowRight, LoaderCircle } from 'lucide-react'
import { AuthLayout } from '../components/AuthLayout'
import { Logo } from '../components/Layout'
import { useAuth } from '../context/Auth'

const MIN_PASSWORD = 8

function updateMessage(error) {
  const code = String(error?.code ?? '')
  const status = error?.status
  const text = String(error?.message ?? '').toLowerCase()
  if (code === 'same_password' || text.includes('different from the old password') || text.includes('should be different')) {
    return 'La nueva contraseña tiene que ser distinta a la anterior.'
  }
  if (code === 'weak_password' || (text.includes('password') && (text.includes('least') || text.includes('short') || text.includes('weak')))) {
    return `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`
  }
  if (
    code === 'session_expired'
    || error?.name === 'AuthSessionMissingError'
    || status === 401
    || text.includes('session')
    || text.includes('not authenticated')
  ) {
    return 'El enlace de recuperación venció. Pedí uno nuevo desde el login.'
  }
  if (error?.name === 'AuthRetryableFetchError' || text.includes('failed to fetch') || text.includes('network')) {
    return 'No pudimos actualizar la contraseña. Intentá nuevamente.'
  }
  return 'No pudimos actualizar la contraseña. Intentá nuevamente.'
}

function validate(password, confirmPassword) {
  if (password.length < MIN_PASSWORD) return `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`
  if (!confirmPassword || password !== confirmPassword) return 'Las contraseñas no coinciden.'
  return ''
}

export function UpdatePassword() {
  const { updatePassword, completePasswordRecovery } = useAuth()
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [updated, setUpdated] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    const localError = validate(password, confirmPassword)
    if (localError) {
      setError(localError)
      return
    }
    setError('')
    setSubmitting(true)
    try {
      await updatePassword(password)
      setPassword('')
      setConfirmPassword('')
      setUpdated(true)
    } catch (updateError) {
      setError(updateMessage(updateError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AuthLayout>
      {updated ? (
        <div className="login-form">
          <div className="mobile-logo"><Logo /></div>
          <h2>Contraseña actualizada</h2>
          <p>Ya podés continuar con tu cuenta usando la nueva contraseña.</p>
          <button type="button" className="primary login-button" onClick={completePasswordRecovery}>
            Continuar
            <ArrowRight size={18} />
          </button>
        </div>
      ) : (
        <form className="login-form" onSubmit={handleSubmit} noValidate>
          <div className="mobile-logo"><Logo /></div>
          <h2>Nueva contraseña</h2>
          <p>Elegí una contraseña nueva para tu cuenta.</p>
          <label>
            Nueva contraseña
            <input
              type="password"
              autoComplete="new-password"
              placeholder="••••••••"
              value={password}
              onChange={(event) => {
                setPassword(event.target.value)
                if (error) setError('')
              }}
              disabled={submitting}
              aria-invalid={Boolean(error)}
            />
            <small className="login-hint">Mínimo {MIN_PASSWORD} caracteres.</small>
          </label>
          <label>
            Confirmar contraseña
            <input
              type="password"
              autoComplete="new-password"
              placeholder="••••••••"
              value={confirmPassword}
              onChange={(event) => {
                setConfirmPassword(event.target.value)
                if (error) setError('')
              }}
              disabled={submitting}
              aria-invalid={Boolean(error)}
            />
          </label>
          {error && <p className="login-error" role="alert">{error}</p>}
          <button type="submit" className="primary login-button" disabled={submitting} aria-busy={submitting}>
            {submitting ? <LoaderCircle size={18} className="spin" /> : null}
            {submitting ? 'Guardando…' : 'Guardar contraseña'}
            {submitting ? null : <ArrowRight size={18} />}
          </button>
        </form>
      )}
    </AuthLayout>
  )
}
