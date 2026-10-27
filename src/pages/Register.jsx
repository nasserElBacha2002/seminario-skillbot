import { useState } from 'react'
import { ArrowRight, LoaderCircle } from 'lucide-react'
import { AuthLayout } from '../components/AuthLayout'
import { GoogleButton } from '../components/GoogleButton'
import { Logo } from '../components/Layout'
import { useAuth } from '../context/Auth'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const MIN_PASSWORD = 8

function signUpMessage(error) {
  const code = String(error?.code ?? '')
  const status = error?.status
  const text = String(error?.message ?? '').toLowerCase()
  if (code === 'user_already_exists' || text.includes('already registered') || text.includes('already been registered')) {
    return 'Ya existe una cuenta asociada a este email.'
  }
  if (code === 'over_email_send_rate_limit' || status === 429 || text.includes('rate limit') || text.includes('too many requests')) {
    return 'Demasiados intentos. Esperá un momento e intentá nuevamente.'
  }
  if (code === 'weak_password' || (text.includes('password') && (text.includes('least') || text.includes('short') || text.includes('weak')))) {
    return `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`
  }
  if (code === 'invalid_email' || text.includes('unable to validate email') || text.includes('invalid email')) {
    return 'Ingresá un email válido.'
  }
  if (code === 'signup_disabled' || text.includes('signups not allowed') || text.includes('sign up is disabled')) {
    return 'El registro no está habilitado. Pedile a quien administra el proyecto que active Email signup.'
  }
  if (error?.name === 'AuthRetryableFetchError' || text.includes('failed to fetch') || text.includes('network')) {
    return 'No pudimos crear la cuenta. Intentá nuevamente.'
  }
  return 'No pudimos crear la cuenta. Intentá nuevamente.'
}

function validate({ name, email, password, confirmPassword }) {
  if (!name) return 'Ingresá tu nombre.'
  if (!email || !EMAIL_PATTERN.test(email)) return 'Ingresá un email válido.'
  if (password.length < MIN_PASSWORD) return `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`
  if (!confirmPassword || password !== confirmPassword) return 'Las contraseñas no coinciden.'
  return ''
}

export function Register({ email, onEmailChange, onLogin }) {
  const { signUp, authNotice } = useAuth()
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const displayError = error || authNotice
  const [submitting, setSubmitting] = useState(false)
  const [needsConfirm, setNeedsConfirm] = useState(false)

  function goToLogin() {
    setPassword('')
    setConfirmPassword('')
    setError('')
    setNeedsConfirm(false)
    onLogin()
  }

  async function handleSubmit(event) {
    event.preventDefault()
    const nextName = name.trim()
    const nextEmail = email.trim()
    const localError = validate({
      name: nextName,
      email: nextEmail,
      password,
      confirmPassword,
    })
    if (localError) {
      setError(localError)
      return
    }
    setError('')
    setSubmitting(true)
    try {
      const data = await signUp({
        email: nextEmail,
        password,
        displayName: nextName,
      })
      setPassword('')
      setConfirmPassword('')
      if (data.session) return
      if (!data.user) {
        setError('No pudimos crear la cuenta. Intentá nuevamente.')
        return
      }
      setNeedsConfirm(true)
    } catch (signUpError) {
      setError(signUpMessage(signUpError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AuthLayout>
      {needsConfirm ? (
        <div className="login-form">
          <div className="mobile-logo"><Logo /></div>
          <h2>Revisá tu correo</h2>
          <p>Te enviamos un correo para confirmar tu cuenta. Después de confirmarla vas a poder iniciar sesión.</p>
          <button type="button" className="primary login-button" onClick={goToLogin}>
            Volver a iniciar sesión
          </button>
        </div>
      ) : (
        <form className="login-form" onSubmit={handleSubmit} noValidate>
          <div className="mobile-logo"><Logo /></div>
          <h2>Creá tu cuenta</h2>
          <p>Registrate con tu nombre, email y una contraseña.</p>
          <label>
            Nombre
            <input
              type="text"
              autoComplete="name"
              placeholder="Tu nombre"
              value={name}
              onChange={(event) => {
                setName(event.target.value)
                if (error) setError('')
              }}
              disabled={submitting}
              aria-invalid={Boolean(error)}
            />
          </label>
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
          <label>
            Contraseña
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
          {displayError && <p className="login-error" role="alert">{displayError}</p>}
          <button type="submit" className="primary login-button" disabled={submitting} aria-busy={submitting}>
            {submitting ? <LoaderCircle size={18} className="spin" /> : null}
            {submitting ? 'Creando cuenta…' : 'Crear cuenta'}
            {submitting ? null : <ArrowRight size={18} />}
          </button>
          <div className="login-divider" role="separator">o</div>
          <GoogleButton disabled={submitting} onError={setError} />
          <p className="login-switch">
            ¿Ya tenés cuenta?{' '}
            <button type="button" onClick={goToLogin}>Iniciar sesión</button>
          </p>
        </form>
      )}
    </AuthLayout>
  )
}
