import { useCallback, useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './context/Auth'
import { SkillbotDataProvider, useSkillbotData } from './context/SkillbotData'
import { Boot, BootError } from './components/Boot'
import { OnboardingWizard } from './components/OnboardingWizard'
import { canPostponeOnboarding, mustCompleteOnboarding } from './lib/onboarding'
import { parsePath, pathForRoute } from './lib/routes'
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
  const [route, setRoute] = useState(() => parsePath(window.location.pathname, window.location.search))
  const { page, caseId, origin, area: areaFilter, askCaseId } = route

  const applyRoute = useCallback((next) => {
    setRoute({
      page: next.page,
      caseId: next.caseId ?? null,
      origin: next.origin ?? 'inicio',
      area: next.area ?? 'todos',
      askCaseId: next.askCaseId ?? null,
    })
  }, [])

  const go = useCallback((patch, { replace = false } = {}) => {
    const next = {
      page: patch.page ?? route.page,
      caseId: patch.caseId !== undefined ? patch.caseId : route.caseId,
      origin: patch.origin !== undefined ? patch.origin : route.origin,
      area: patch.area !== undefined ? patch.area : route.area,
      askCaseId: patch.askCaseId !== undefined ? patch.askCaseId : route.askCaseId,
    }
    if (next.page !== 'detalle' && next.page !== 'desafio') next.caseId = null
    if (next.page !== 'ayuda') next.askCaseId = null
    const url = pathForRoute(next)
    if (replace) window.history.replaceState(next, '', url)
    else window.history.pushState(next, '', url)
    applyRoute(next)
  }, [applyRoute, route])

  const setPage = useCallback((nextPage) => {
    go({ page: nextPage, caseId: null, askCaseId: null, origin: 'inicio' })
  }, [go])

  useEffect(() => {
    const onPop = () => {
      applyRoute(parsePath(window.location.pathname, window.location.search))
    }
    window.addEventListener('popstate', onPop)
    return () => window.removeEventListener('popstate', onPop)
  }, [applyRoute])

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [page, caseId])

  if (loading) return <Boot />
  if (error) return <BootError error={error} onRetry={reload} />

  const openCase = (id, from = 'inicio') => {
    rememberCase(id)
    go({ page: 'detalle', caseId: id, origin: from })
  }
  const askCommunity = (id) => {
    go({ page: 'ayuda', askCaseId: id })
  }
  const openExplore = (area = 'todos') => {
    go({ page: 'explorar', area, caseId: null })
  }
  const onAreaChange = (area) => {
    go({ page: 'explorar', area, caseId: null }, { replace: true })
  }
  const clearAsk = () => go({ page: 'ayuda', askCaseId: null }, { replace: true })

  const useCase = data.useCases.find((item) => item.id === caseId)
  if ((page === 'detalle' || page === 'desafio') && !useCase) {
    return <ExplorePage setPage={setPage} openCase={openCase} area={areaFilter} onAreaChange={onAreaChange} />
  }

  if (page === 'inicio') return <HomePage setPage={setPage} openCase={openCase} onExplore={openExplore} />
  if (page === 'explorar') {
    return <ExplorePage setPage={setPage} openCase={openCase} area={areaFilter} onAreaChange={onAreaChange} />
  }
  if (page === 'detalle' || page === 'desafio') {
    return <UseCasePage setPage={setPage} useCase={useCase} origin={origin} onAsk={askCommunity} />
  }
  if (page === 'progreso') return <ProgressPage setPage={setPage} />
  if (page === 'ayuda') {
    return (
      <HelpPage
        setPage={setPage}
        openCase={openCase}
        askCaseId={askCaseId}
        clearAsk={clearAsk}
      />
    )
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

  if (error) return <BootError error={error} onRetry={reload} />
  if (loading || !data) return <Boot />
  if (later || !mustCompleteOnboarding(data.onboarding)) return <Shell />

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