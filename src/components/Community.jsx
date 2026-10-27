import { useEffect, useState } from 'react'
import { CircleCheck, LoaderCircle, MessageCircle, Send } from 'lucide-react'
import { createHelpReply, createHelpTopic, fetchHelpReplies, markHelpSolution } from '../lib/queries'

const relative = new Intl.RelativeTimeFormat('es', { numeric: 'auto' })
const UNITS = [['year', 31536000], ['month', 2592000], ['week', 604800], ['day', 86400], ['hour', 3600], ['minute', 60]]

export function timeAgo(value) {
  const seconds = (new Date(value).getTime() - Date.now()) / 1000
  for (const [unit, size] of UNITS) {
    if (Math.abs(seconds) >= size) return relative.format(Math.round(seconds / size), unit)
  }
  return 'recién'
}

function Author({ name, initials, date }) {
  return (
    <div className="topic-author">
      <span>{initials || '?'}</span>
      <b>{name || 'Alguien'}</b>
      <small>{timeAgo(date)}</small>
    </div>
  )
}

export function TopicCard({ topic, useCase, onOpen }) {
  return (
    <button type="button" className="topic-card" onClick={() => onOpen(topic.id)}>
      <div className="topic-card-head">
        <h3>{topic.title}</h3>
        {topic.solved_reply_id && <em className="topic-solved"><CircleCheck size={13} /> Resuelta</em>}
      </div>
      <p>{topic.body}</p>
      <div className="topic-meta">
        <Author name={topic.author_name} initials={topic.author_initials} date={topic.created_at} />
        {useCase && <span className="topic-case">{useCase.title}</span>}
        <span className="topic-count"><MessageCircle size={14} /> {topic.replyCount}</span>
      </div>
    </button>
  )
}

export function TopicForm({ useCases, initialCaseId, onCreated, onCancel }) {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [useCaseId, setUseCaseId] = useState(initialCaseId ?? '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const submit = async (event) => {
    event.preventDefault()
    if (title.trim().length < 5) return setError('El título tiene que tener al menos 5 caracteres.')
    if (!body.trim()) return setError('Contá un poco más tu duda.')
    setSaving(true)
    setError('')
    try {
      onCreated(await createHelpTopic({ title, body, useCaseId }))
    } catch (err) {
      setError(err.message || 'No pudimos publicar la pregunta.')
      setSaving(false)
    }
  }

  return (
    <form className="topic-form" onSubmit={submit}>
      <h2>Nueva pregunta</h2>
      <label htmlFor="topic-title">Título</label>
      <input
        id="topic-title"
        value={title}
        maxLength={140}
        onChange={(event) => setTitle(event.target.value)}
        placeholder="Ej.: ChatGPT me inventa datos al resumir un PDF"
      />
      <label htmlFor="topic-body">Tu duda</label>
      <textarea
        id="topic-body"
        rows={5}
        value={body}
        maxLength={4000}
        onChange={(event) => setBody(event.target.value)}
        placeholder="Qué intentaste, qué herramienta usaste y qué te respondió."
      />
      <label htmlFor="topic-case">Caso relacionado <span className="field-optional">(opcional)</span></label>
      <select id="topic-case" value={useCaseId} onChange={(event) => setUseCaseId(event.target.value)}>
        <option value="">Ninguno</option>
        {useCases.map((item) => <option key={item.id} value={item.id}>{item.title}</option>)}
      </select>
      <p className="field-help">No compartas contraseñas, datos bancarios ni información de otras personas.</p>
      {error && <p className="form-error" role="alert">{error}</p>}
      <div className="topic-form-actions">
        <button type="button" className="secondary" onClick={onCancel}>Cancelar</button>
        <button type="submit" className="primary" disabled={saving}>
          {saving ? <LoaderCircle size={16} className="spin" /> : <Send size={16} />} Publicar
        </button>
      </div>
    </form>
  )
}

export function TopicDetail({ topic, useCase, onBack, onChange, openCase }) {
  const [replies, setReplies] = useState(null)
  const [loadError, setLoadError] = useState('')
  const [body, setBody] = useState('')
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    fetchHelpReplies(topic.id)
      .then((rows) => active && setReplies(rows))
      .catch((err) => active && setLoadError(err.message))
    return () => { active = false }
  }, [topic.id])

  const reply = async (event) => {
    event.preventDefault()
    if (!body.trim()) return
    setSending(true)
    setError('')
    try {
      const created = await createHelpReply(topic.id, body)
      setReplies((list) => [...(list ?? []), created])
      setBody('')
      onChange({ ...topic, replyCount: topic.replyCount + 1, last_activity_at: created.created_at })
    } catch (err) {
      setError(err.message || 'No pudimos publicar la respuesta.')
    } finally {
      setSending(false)
    }
  }

  const toggleSolution = async (replyId) => {
    const next = topic.solved_reply_id === replyId ? null : replyId
    try {
      await markHelpSolution(topic.id, next)
      onChange({ ...topic, solved_reply_id: next })
    } catch (err) {
      setError(err.message || 'No pudimos marcar la solución.')
    }
  }

  // La solución va primero; el resto sigue en orden de llegada.
  const ordered = replies
    ? [...replies].sort((a, b) => (b.id === topic.solved_reply_id) - (a.id === topic.solved_reply_id))
    : []

  return (
    <div className="topic-detail">
      <button type="button" className="back" onClick={onBack}>← Volver a la comunidad</button>
      <article className="topic-main">
        <div className="topic-card-head">
          <h1>{topic.title}</h1>
          {topic.solved_reply_id && <em className="topic-solved"><CircleCheck size={13} /> Resuelta</em>}
        </div>
        <Author name={topic.author_name} initials={topic.author_initials} date={topic.created_at} />
        <p className="topic-body">{topic.body}</p>
        {useCase && (
          <button type="button" className="topic-case" onClick={() => openCase(useCase.id)}>
            Caso: {useCase.title} →
          </button>
        )}
      </article>

      <h2 className="help-section-title">
        {topic.replyCount} {topic.replyCount === 1 ? 'respuesta' : 'respuestas'}
      </h2>
      {loadError && <p className="form-error">{loadError}</p>}
      {!replies && !loadError && <p className="help-empty"><LoaderCircle size={15} className="spin" /> Cargando respuestas…</p>}
      {replies && !replies.length && <p className="help-empty">Todavía nadie respondió. ¿Sabés cómo resolverlo?</p>}
      <div className="reply-list">
        {ordered.map((item) => {
          const solved = item.id === topic.solved_reply_id
          return (
            <article key={item.id} className={solved ? 'reply solved' : 'reply'}>
              {solved && <em className="topic-solved"><CircleCheck size={13} /> Solución</em>}
              <Author name={item.author_name} initials={item.author_initials} date={item.created_at} />
              <p>{item.body}</p>
              {topic.mine && (
                <button type="button" className="reply-mark" onClick={() => toggleSolution(item.id)}>
                  {solved ? 'Quitar solución' : 'Marcar como solución'}
                </button>
              )}
            </article>
          )
        })}
      </div>

      <form className="reply-form" onSubmit={reply}>
        <label htmlFor="reply-body">Tu respuesta</label>
        <textarea
          id="reply-body"
          rows={4}
          value={body}
          maxLength={4000}
          onChange={(event) => setBody(event.target.value)}
          placeholder="Contá qué te funcionó, o sumá otra idea al debate."
        />
        {error && <p className="form-error" role="alert">{error}</p>}
        <button type="submit" className="primary" disabled={sending || !body.trim()}>
          {sending ? <LoaderCircle size={16} className="spin" /> : <Send size={16} />} Responder
        </button>
      </form>
    </div>
  )
}
