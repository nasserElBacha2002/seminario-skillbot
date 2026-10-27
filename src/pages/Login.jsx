import { useState } from 'react'
import { ArrowRight, LoaderCircle } from 'lucide-react'
import { AuthLayout } from '../components/AuthLayout'
import { GoogleButton } from '../components/GoogleButton'
import { Logo } from '../components/Layout'
import { useAuth } from '../context/Auth'

function loginMessage(error) {
  const code = String(error?.code ?? '')
  const status = error?.status
  const text = String(error?.message ?? '').toLowerCase()
  if (
    status === 400
    || code === 'invalid_credentials'
    || text.includes('invalid login')
    || text.includes('invalid credentials')
    || text.includes('email not confirmed')
  ) {
    return 'Email o contraseña incorrectos.'
  }
  return 'No pudimos iniciar sesión. Intentá nuevamente.'
}

export function Login({ email, onEmailChange, onRegister, onForgot }) {
  const { signIn, authNotice, clearAuthNotice } = useAuth()
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const displayError = error || authNotice

  async function handleSubmit(event) {
    event.preventDefault()
    clearAuthNotice()
    const nextEmail = email.trim()
    if (!nextEmail || !password) {
      setError('Completá el email y la contraseña.')
      return
    }
    setError('')
    setSubmitting(true)
    try {
      await signIn(nextEmail, password)
    } catch (signInError) {
      setError(loginMessage(signInError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AuthLayout>
      <form className="login-form" onSubmit={handleSubmit} noValidate>
        <div className="mobile-logo"><Logo /></div>
        <h2>Iniciá sesión</h2>
        <p>Entrá con tu email y contraseña para continuar.</p>
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
            autoComplete="current-password"
            placeholder="••••••••"
            value={password}
            onChange={(event) => {
              setPassword(event.target.value)
              if (error) setError('')
            }}
            disabled={submitting}
            aria-invalid={Boolean(error)}
          />
        </label>
        <button
          type="button"
          className="login-forgot"
          disabled={submitting}
          onClick={() => {
            setPassword('')
            setError('')
            onForgot()
          }}
        >
          Olvidé mi contraseña
        </button>
        {displayError && <p className="login-error" role="alert">{displayError}</p>}
        <button type="submit" className="primary login-button" disabled={submitting} aria-busy={submitting}>
          {submitting ? <LoaderCircle size={18} className="spin" /> : null}
          {submitting ? 'Entrando…' : 'Entrar'}
          {submitting ? null : <ArrowRight size={18} />}
        </button>
        <div className="login-divider" role="separator">o</div>
        <GoogleButton disabled={submitting} onError={setError} />
        <p className="login-switch">
          ¿No tenés cuenta?{' '}
          <button
            type="button"
            onClick={() => {
              setPassword('')
              setError('')
              onRegister()
            }}
          >
            Crear cuenta
          </button>
        </p>
      </form>
    </AuthLayout>
  )
}
