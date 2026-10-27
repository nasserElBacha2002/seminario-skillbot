import { ArrowRight, MessagesSquare, Search } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { caseOfTheDay } from '../lib/daily'
import { Layout } from '../components/Layout'
import { UseCaseCard } from '../components/UseCaseCard'
import { caseIcon } from '../components/icons'

// Casos empezados y sin terminar, el último que se tocó primero.
function startedCases(useCases, progress) {
  return useCases
    .filter((item) => {
      const entry = progress[item.id]
      return entry && entry.status !== 'completed' && entry.progress < 100
    })
    .sort((a, b) => String(progress[b.id].updated_at ?? '').localeCompare(String(progress[a.id].updated_at ?? '')))
}

export function HomePage({ setPage, openCase }) {
  const { data } = useSkillbotData()
  const daily = caseOfTheDay(data.useCases)
  const DailyIcon = daily ? caseIcon(daily) : null
  const started = startedCases(data.useCases, data.progress)
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

        <button type="button" className="help-banner" onClick={() => setPage('ayuda')}>
          <span><MessagesSquare size={20} /></span>
          <div>
            <b>¿Conocés el nuevo centro de ayuda?</b>
            <small>Preguntá tus dudas y ayudá a otros usuarios con las suyas.</small>
          </div>
          <em>Ir al centro de ayuda <ArrowRight size={15} /></em>
        </button>

        <div className="section-heading">
          <div>
            <h2>Seguí donde quedaste</h2>
            <p>{started.length ? 'Los casos que empezaste y todavía no terminaste.' : 'Todavía no empezaste ningún caso.'}</p>
          </div>
          <button type="button" className="text-button" onClick={() => setPage('explorar')}>
            Ver todos los casos <ArrowRight size={14} />
          </button>
        </div>
        {started.length > 0 ? (
          <div className="use-cases-grid">
            {started.map((item) => <UseCaseCard key={item.id} item={item} onOpen={(id) => openCase(id, 'inicio')} />)}
          </div>
        ) : (
          <div className="home-empty">
            <p>Empezá por el caso de hoy o buscá uno parecido a lo que necesitás.</p>
            <button type="button" className="secondary" onClick={() => setPage('explorar')}>
              <Search size={15} /> Explorar casos
            </button>
          </div>
        )}

        <p className="home-side">
          <span>{data.completedCount} prácticas completadas · {data.profile.xp} XP</span>
          <button type="button" className="text-button" onClick={() => setPage('progreso')}>Ver progreso</button>
        </p>
      </section>
    </Layout>
  )
}
