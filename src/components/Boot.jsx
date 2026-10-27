import { LoaderCircle, RotateCcw, TriangleAlert } from 'lucide-react'
import { Logo } from './Layout'

export function Boot() {
  return (
    <div className="boot">
      <Logo />
      <p><LoaderCircle size={17} className="spin" /> Cargando…</p>
    </div>
  )
}

export function BootError({ error, onRetry }) {
  const message = String(error?.message ?? '')
  const missingSchema = /use_case_fields|output_template|schema cache/i.test(message)
  return (
    <div className="boot">
      <Logo />
      <div className="boot-error">
        <span><TriangleAlert size={26} /></span>
        <h2>No pudimos conectarnos a la base</h2>
        <p>{message}</p>
        {missingSchema && (
          <p>Falta aplicar la migración 20261020210000_guided_resolution.sql y volver a correr supabase/seed.sql.</p>
        )}
        <button type="button" className="primary" onClick={onRetry}><RotateCcw size={16} /> Reintentar</button>
      </div>
    </div>
  )
}
