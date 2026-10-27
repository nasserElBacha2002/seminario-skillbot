import { useState } from 'react'
import { ChevronRight, LogOut } from 'lucide-react'
import { Layout } from '../components/Layout'
import { useAuth } from '../context/Auth'
import { useSkillbotData } from '../context/SkillbotData'

export function ProfilePage({ setPage }) {
  const { data } = useSkillbotData()
  const { signOut } = useAuth()
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
            <p className="eyebrow">CUENTA</p>
            <button type="button" className="logout" onClick={handleLogout} disabled={leaving}>
              <span><LogOut size={18} /></span>
              <div>
                <b>{leaving ? 'Cerrando sesión…' : 'Cerrar sesión'}</b>
                <small>Volver a la pantalla de ingreso</small>
              </div>
              <ChevronRight size={18} />
            </button>
            {error && <p className="save-error" role="alert">{error}</p>}
          </article>
        </div>
      </section>
    </Layout>
  )
}
