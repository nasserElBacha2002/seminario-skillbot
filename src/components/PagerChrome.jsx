import { ArrowRight, BookOpen } from 'lucide-react'

export function PagerChrome({
  page,
  total,
  progress,
  onExit,
  onBack,
  backDisabled,
  onPrimary,
  primaryLabel,
  primaryDisabled,
  secondaryAction,
  children,
}) {
  return (
    <>
      <header className="ficha-pager-top">
        <button type="button" className="ficha-pager-exit" onClick={onExit}>
          ← Salir
        </button>
        <p className="ficha-pager-count">
          <BookOpen size={14} aria-hidden />
          {page + 1} de {total}
        </p>
      </header>

      <div
        className="ficha-pager-progress"
        role="progressbar"
        aria-valuenow={progress}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={`Progreso: ${progress}%`}
      >
        <span className="ficha-pager-progress-fill" style={{ width: `${progress}%` }} />
      </div>

      <div className="ficha-pager-body">{children}</div>

      <footer className="ficha-pager-foot">
        <button
          type="button"
          className="ficha-pager-back"
          disabled={backDisabled}
          onClick={onBack}
        >
          Atrás
        </button>
        <div className="ficha-pager-actions">
          {secondaryAction}
          <button
            type="button"
            className="primary ficha-pager-continue"
            disabled={primaryDisabled}
            onClick={onPrimary}
          >
            {primaryLabel}
            <ArrowRight size={18} />
          </button>
        </div>
      </footer>
    </>
  )
}