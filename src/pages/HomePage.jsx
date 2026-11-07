import { ArrowRight, MessagesSquare, Search } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { caseOfTheDay } from '../lib/daily'
import { BUSINESS_AREAS, primaryReason, recommendationText } from '../lib/matching'
import { Layout } from '../components/Layout'
import { UseCaseCard } from '../components/UseCaseCard'
import { caseIcon } from '../components/icons'

function startedCases(useCases, progress) {
  return useCases
    .filter((item) => {
      const entry = progress[item.id]
      return entry && entry.status !== 'completed' && entry.progress < 100
    })
    .sort((a, b) => String(progress[b.id].updated_at ?? '').localeCompare(String(progress[a.id].updated_at ?? '')))
}

function completedCases(useCases, progress) {
  return useCases.filter((item) => progress[item.id]?.status === 'completed' || progress[item.id]?.progress >= 100)
}

export function HomePage({ setPage, openCase, onExplore }) {
  const { data, recommendations, personalized } = useSkillbotData()
  const byId = new Map(data.useCases.map((item) => [item.id, item]))
  const recommended = personalized
    ? recommendations.filter((item) => item.score > 0).slice(0, 6)
    : []
  const daily = caseOfTheDay(data.useCases)
  const DailyIcon = daily ? caseIcon(daily) : null
  const started = startedCases(data.useCases, data.progress)
  const completed = completedCases(data.useCases, data.progress)
  const options = data.onboarding?.options

  return (
    <Layout page="inicio" setPage={setPage}>
      <section className="page home-page">
        <div className="hero-copy">
          <h1>{personalized ? 'Encontrá soluciones con IA para tu emprendimiento' : '¿Qué querés resolver?'}</h1>
          <p>
            {personalized
              ? 'El orden sale de las dificultades, el objetivo y las áreas que marcaste. Un caso de otra área puede aparecer primero si resuelve mejor lo que necesitás.'
              : 'Elegí un problema de Marketing, Finanzas o Administración y practicá cómo resolverlo con IA.'}
          </p>
        </div>

        {!data.useCases.length && (
          <p className="home-empty">El catálogo todavía no tiene casos publicados.</p>
        )}

        {!personalized && data.useCases.length > 0 && (
          <div className="home-invite">
            <p>Todavía no armamos un ranking: faltan tus respuestas. El catálogo completo sigue disponible.</p>
            <button type="button" className="secondary" onClick={() => setPage('perfil')}>Completar cuestionario</button>
          </div>
        )}

        {personalized && (
          <>
            <div className="section-heading">
              <div>
                <h2>Recomendado para vos</h2>
                <p>Los seis casos que mejor coinciden con lo que marcaste.</p>
              </div>
            </div>
            {recommended.length > 0 ? (
              <div className="use-cases-grid">
                {recommended.map((entry) => {
                  const item = byId.get(entry.id)
                  if (!item) return null
                  return (
                    <UseCaseCard
                      key={entry.id}
                      item={item}
                      reason={recommendationText(primaryReason(entry), options)}
                      onOpen={(id) => openCase(id, 'inicio')}
                    />
                  )
                })}
              </div>
            ) : (
              <p className="home-empty">No encontramos coincidencias con esas respuestas. Podés recorrer el catálogo completo.</p>
            )}
          </>
        )}

        <div className="section-heading">
          <div>
            <h2>Áreas del negocio</h2>
            <p>Marketing, Finanzas y Administración quedan abiertas, aunque no las hayas elegido.</p>
          </div>
        </div>
        <div className="area-board">
          {BUSINESS_AREAS.map((area) => (
            <button key={area.id} type="button" onClick={() => onExplore(area.id)}>
              <b>{area.label}</b>
              <small>Ver casos de esta área</small>
            </button>
          ))}
        </div>

        <div className="section-heading">
          <div>
            <h2>Seguí donde quedaste</h2>
            <p>{started.length ? 'Los casos que empezaste y todavía no terminaste.' : 'Todavía no empezaste ningún caso.'}</p>
          </div>
          <button type="button" className="text-button" onClick={() => onExplore('todos')}>
            Ver todos los casos <ArrowRight size={14} />
          </button>
        </div>
        {started.length > 0 ? (
          <div className="use-cases-grid">
            {started.map((item) => <UseCaseCard key={item.id} item={item} onOpen={(id) => openCase(id, 'inicio')} />)}
          </div>
        ) : (
          <div className="home-empty">
            <p>{daily ? 'Empezá por el caso de hoy o buscá uno parecido a lo que necesitás.' : 'Buscá un caso parecido a lo que necesitás.'}</p>
            <button type="button" className="secondary" onClick={() => onExplore('todos')}>
              <Search size={15} /> Explorar casos
            </button>
          </div>
        )}

        {completed.length > 0 && (
          <>
            <div className="section-heading">
              <div>
                <h2>Completados</h2>
                <p>{completed.length === 1 ? 'Ya terminaste 1 caso.' : `Ya terminaste ${completed.length} casos.`} Podés abrirlos para repasar.</p>
              </div>
            </div>
            <div className="use-cases-grid">
              {completed.map((item) => <UseCaseCard key={item.id} item={item} onOpen={(id) => openCase(id, 'inicio')} />)}
            </div>
          </>
        )}

        {daily ? (
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
        ) : (
          <p className="home-empty">Hoy no hay una práctica disponible.</p>
        )}

        <button type="button" className="help-banner" onClick={() => setPage('ayuda')}>
          <span><MessagesSquare size={20} /></span>
          <div>
            <b>¿Conocés el nuevo centro de ayuda?</b>
            <small>Preguntá tus dudas y ayudá a otros usuarios con las suyas.</small>
          </div>
          <em>Ir al centro de ayuda <ArrowRight size={15} /></em>
        </button>

        <p className="home-side">
          <span>{data.completedCount} {data.completedCount === 1 ? 'práctica completada' : 'prácticas completadas'} · {data.profile.xp} XP</span>
          <button type="button" className="text-button" onClick={() => setPage('progreso')}>Ver progreso</button>
        </p>
      </section>
    </Layout>
  )
}
