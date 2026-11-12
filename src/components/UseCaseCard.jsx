import { ArrowRight } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { isPracticeReady } from '../lib/practice'
import { caseIcon } from './icons'
import { ProgressBar } from './Layout'

export function UseCaseCard({ item, onOpen, reason = '' }) {
  const { data } = useSkillbotData()
  const Icon = caseIcon(item)
  const entry = data.progress[item.id]
  const progress = entry?.progress ?? 0
  const completed = entry?.status === 'completed' || progress === 100
  const started = !completed && (progress > 0 || entry?.status === 'in_progress')
  const ready = isPracticeReady(item)
  const label = completed ? 'Abrir' : ready ? 'Practicar' : 'Ver ficha'
  return (
    <article className="use-case-card">
      <div className="use-case-top">
        <span className={`tool-icon ${item.color}`}><Icon size={18} /></span>
        {item.areaName && <span className="case-category">{item.areaName}</span>}
      </div>
      <h3>
        <button type="button" className="card-hit" onClick={() => onOpen(item.id)}>
          {item.title}
          <span className="sr-only">. {label}</span>
        </button>
      </h3>
      <p>{item.description}</p>
      <div className="case-meta">
        <span>{item.estimatedTime} · {item.difficulty}</span>
        {completed && <span className="done-mark">✓ Completado</span>}
        {started && <span className="practice-mark">En práctica</span>}
        {!completed && !started && <span>{ready ? 'Práctica' : 'Ficha'}</span>}
      </div>
      {reason && <p className="card-reason">{reason}</p>}
      {started && (
        <div className="card-progress">
          <ProgressBar value={progress} />
        </div>
      )}
      <span className="card-action">{label} <ArrowRight size={15} /></span>
    </article>
  )
}
