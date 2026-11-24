export function CaseFlowScene({ children, panelClass = '' }) {
  const panel = ['ficha-pager', panelClass].filter(Boolean).join(' ')
  return (
    <div className="ficha-pager-scene">
      <div className="ficha-pager-bg" aria-hidden>
        <span className="intro-orb intro-orb-a" />
        <span className="intro-orb intro-orb-b" />
        <span className="intro-orb intro-orb-c" />
      </div>
      <div className={panel}>{children}</div>
    </div>
  )
}