import { ArrowRight } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { caseIcon } from './icons'
import { ProgressBar } from './Layout'

export function UseCaseCard({ item, onOpen }) {
  const { data } = useSkillbotData()
  const Icon = caseIcon(item)
  const entry = data.progress[item.id]
  const progress = entry?.progress ?? 0
  const completed = entry?.status === 'completed' || progress === 100
  const started = !completed && (progress > 0 || entry?.status === 'in_progress')
  const label = completed ? 'Abrir' : 'Practicar'
  return (
    <article className="use-case-card">
      <div className="use-case-top">
        <span className={`tool-icon ${item.color}`}><Icon size={18} /></span>
        <span className="case-category">{item.category}</span>
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
        {!completed && !started && <span>Nuevo</span>}
      </div>
      {started && (
        <div className="card-progress">
          <ProgressBar value={progress} />
        </div>
      )}
      <span className="card-action">{label} <ArrowRight size={15} /></span>
    </article>
  )
}
