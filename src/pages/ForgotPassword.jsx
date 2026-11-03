import { useState } from 'react'
import { ArrowRight, LoaderCircle } from 'lucide-react'
import { AuthLayout } from '../components/AuthLayout'
import { Logo } from '../components/Layout'
import { useAuth } from '../context/Auth'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function resetMessage(error) {
  const code = String(error?.code ?? '')
  const status = error?.status
  const text = String(error?.message ?? '').toLowerCase()
  if (code === 'over_email_send_rate_limit' || status === 429 || text.includes('rate limit') || text.includes('too many requests')) {
    return 'Demasiados intentos. Esperá un momento e intentá nuevamente.'
  }
  if (code === 'invalid_email' || text.includes('unable to validate email') || text.includes('invalid email')) {
    return 'Ingresá un email válido.'
  }
  if (error?.name === 'AuthRetryableFetchError' || text.includes('failed to fetch') || text.includes('network')) {
    return 'No pudimos enviar el correo. Intentá nuevamente.'
  }
  return 'No pudimos enviar el correo. Intentá nuevamente.'
}

export function ForgotPassword({ email, onEmailChange, onLogin }) {
  const { resetPasswordForEmail } = useAuth()
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [sent, setSent] = useState(false)

  function goToLogin() {
    setError('')
    setSent(false)
    onLogin()
  }

  async function handleSubmit(event) {
    event.preventDefault()
    const nextEmail = email.trim()
    if (!nextEmail || !EMAIL_PATTERN.test(nextEmail)) {
      setError('Ingresá un email válido.')
      return
    }
    setError('')
    setSubmitting(true)
    try {
      await resetPasswordForEmail(nextEmail)
      setSent(true)
    } catch (resetError) {
      setError(resetMessage(resetError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AuthLayout>
      {sent ? (
        <div className="login-form">
          <div className="mobile-logo"><Logo /></div>
          <h2>Revisá tu correo</h2>
          <p>Si hay una cuenta con ese email, te enviamos un enlace para restablecer la contraseña.</p>
          <button type="button" className="primary login-button" onClick={goToLogin}>
            Volver a iniciar sesión
          </button>
        </div>
      ) : (
        <form className="login-form" onSubmit={handleSubmit} noValidate>
          <div className="mobile-logo"><Logo /></div>
          <h2>Restablecé tu contraseña</h2>
          <p>Ingresá el email de tu cuenta. Te vamos a enviar un enlace para elegir una nueva contraseña.</p>
          <label>
            Email
            <input
              type="email"
              autoComplete="email"
              placeholder="nombre@ejemplo.com"
              value={email}
              onChange={(event) => {
                onEmailChange(event.target.value)
                if (error) setError('')
              }}
              disabled={submitting}
              aria-invalid={Boolean(error)}
            />
          </label>
          {error && <p className="login-error" role="alert">{error}</p>}
          <button type="submit" className="primary login-button" disabled={submitting} aria-busy={submitting}>
            {submitting ? <LoaderCircle size={18} className="spin" /> : null}
            {submitting ? 'Enviando…' : 'Enviar enlace'}
            {submitting ? null : <ArrowRight size={18} />}
          </button>
          <p className="login-switch">
            <button type="button" onClick={goToLogin} disabled={submitting}>Volver a iniciar sesión</button>
          </p>
        </form>
      )}
    </AuthLayout>
  )
}
