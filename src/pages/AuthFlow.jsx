import { useState } from 'react'
import { Login } from './Login'
import { Register } from './Register'

export function AuthFlow() {
  const [view, setView] = useState('login')
  const [email, setEmail] = useState('')

  if (view === 'register') {
    return (
      <Register
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
    />
  )
}
