import { Check, Flame, Lock, Medal, Search, Sparkles, Trophy } from 'lucide-react'
import { Layout, ProgressBar } from '../components/Layout'
import { useSkillbotData } from '../context/SkillbotData'

const achievementIcons = { Trophy, Flame, Search, Medal }

function Stat({ icon: Icon, label, value, color }) {
  return (
    <div className="stat">
      <span className={`stat-icon ${color}`}><Icon size={19} /></span>
      <div><b>{value}</b><small>{label}</small></div>
    </div>
  )
}

export function ProgressPage({ setPage }) {
  const { data } = useSkillbotData()
  return (
    <Layout page="progreso" setPage={setPage}>
      <section className="page progress-page">
        <div className="page-intro">
          <p className="eyebrow">TU RECORRIDO</p>
          <h1>Tu progreso</h1>
          <p>Cada caso resuelto queda registrado acá. La tarea se resuelve en el caso, no en esta pantalla.</p>
        </div>
        <div className="progress-overview">
          <div className="level-card">
            <span className="level-icon"><Medal size={27} /></span>
            <div>
              <p className="eyebrow">NIVEL ACTUAL</p>
              <h2>{data.level.name}</h2>
              <p>Sigue desde el problema que tengas ahora.</p>
            </div>
            <div className="level-xp">
              <b>{data.profile.xp} <small>XP</small></b>
              <ProgressBar value={data.levelProgress} />
              <span>{data.level.next_xp ? `Próximo nivel: ${data.level.next_xp} XP` : 'Alcanzaste el nivel máximo'}</span>
            </div>
          </div>
          <div className="mini-stat-grid">
            <Stat icon={Check} color="green" value={data.completedCount} label="Casos resueltos" />
            <Stat icon={Sparkles} color="violet" value={data.practicedSkills} label="Habilidades practicadas" />
            <Stat icon={Flame} color="orange" value={`${data.streak} ${data.streak === 1 ? 'día' : 'días'}`} label="Racha actual" />
          </div>
        </div>
        <section className="section-heading">
          <div>
            <h2>Progreso por habilidad</h2>
            <p>Así crecen tus habilidades con cada práctica.</p>
          </div>
        </section>
        <article className="skill-panel">
          {data.skills.map((skill) => (
            <div className="skill" key={skill.id}>
              <div><b>{skill.name}</b><span>{skill.value}%</span></div>
              <ProgressBar value={skill.value} color={skill.color} />
            </div>
          ))}
        </article>
        <section className="section-heading">
          <div>
            <h2>Tus logros</h2>
            <p>Pequeños hitos, grandes avances.</p>
          </div>
        </section>
        <div className="achievements">
          {data.achievements.map((item) => {
            const Icon = item.unlocked ? achievementIcons[item.icon] ?? Trophy : Lock
            return (
              <article key={item.id} className={`achievement ${item.unlocked ? '' : 'locked'}`}>
                <span><Icon size={21} /></span>
                <div><b>{item.title}</b><small>{item.description}</small></div>
                {item.unlocked && <Check size={17} />}
              </article>
            )
          })}
        </div>
      </section>
    </Layout>
  )
}
