import { useState } from 'react'
import { ChevronRight, KeyRound, LoaderCircle, LogOut, Mail, Pencil } from 'lucide-react'
import { Layout } from '../components/Layout'
import { useAuth } from '../context/Auth'
import { useSkillbotData } from '../context/SkillbotData'

const MIN_PASSWORD = 8

function passwordMessage(error) {
  const code = String(error?.code ?? '')
  const status = error?.status
  const text = String(error?.message ?? '').toLowerCase()
  if (code === 'same_password' || text.includes('different from the old password') || text.includes('should be different')) {
    return 'La nueva contraseña tiene que ser distinta a la anterior.'
  }
  if (code === 'weak_password' || (text.includes('password') && (text.includes('least') || text.includes('short') || text.includes('weak')))) {
    return `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`
  }
  if (error?.name === 'AuthRetryableFetchError' || text.includes('failed to fetch') || text.includes('network')) {
    return 'No pudimos actualizar la contraseña. Intentá nuevamente.'
  }
  return 'No pudimos actualizar la contraseña. Intentá nuevamente.'
}

function NameForm({ currentName, onCancel, onSaved }) {
  const { saveDisplayName } = useSkillbotData()
  const [name, setName] = useState(currentName)
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    const nextName = name.trim()
    if (!nextName) {
      setError('Ingresá tu nombre.')
      return
    }
    setError('')
    setSubmitting(true)
    try {
      await saveDisplayName(nextName)
      onSaved()
    } catch {
      setError('No pudimos guardar el nombre. Intentá nuevamente.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form className="account-form" onSubmit={handleSubmit} noValidate>
      <label>
        Nombre
        <input
          type="text"
          autoComplete="name"
          value={name}
          onChange={(event) => {
            setName(event.target.value)
            if (error) setError('')
          }}
          disabled={submitting}
          aria-invalid={Boolean(error)}
        />
      </label>
      {error && <p className="save-error" role="alert">{error}</p>}
      <button type="submit" className="primary" disabled={submitting} aria-busy={submitting}>
        {submitting ? <LoaderCircle size={17} className="spin" /> : null}
        {submitting ? 'Guardando…' : 'Guardar nombre'}
      </button>
      <button type="button" className="account-back" onClick={onCancel} disabled={submitting}>Volver</button>
    </form>
  )
}

function PasswordForm({ onCancel }) {
  const { updatePassword } = useAuth()
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    if (password.length < MIN_PASSWORD) {
      setError(`La contraseña debe tener al menos ${MIN_PASSWORD} caracteres.`)
      return
    }
    if (!confirmPassword || password !== confirmPassword) {
      setError('Las contraseñas no coinciden.')
      return
    }
    setError('')
    setSuccess(false)
    setSubmitting(true)
    try {
      await updatePassword(password)
      setPassword('')
      setConfirmPassword('')
      setSuccess(true)
    } catch (updateError) {
      setError(passwordMessage(updateError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form className="account-form" onSubmit={handleSubmit} noValidate>
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
            if (success) setSuccess(false)
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
            if (success) setSuccess(false)
          }}
          disabled={submitting}
          aria-invalid={Boolean(error)}
        />
      </label>
      {error && <p className="save-error" role="alert">{error}</p>}
      {success && <p className="save-ok" role="status">Contraseña actualizada.</p>}
      <button type="submit" className="primary" disabled={submitting} aria-busy={submitting}>
        {submitting ? <LoaderCircle size={17} className="spin" /> : null}
        {submitting ? 'Guardando…' : 'Guardar contraseña'}
      </button>
      <button type="button" className="account-back" onClick={onCancel} disabled={submitting}>Volver</button>
    </form>
  )
}

export function ProfilePage({ setPage }) {
  const { data } = useSkillbotData()
  const { user, signOut } = useAuth()
  const [panel, setPanel] = useState('menu')
  const [error, setError] = useState('')
  const [leaving, setLeaving] = useState(false)

  async function handleLogout() {
    setError('')
    setLeaving(true)
    try {
      await signOut()
    } catch {
      setError('No pudimos cerrar la sesión. Intentá nuevamente.')
      setLeaving(false)
    }
  }

  return (
    <Layout page="perfil" setPage={setPage}>
      <section className="page profile-page">
        <div className="profile-main refined">
          <span className="profile-avatar">{data.profile.initials}</span>
          <div className="profile-title">
            <p className="eyebrow">TU PERFIL</p>
            <h1>{data.profile.name}</h1>
            <p><span /> {data.level.name} · {data.profile.xp} XP</p>
          </div>
        </div>
        <div className="profile-grid">
          <article>
            <p className="eyebrow">SOBRE VOS</p>
            <h2>Tu objetivo</h2>
            <p>{data.profile.goal}</p>
            <h2 className="interests-title">Tus intereses</h2>
            <div className="interest-list">{data.profile.interests.map((item) => <span key={item}>{item}</span>)}</div>
          </article>
          <article className="settings-list">
            {panel === 'name' ? (
              <>
                <p className="eyebrow">EDITAR NOMBRE</p>
                <NameForm currentName={data.profile.name} onCancel={() => setPanel('menu')} onSaved={() => setPanel('menu')} />
              </>
            ) : panel === 'password' ? (
              <>
                <p className="eyebrow">CAMBIAR CONTRASEÑA</p>
                <PasswordForm onCancel={() => setPanel('menu')} />
              </>
            ) : (
              <>
                <p className="eyebrow">CUENTA</p>
                <div className="account-row">
                  <span><Mail size={18} /></span>
                  <div>
                    <b>{user?.email || 'Sin email'}</b>
                    <small>Email de la cuenta</small>
                  </div>
                </div>
                <button type="button" onClick={() => setPanel('name')}>
                  <span><Pencil size={18} /></span>
                  <div>
                    <b>Editar nombre</b>
                    <small>Se usa en tu perfil y en las iniciales</small>
                  </div>
                  <ChevronRight size={18} />
                </button>
                <button type="button" onClick={() => setPanel('password')}>
                  <span><KeyRound size={18} /></span>
                  <div>
                    <b>Cambiar contraseña</b>
                    <small>Actualizá el acceso de esta cuenta</small>
                  </div>
                  <ChevronRight size={18} />
                </button>
                <button type="button" className="logout" onClick={handleLogout} disabled={leaving}>
                  <span><LogOut size={18} /></span>
                  <div>
                    <b>{leaving ? 'Cerrando sesión…' : 'Cerrar sesión'}</b>
                    <small>Volver a la pantalla de ingreso</small>
                  </div>
                  <ChevronRight size={18} />
                </button>
                {error && <p className="save-error" role="alert">{error}</p>}
              </>
            )}
          </article>
        </div>
      </section>
    </Layout>
  )
}
