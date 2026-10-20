import { useSkillbotData } from '../context/SkillbotData'
import { recentCaseId } from '../lib/storage'
import { CaseBrowser } from '../components/CaseBrowser'
import { Layout } from '../components/Layout'

export function HomePage({ setPage, openCase }) {
  const { data } = useSkillbotData()
  const recent = data.useCases.find((item) => item.id === recentCaseId())
  return (
    <Layout page="inicio" setPage={setPage}>
      <section className="page home-page">
        <div className="hero-copy">
          <h1>¿Qué querés resolver?</h1>
          <p>Elegí una situación, practicá cómo resolverla con IA y aprendé a detectar errores antes de usar el resultado.</p>
        </div>
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
