import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { setStorageOwner } from '../lib/storage'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [passwordRecovery, setPasswordRecovery] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let cancelled = false
    let leaveBoot

    supabase.auth.getSession()
      .then(({ data, error: sessionError }) => {
        if (cancelled) return
        if (sessionError) {
          setError(sessionError)
          setSession(null)
          setStorageOwner(null)
          setLoading(false)
          return
        }
        setError(null)
        setSession(data.session)
        setStorageOwner(data.session?.user?.id ?? null)
      })
      .catch((sessionError) => {
        if (cancelled) return
        setError(sessionError)
        setSession(null)
        setStorageOwner(null)
        setLoading(false)
      })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (cancelled) return
      if (event === 'PASSWORD_RECOVERY') setPasswordRecovery(true)
      if (event === 'SIGNED_OUT') setPasswordRecovery(false)
      setSession(nextSession)
      setStorageOwner(nextSession?.user?.id ?? null)
      setError(null)
      // PASSWORD_RECOVERY se emite en un setTimeout(0) aparte de INITIAL_SESSION.
      // Dejar Boot un tick evita un flash de Home al volver del mail.
      if (event === 'INITIAL_SESSION') {
        leaveBoot = window.setTimeout(() => {
          if (!cancelled) setLoading(false)
        }, 0)
      } else {
        setLoading(false)
      }
    })

    return () => {
      cancelled = true
      if (leaveBoot) window.clearTimeout(leaveBoot)
      subscription.unsubscribe()
    }
  }, [])

  const signIn = useCallback(async (email, password) => {
    const { data, error: signInError } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    })
    if (signInError) throw signInError
    return data
  }, [])

  const signUp = useCallback(async ({ email, password, displayName }) => {
    const { data, error: signUpError } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: {
        data: {
          display_name: displayName.trim(),
        },
      },
    })
    if (signUpError) throw signUpError
    return data
  }, [])

  const signOut = useCallback(async () => {
    const { error: signOutError } = await supabase.auth.signOut()
    if (signOutError) throw signOutError
  }, [])

  const resetPasswordForEmail = useCallback(async (email) => {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: window.location.origin,
    })
    if (resetError) throw resetError
  }, [])

  const updatePassword = useCallback(async (password) => {
    const { data, error: updateError } = await supabase.auth.updateUser({ password })
    if (updateError) throw updateError
    return data
  }, [])

  const completePasswordRecovery = useCallback(() => {
    setPasswordRecovery(false)
  }, [])

  const reload = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const { data, error: sessionError } = await supabase.auth.getSession()
      if (sessionError) {
        setError(sessionError)
        setSession(null)
        setStorageOwner(null)
        return
      }
      setSession(data.session)
      setStorageOwner(data.session?.user?.id ?? null)
    } catch (sessionError) {
      setError(sessionError)
      setSession(null)
      setStorageOwner(null)
    } finally {
      setLoading(false)
    }
  }, [])

  const value = useMemo(
    () => ({
      session,
      user: session?.user ?? null,
      passwordRecovery,
      loading,
      error,
      signIn,
      signUp,
      signOut,
      resetPasswordForEmail,
      updatePassword,
      completePasswordRecovery,
      reload,
    }),
    [session, passwordRecovery, loading, error, signIn, signUp, signOut, resetPasswordForEmail, updatePassword, completePasswordRecovery, reload],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth tiene que usarse dentro de AuthProvider')
  return context
}
