import { useState } from 'react'
import { ExternalLink } from 'lucide-react'
import { copyText } from '../lib/clipboard'

function arrangeTools(tools) {
  const usable = tools.filter((tool) => tool.url)
  const primaries = usable.filter((tool) => tool.role === 'primary')
  const recommended = primaries[0] || usable[0] || null
  return { recommended, others: usable.filter((tool) => tool !== recommended) }
}

export function CaseResult({ text, tools, xpNote, saveError, onEdit, onBack }) {
  const [notice, setNotice] = useState('')
  const [copied, setCopied] = useState(false)
  const { recommended, others } = arrangeTools(tools)

  async function copy() {
    const ok = await copyText(text)
    setCopied(ok)
    setNotice(ok ? 'Copiado. Pegalo en la herramienta que abras.' : 'No pudimos copiarlo automáticamente. Copialo manualmente antes de continuar.')
  }

  async function openTool(tool) {
    const pending = copyText(text)
    window.open(tool.url, '_blank', 'noopener,noreferrer')
    const ok = await pending
    setCopied(ok)
    setNotice(ok
      ? `Pedido copiado. Pegalo en ${tool.name} para continuar.`
      : 'No pudimos copiarlo automáticamente. Copialo manualmente antes de continuar.')
  }

  return (
    <div className="case-result">
      <h2>Tu pedido está listo</h2>
      <p className="result-lead">Armamos este pedido con los datos que completaste.</p>
      <pre className="result-text">{text}</pre>
      <div className="case-actions">
        <button type="button" className="primary" onClick={copy}>
          {copied && notice.startsWith('Copiado') ? 'Copiado' : 'Copiar pedido'}
        </button>
      </div>
      {recommended && (
        <section className="recommended-pick">
          <p className="rec-kicker">Herramienta recomendada</p>
          <h3>{recommended.name}</h3>
          {recommended.reason && <p>{recommended.reason}</p>}
          <button type="button" className="primary" onClick={() => openTool(recommended)}>
            Abrir en {recommended.name} <ExternalLink size={15} />
          </button>
        </section>
      )}
      {others.length > 0 && (
        <p className="tool-extra">
          <span>Otras opciones</span>
          {others.map((tool, index) => (
            <span key={tool.id}>
              {index > 0 && ' · '}
              <button type="button" onClick={() => openTool(tool)}>{tool.name}</button>
            </span>
          ))}
        </p>
      )}
      <div className="result-links">
        <button type="button" className="text-button" onClick={onEdit}>Editar respuestas</button>
        <button type="button" className="text-button" onClick={onBack}>Volver al caso</button>
      </div>
      <p className="copy-feedback" role="status">{notice}</p>
      {xpNote && <p className="result-note">{xpNote}</p>}
      {saveError && (
        <p className="save-error">
          El pedido quedó en este dispositivo, pero no se pudo guardar el progreso: {saveError.message}
          {/resolve_use_case|PGRST202/i.test(String(saveError.message ?? '')) && ' Falta aplicar la migración 20261020223000_resolve_use_case.sql.'}
        </p>
      )}
    </div>
  )
}
