import { useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './context/Auth'
import { SkillbotDataProvider, useSkillbotData } from './context/SkillbotData'
import { Boot, BootError } from './components/Boot'
import { rememberCase } from './lib/storage'
import { ExplorePage } from './pages/ExplorePage'
import { HomePage } from './pages/HomePage'
import { AuthFlow } from './pages/AuthFlow'
import { ProfilePage } from './pages/ProfilePage'
import { ProgressPage } from './pages/ProgressPage'
import { UseCasePage } from './pages/UseCasePage'

function Shell() {
  const { data, loading, error, reload } = useSkillbotData()
  const [page, setPage] = useState('inicio')
  const [caseId, setCaseId] = useState(null)
  const [origin, setOrigin] = useState('inicio')

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
  const useCase = data.useCases.find((item) => item.id === caseId)
  if ((page === 'detalle' || page === 'desafio') && !useCase) {
    return <ExplorePage setPage={setPage} openCase={openCase} />
  }

  if (page === 'inicio') return <HomePage setPage={setPage} openCase={openCase} />
  if (page === 'explorar') return <ExplorePage setPage={setPage} openCase={openCase} />
  if (page === 'detalle' || page === 'desafio') return <UseCasePage setPage={setPage} useCase={useCase} origin={origin} />
  if (page === 'progreso') return <ProgressPage setPage={setPage} />
  return <ProfilePage setPage={setPage} />
}

function Gate() {
  const { session, loading, error, reload } = useAuth()
  if (loading) return <Boot />
  if (error && !session) return <BootError error={error} onRetry={reload} />
  if (!session) return <AuthFlow />
  return (
    <SkillbotDataProvider>
      <Shell />
    </SkillbotDataProvider>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <Gate />
    </AuthProvider>
  )
}
