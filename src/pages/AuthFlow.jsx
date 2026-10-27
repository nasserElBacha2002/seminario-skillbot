import { useState } from 'react'
import { useAuth } from '../context/Auth'
import { ForgotPassword } from './ForgotPassword'
import { Login } from './Login'
import { Register } from './Register'
import { UpdatePassword } from './UpdatePassword'

export function AuthFlow() {
  const { passwordRecovery } = useAuth()
  const [view, setView] = useState('login')
  const [email, setEmail] = useState('')

  if (passwordRecovery) {
    return <UpdatePassword />
  }

  if (view === 'register') {
    return (
      <Register
        email={email}
        onEmailChange={setEmail}
        onLogin={() => setView('login')}
      />
    )
  }

  if (view === 'forgot') {
    return (
      <ForgotPassword
        email={email}
        onEmailChange={setEmail}
        onLogin={() => setView('login')}
      />
    )
  }

  return (
    <Login
      email={email}
      onEmailChange={setEmail}
      onRegister={() => setView('register')}
      onForgot={() => setView('forgot')}
    />
  )
}
