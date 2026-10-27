import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { setStorageOwner } from '../lib/storage'

const AuthContext = createContext(null)

const OAUTH_ERROR_KEYS = ['error', 'error_code', 'error_description', 'error_uri']

function readSearchAndHash() {
  const url = new URL(window.location.href)
  return {
    url,
    search: url.searchParams,
    hash: new URLSearchParams(url.hash.replace(/^#/, '')),
  }
}

function oauthCallbackMessage() {
  const { search, hash } = readSearchAndHash()
  const error = search.get('error') || hash.get('error')
  if (!error) return ''
  const code = String(search.get('error_code') || hash.get('error_code') || error).toLowerCase()
  if (code.includes('access_denied')) return 'Cancelaste el acceso con Google.'
  return 'No pudimos completar el acceso con Google. Intentá nuevamente.'
}

function authCallbackStillNeeded(search, hash) {
  const type = search.get('type') || hash.get('type')
  return Boolean(
    search.get('code')
    || hash.get('code')
    || search.get('access_token')
    || hash.get('access_token')
    || search.get('refresh_token')
    || hash.get('refresh_token')
    || search.get('token_hash')
    || hash.get('token_hash')
    || type === 'recovery'
    || type === 'signup'
    || type === 'magiclink'
  )
}

function clearConsumedOAuthErrorParams() {
  const { url, search, hash } = readSearchAndHash()
  if (!(search.get('error') || hash.get('error'))) return
  if (authCallbackStillNeeded(search, hash)) return

  let changed = false
  for (const key of OAUTH_ERROR_KEYS) {
    if (search.has(key)) {
      search.delete(key)
      changed = true
    }
    if (hash.has(key)) {
      hash.delete(key)
      changed = true
    }
  }
  if (!changed) return

  const nextSearch = search.toString()
  const nextHash = hash.toString()
  const next = `${url.pathname}${nextSearch ? `?${nextSearch}` : ''}${nextHash ? `#${nextHash}` : ''}`
  window.history.replaceState(window.history.state, '', next)
}

function isOAuthCallbackFailure(error) {
  const name = String(error?.name ?? '')
  const code = String(error?.code ?? '').toLowerCase()
  return name === 'AuthImplicitGrantRedirectError' || code.includes('access_denied')
}

export function canChangePassword(user) {
  const identities = Array.isArray(user?.identities) ? user.identities : []
  if (identities.length > 0) {
    return identities.some((item) => String(item.provider).toLowerCase() === 'email')
  }
  const providers = user?.app_metadata?.providers
  if (Array.isArray(providers) && providers.length > 0) {
    return providers.map((item) => String(item).toLowerCase()).includes('email')
  }
  const provider = String(user?.app_metadata?.provider ?? '').toLowerCase()
  if (provider) return provider === 'email'
  return true
}

export function isReauthenticationError(error) {
  const code = String(error?.code ?? '').toLowerCase()
  const text = String(error?.message ?? '').toLowerCase()
  return (
    code === 'reauthentication_needed'
    || code === 'insufficient_aal'
    || text.includes('reauthentication')
    || text.includes('re-authenticate')
    || text.includes('reauthenticate')
    || text.includes('recent login')
    || text.includes('recent authentication')
  )
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [passwordRecovery, setPasswordRecovery] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [authNotice, setAuthNotice] = useState('')

  useEffect(() => {
    let cancelled = false
    let leaveBoot
    const notice = oauthCallbackMessage()
    if (notice) setAuthNotice(notice)

    supabase.auth.getSession()
      .then(({ data, error: sessionError }) => {
        if (cancelled) return
        if (sessionError) {
          setSession(null)
          setStorageOwner(null)
          if (isOAuthCallbackFailure(sessionError)) {
            setError(null)
            setAuthNotice((current) => current || 'No pudimos completar el acceso con Google. Intentá nuevamente.')
          } else {
            setError(sessionError)
          }
          setLoading(false)
          return
        }
        setError(null)
        setSession(data.session)
        setStorageOwner(data.session?.user?.id ?? null)
      })
      .catch((sessionError) => {
        if (cancelled) return
        setSession(null)
        setStorageOwner(null)
        if (isOAuthCallbackFailure(sessionError)) {
          setError(null)
          setAuthNotice((current) => current || 'No pudimos completar el acceso con Google. Intentá nuevamente.')
        } else {
          setError(sessionError)
        }
        setLoading(false)
      })
      .finally(() => {
        if (cancelled || !notice) return
        clearConsumedOAuthErrorParams()
      })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (cancelled) return
      if (event === 'PASSWORD_RECOVERY') setPasswordRecovery(true)
      if (event === 'SIGNED_OUT') setPasswordRecovery(false)
      if (event === 'SIGNED_IN') setAuthNotice('')
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

  const signInWithGoogle = useCallback(async () => {
    const { data, error: oauthError } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
      },
    })
    if (oauthError) throw oauthError
    return data
  }, [])

  const completePasswordRecovery = useCallback(() => {
    setPasswordRecovery(false)
  }, [])

  const clearAuthNotice = useCallback(() => {
    setAuthNotice('')
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
      authNotice,
      clearAuthNotice,
      signIn,
      signUp,
      signInWithGoogle,
      signOut,
      resetPasswordForEmail,
      updatePassword,
      completePasswordRecovery,
      reload,
    }),
    [session, passwordRecovery, loading, error, authNotice, clearAuthNotice, signIn, signUp, signInWithGoogle, signOut, resetPasswordForEmail, updatePassword, completePasswordRecovery, reload],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth tiene que usarse dentro de AuthProvider')
  return context
}
