import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { setStorageOwner } from '../lib/storage'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let cancelled = false

    supabase.auth.getSession()
      .then(({ data, error: sessionError }) => {
        if (cancelled) return
        if (sessionError) {
          setError(sessionError)
          setSession(null)
          setStorageOwner(null)
        } else {
          setError(null)
          setSession(data.session)
          setStorageOwner(data.session?.user?.id ?? null)
        }
        setLoading(false)
      })
      .catch((sessionError) => {
        if (cancelled) return
        setError(sessionError)
        setSession(null)
        setStorageOwner(null)
        setLoading(false)
      })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (cancelled) return
      setSession(nextSession)
      setStorageOwner(nextSession?.user?.id ?? null)
      setError(null)
      setLoading(false)
    })

    return () => {
      cancelled = true
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
      loading,
      error,
      signIn,
      signUp,
      signOut,
      reload,
    }),
    [session, loading, error, signIn, signUp, signOut, reload],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth tiene que usarse dentro de AuthProvider')
  return context
}
