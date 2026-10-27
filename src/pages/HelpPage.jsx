import { useCallback, useEffect, useState } from 'react'
import { LoaderCircle, Plus, RotateCcw, TriangleAlert } from 'lucide-react'
import { TopicCard, TopicDetail, TopicForm } from '../components/Community'
import { HelpFaq } from '../components/HelpFaq'
import { Layout } from '../components/Layout'
import { SearchBar } from '../components/SearchBar'
import { useSkillbotData } from '../context/SkillbotData'
import { fetchHelpTopics } from '../lib/queries'
import { normalize, significantTokens } from '../lib/search'

const filters = [
  ['todas', 'Todas'],
  ['sin-respuesta', 'Sin respuesta'],
  ['resueltas', 'Resueltas'],
  ['mias', 'Mis preguntas'],
]

function passesFilter(topic, filter) {
  if (filter === 'sin-respuesta') return topic.replyCount === 0
  if (filter === 'resueltas') return Boolean(topic.solved_reply_id)
  if (filter === 'mias') return topic.mine
  return true
}

function matches(query, topic) {
  const tokens = significantTokens(query)
  if (!tokens.length) return true
  const haystack = normalize(`${topic.title} ${topic.body}`)
  return tokens.every((token) => haystack.includes(token))
}

// Sin la migración, PostgREST no encuentra la tabla.
function isMissingTable(error) {
  return error?.code === 'PGRST205' || error?.code === '42P01'
}

export function HelpPage({ setPage, openCase, askCaseId, clearAsk }) {
  const { data } = useSkillbotData()
  const [tab, setTab] = useState('comunidad')
  const [topics, setTopics] = useState(null)
  const [error, setError] = useState(null)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState('todas')
  const [openId, setOpenId] = useState(null)
  const [composing, setComposing] = useState(Boolean(askCaseId))

  const load = useCallback(() => {
    setError(null)
    fetchHelpTopics().then(setTopics).catch(setError)
  }, [])
  useEffect(load, [load])

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [openId, composing])

  const caseById = (id) => data.useCases.find((item) => item.id === id)
  const updateTopic = (next) => setTopics((list) => list.map((item) => (item.id === next.id ? { ...item, ...next } : item)))
  const closeForm = () => { setComposing(false); clearAsk() }
  const open = topics?.find((item) => item.id === openId)

  if (open) {
    return (
      <Layout page="ayuda" setPage={setPage}>
        <section className="page help-page">
          <TopicDetail
            topic={open}
            useCase={caseById(open.use_case_id)}
            onBack={() => setOpenId(null)}
            onChange={updateTopic}
            openCase={(id) => openCase(id, 'ayuda')}
          />
        </section>
      </Layout>
    )
  }

  const visible = (topics ?? []).filter((topic) => passesFilter(topic, filter) && matches(query, topic))

  return (
    <Layout page="ayuda" setPage={setPage}>
      <section className="page help-page">
        <div className="page-intro help-intro">
          <div>
            <p className="eyebrow">CENTRO DE AYUDA</p>
            <h1>Preguntá, respondé y aprendé con otros</h1>
            <p>Si te trabaste con una tarea o con una IA, abrí una pregunta. Cualquiera puede responder.</p>
          </div>
          {tab === 'comunidad' && !composing && !error && (
            <button type="button" className="primary" onClick={() => setComposing(true)}>
              <Plus size={16} /> Nueva pregunta
            </button>
          )}
        </div>

        <div className="help-tabs" role="tablist">
          {[['comunidad', 'Comunidad'], ['faq', 'Preguntas frecuentes']].map(([id, label]) => (
            <button key={id} type="button" role="tab" aria-selected={tab === id} className={tab === id ? 'active' : ''} onClick={() => setTab(id)}>
              {label}
            </button>
          ))}
        </div>

        {tab === 'faq' && <HelpFaq />}

        {tab === 'comunidad' && composing && (
          <TopicForm
            useCases={data.useCases}
            initialCaseId={askCaseId}
            onCancel={closeForm}
            onCreated={(topic) => {
              setTopics((list) => [topic, ...(list ?? [])])
              closeForm()
              setOpenId(topic.id)
            }}
          />
        )}

        {tab === 'comunidad' && !composing && error && (
          <div className="boot-error help-error">
            <span><TriangleAlert size={24} /></span>
            <h2>No pudimos cargar la comunidad</h2>
            <p>{isMissingTable(error)
              ? 'Falta aplicar la migración 20261027200000_help_community.sql en Supabase.'
              : error.message}</p>
            <button type="button" className="primary" onClick={load}><RotateCcw size={16} /> Reintentar</button>
          </div>
        )}

        {tab === 'comunidad' && !composing && !error && (
          <>
            <SearchBar id="help-search" value={query} onChange={setQuery} label="Buscar en la comunidad" placeholder="Buscá si alguien ya preguntó lo mismo..." />
            <div className="help-filters">
              {filters.map(([id, label]) => (
                <button key={id} type="button" className={filter === id ? 'active' : ''} aria-pressed={filter === id} onClick={() => setFilter(id)}>
                  {label}
                </button>
              ))}
            </div>
            {!topics && <p className="help-empty"><LoaderCircle size={15} className="spin" /> Cargando preguntas…</p>}
            {topics && !visible.length && (
              <p className="help-empty">
                {topics.length ? 'No hay preguntas que coincidan.' : 'Todavía no hay preguntas. ¡Abrí la primera!'}
              </p>
            )}
            <div className="topic-list">
              {visible.map((topic) => (
                <TopicCard key={topic.id} topic={topic} useCase={caseById(topic.use_case_id)} onOpen={setOpenId} />
              ))}
            </div>
          </>
        )}
      </section>
    </Layout>
  )
}
