import { useEffect, useState } from 'react'
import { caseIcon } from '../components/icons'
import { CaseResult } from '../components/CaseResult'
import { CaseSteps } from '../components/CaseSteps'
import { DynamicCaseForm } from '../components/DynamicCaseForm'
import { Layout } from '../components/Layout'
import { useSkillbotData } from '../context/SkillbotData'
import { fillTemplate, unresolvedPlaceholders } from '../lib/template'
import { loadDraft, loadResult, rememberCase, saveResult } from '../lib/storage'

function hasContent(values) {
  return Object.values(values ?? {}).some((value) => String(value).trim())
}

export function UseCasePage({ setPage, useCase, origin }) {
  const { markResolved } = useSkillbotData()
  const Icon = caseIcon(useCase)
  const [stage, setStage] = useState('intro')
  const [resultText, setResultText] = useState(() => loadResult(useCase.id)?.text ?? '')
  const [xpNote, setXpNote] = useState('')
  const [saveError, setSaveError] = useState(null)
  const [templateError, setTemplateError] = useState('')
  const ready = useCase.fields.length > 0 && Boolean(useCase.outputTemplate)

  useEffect(() => {
    rememberCase(useCase.id)
    setStage('intro')
    setResultText(loadResult(useCase.id)?.text ?? '')
    setXpNote('')
    setSaveError(null)
    setTemplateError('')
  }, [useCase.id])

  async function generate(nextValues) {
    const optionalKeys = useCase.fields.filter((field) => !field.required).map((field) => field.key)
    const text = fillTemplate(useCase.outputTemplate, nextValues, optionalKeys).trim()
    if (!text || unresolvedPlaceholders(text).length) {
      setTemplateError('No se pudo armar el pedido con estos datos.')
      return
    }
    setResultText(text)
    saveResult(useCase.id, text, nextValues)
    setStage('result')
    setTemplateError('')
    setSaveError(null)
    try {
      const xp = await markResolved(useCase)
      setXpNote(xp > 0 ? `Sumaste ${xp} XP.` : '')
    } catch (error) {
      setSaveError(error)
    }
  }

  return (
    <Layout page="detalle" setPage={setPage}>
      <section className="page case-flow">
        <button type="button" className="back" onClick={() => setPage(origin || 'inicio')}>← Volver</button>
        <div className={`case-heading${stage === 'intro' ? '' : ' case-heading-compact'}${stage === 'result' ? ' case-heading-result' : ''}`}>
          <span className={`hero-tool-icon tool-icon ${useCase.color}`}><Icon size={28} /></span>
          <div>
            <p className="case-kicker">{useCase.category}</p>
            <h1>{useCase.title}</h1>
            <p>{useCase.description}</p>
            <p className="case-facts">{useCase.estimatedTime} · Dificultad {String(useCase.difficulty).toLocaleLowerCase('es')}</p>
            <p className="case-outcome">Te llevás un pedido listo para usar.</p>
          </div>
        </div>

        {stage === 'intro' && (
          <>
            <article className="example-box">
              <p className="case-kicker">Por ejemplo</p>
              <p>{useCase.situation}</p>
            </article>
            {ready ? (
              <div className="case-actions">
                <button type="button" className="primary" onClick={() => setStage('form')}>
                  {hasContent(loadDraft(useCase.id)) ? 'Continuar con tus datos' : 'Armar mi solución'}
                </button>
                {resultText && (
                  <button type="button" className="secondary" onClick={() => setStage('result')}>Ver el pedido anterior</button>
                )}
              </div>
            ) : (
              <p className="save-error">Este caso todavía no tiene una solución guiada.</p>
            )}
          </>
        )}

        {stage === 'form' && (
          <>
            <h2 className="flow-title">Contanos tu caso</h2>
            <p className="flow-lead">Con estos datos armamos el pedido. La herramienta aparece al final.</p>
            {templateError && <p className="save-error" role="alert">{templateError}</p>}
            <DynamicCaseForm
              key={`${useCase.id}-${stage}`}
              useCase={useCase}
              initialValues={loadDraft(useCase.id)}
              submitLabel="Armar mi pedido"
              onSubmit={generate}
              onCancel={() => setStage('intro')}
            />
          </>
        )}

        {stage === 'result' && (
          <CaseResult
            text={resultText}
            tools={useCase.tools}
            xpNote={xpNote}
            saveError={saveError}
            onEdit={() => setStage('form')}
            onBack={() => setStage('intro')}
          />
        )}

        {stage === 'result' && useCase.steps.length > 0 && (
          <details className="help-panel">
            <summary>Cómo usar esta solución</summary>
            <p className="help-note">{useCase.learning}</p>
            <p className="help-note">{useCase.mistake}</p>
            <CaseSteps useCase={useCase} />
          </details>
        )}

        {stage === 'result' && useCase.challenge && (
          <div className="optional-practice">
            <button type="button" className="text-button" onClick={() => setPage('desafio')}>Practicar lo aprendido</button>
            <p>Opcional. No hace falta para obtener el pedido.</p>
          </div>
        )}
      </section>
    </Layout>
  )
}
