import { useEffect, useState } from 'react'
import { SkillbotDataProvider, useSkillbotData } from './context/SkillbotData'
import { Boot, BootError } from './components/Boot'
import { rememberCase } from './lib/storage'
import { ExplorePage } from './pages/ExplorePage'
import { HelpPage } from './pages/HelpPage'
import { HomePage } from './pages/HomePage'
import { Login } from './pages/Login'
import { ProfilePage } from './pages/ProfilePage'
import { ProgressPage } from './pages/ProgressPage'
import { UseCasePage } from './pages/UseCasePage'

function Shell({ onLogout }) {
  const { data, loading, error, reload } = useSkillbotData()
  const [page, setPage] = useState('inicio')
  const [caseId, setCaseId] = useState(null)
  const [origin, setOrigin] = useState('inicio')
  const [askCaseId, setAskCaseId] = useState(null)

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [page, caseId])

  if (loading) return <Boot />
  if (error) return <BootError error={error} onRetry={reload} />

  const openCase = (id, from = 'inicio') => {
    rememberCase(id)
    setCaseId(id)
    setOrigin(from)
    setPage('detalle')
  }
  const askCommunity = (id) => {
    setAskCaseId(id)
    setPage('ayuda')
  }
  const useCase = data.useCases.find((item) => item.id === caseId)
  if ((page === 'detalle' || page === 'desafio') && !useCase) {
    return <ExplorePage setPage={setPage} openCase={openCase} />
  }

  if (page === 'inicio') return <HomePage setPage={setPage} openCase={openCase} />
  if (page === 'explorar') return <ExplorePage setPage={setPage} openCase={openCase} />
  if (page === 'detalle' || page === 'desafio') return <UseCasePage setPage={setPage} useCase={useCase} origin={origin} onAsk={askCommunity} />
  if (page === 'progreso') return <ProgressPage setPage={setPage} />
  if (page === 'ayuda') {
    return <HelpPage setPage={setPage} openCase={openCase} askCaseId={askCaseId} clearAsk={() => setAskCaseId(null)} />
  }
  return <ProfilePage setPage={setPage} onLogout={onLogout} />
}

export default function App() {
  const [logged, setLogged] = useState(() => localStorage.getItem('skillbot-demo') === 'yes')
  useEffect(() => {
    if (logged) localStorage.setItem('skillbot-demo', 'yes')
  }, [logged])
  if (!logged) return <Login onLogin={() => setLogged(true)} />
  return (
    <SkillbotDataProvider>
      <Shell onLogout={() => { localStorage.removeItem('skillbot-demo'); setLogged(false) }} />
    </SkillbotDataProvider>
  )
}
