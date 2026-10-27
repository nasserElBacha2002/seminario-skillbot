import { useState } from 'react'
import { useAuth } from '../context/Auth'
import { ForgotPassword } from './ForgotPassword'
import { Login } from './Login'
import { Register } from './Register'
import { UpdatePassword } from './UpdatePassword'

export function AuthFlow() {
  const { passwordRecovery, clearAuthNotice } = useAuth()
  const [view, setView] = useState('login')
  const [email, setEmail] = useState('')

  function showLogin() {
    clearAuthNotice()
    setView('login')
  }

  function showRegister() {
    clearAuthNotice()
    setView('register')
  }

  if (passwordRecovery) {
    return <UpdatePassword />
  }

  if (view === 'register') {
    return (
      <Register
        email={email}
        onEmailChange={setEmail}
        onLogin={showLogin}
      />
    )
  }

  if (view === 'forgot') {
    return (
      <ForgotPassword
        email={email}
        onEmailChange={setEmail}
        onLogin={showLogin}
      />
    )
  }

  return (
    <Login
      email={email}
      onEmailChange={setEmail}
      onRegister={showRegister}
      onForgot={() => setView('forgot')}
    />
  )
}
