import { ArrowRight } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { caseOfTheDay } from '../lib/daily'
import { recentCaseId } from '../lib/storage'
import { CaseBrowser } from '../components/CaseBrowser'
import { Layout } from '../components/Layout'
import { caseIcon } from '../components/icons'

export function HomePage({ setPage, openCase }) {
  const { data } = useSkillbotData()
  const recent = data.useCases.find((item) => item.id === recentCaseId())
  const daily = caseOfTheDay(data.useCases)
  const DailyIcon = daily ? caseIcon(daily) : null
  return (
    <Layout page="inicio" setPage={setPage}>
      <section className="page home-page">
        <div className="hero-copy">
          <h1>¿Qué querés resolver?</h1>
          <p>Elegí una situación, practicá cómo resolverla con IA y aprendé a detectar errores antes de usar el resultado.</p>
        </div>
        {daily && (
          <article className="daily-card">
            <span className={`daily-icon tool-icon ${daily.color}`}>{DailyIcon && <DailyIcon size={22} />}</span>
            <div className="daily-copy">
              <p className="case-kicker">Caso de hoy</p>
              <h2>{daily.title}</h2>
              <p>{daily.description}</p>
            </div>
            <button type="button" className="primary" onClick={() => openCase(daily.id, 'inicio')}>
              Practicar hoy <ArrowRight size={16} />
            </button>
          </article>
        )}
        <CaseBrowser searchId="home-search" onOpen={(id) => openCase(id, 'inicio')} />
        {recent && (
          <button type="button" className="continue-mini" onClick={() => openCase(recent.id, 'inicio')}>
            <span>Seguir con</span>
            <b>{recent.title}</b>
          </button>
        )}
        <p className="home-side">
          <span>{data.completedCount} prácticas completadas · {data.profile.xp} XP</span>
          <button type="button" className="text-button" onClick={() => setPage('progreso')}>Ver progreso</button>
        </p>
      </section>
    </Layout>
  )
}
