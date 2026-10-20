import { ArrowRight } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'
import { caseIcon } from './icons'
import { ProgressBar } from './Layout'

export function UseCaseCard({ item, onOpen }) {
  const { data } = useSkillbotData()
  const Icon = caseIcon(item)
  const progress = data.progress[item.id]?.progress ?? 0
  const partial = progress > 0 && progress < 100
  return (
    <article className="use-case-card">
      <div className="use-case-top">
        <span className={`tool-icon ${item.color}`}><Icon size={18} /></span>
        <span className="case-category">{item.category}</span>
      </div>
      <h3>
        <button type="button" className="card-hit" onClick={() => onOpen(item.id)}>
          {item.title}
          <span className="sr-only">. Abrir</span>
        </button>
      </h3>
      <p>{item.description}</p>
      <div className="case-meta">
        <span>{item.estimatedTime} · {item.difficulty}</span>
        {progress === 100 && <span className="done-mark">✓ Resuelto</span>}
      </div>
      {partial && (
        <div className="card-progress">
          <ProgressBar value={progress} />
          <b>{progress}%</b>
        </div>
      )}
      <span className="card-action">Abrir <ArrowRight size={15} /></span>
    </article>
  )
}
