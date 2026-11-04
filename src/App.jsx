import { useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './context/Auth'
import { SkillbotDataProvider, useSkillbotData } from './context/SkillbotData'
import { Boot, BootError } from './components/Boot'
import { OnboardingWizard } from './components/OnboardingWizard'
import { canPostponeOnboarding } from './lib/onboarding'
import { loadOnboardingLater, rememberCase, saveOnboardingLater } from './lib/storage'
import { ExplorePage } from './pages/ExplorePage'
import { HelpPage } from './pages/HelpPage'
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
  return <ProfilePage setPage={setPage} />
}

function Entry() {
  const { user } = useAuth()
  const { data, loading, error, reload, saveOnboarding } = useSkillbotData()
  const [later, setLater] = useState(() => loadOnboardingLater(user?.id))

  useEffect(() => {
    setLater(loadOnboardingLater(user?.id))
  }, [user?.id])

  if (loading || !data) return <Boot />
  if (error) return <BootError error={error} onRetry={reload} />
  if (data.onboarding?.completedAt || later) return <Shell />

  const allowLater = canPostponeOnboarding({
    profile: data.profile,
    progress: data.progress,
    activityDays: data.activityDays,
    achievements: data.achievements,
  })

  return (
    <OnboardingWizard
      key={user?.id}
      mode="start"
      options={data.onboarding?.options}
      serverAnswers={data.onboarding?.answers}
      allowLater={allowLater}
      onSubmit={saveOnboarding}
      onLater={() => {
        saveOnboardingLater(user?.id)
        setLater(true)
      }}
    />
  )
}

function Gate() {
  const { session, passwordRecovery, loading, error, reload } = useAuth()
  if (loading) return <Boot />
  if (error && !session) return <BootError error={error} onRetry={reload} />
  if (passwordRecovery || !session) return <AuthFlow />
  return (
    <SkillbotDataProvider>
      <Entry />
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
