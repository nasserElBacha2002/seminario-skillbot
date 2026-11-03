import { useState } from 'react'
import { Bot, CircleHelp, Home, Menu, Search, Trophy, UserRound, Zap } from 'lucide-react'
import { useSkillbotData } from '../context/SkillbotData'

const nav = [
  ['inicio', 'Inicio', Home],
  ['explorar', 'Explorar', Search],
  ['progreso', 'Progreso', Trophy],
  ['perfil', 'Perfil', UserRound],
  ['ayuda', 'Ayuda', CircleHelp],
]

export function Logo() {
  return (
    <div className="logo">
      <span><Bot size={19} /></span>
      <b>SkillBot</b>
    </div>
  )
}

export function ProgressBar({ value, color = 'violet' }) {
  return (
    <div className="progress" role="meter" aria-valuenow={value} aria-valuemin={0} aria-valuemax={100} aria-label={`${value}%`}>
      <i className={color} style={{ width: `${value}%` }} />
    </div>
  )
}

function Sidebar({ page, setPage, open, setOpen }) {
  const { data } = useSkillbotData()
  return (
    <>
      <aside className={`sidebar ${open ? 'open' : ''}`}>
        <Logo />
        <nav>
          {nav.map(([id, label, Icon]) => (
            <button
              key={id}
              type="button"
              className={page === id ? 'active' : ''}
              aria-current={page === id ? 'page' : undefined}
              onClick={() => { setPage(id); setOpen(false) }}
            >
              <Icon size={19} />{label}
            </button>
          ))}
        </nav>
        <div className="side-bottom">
          <button type="button" className="profile-mini" onClick={() => { setPage('perfil'); setOpen(false) }}>
            <span>{data.profile.initials}</span>
            <div><b>{data.profile.name}</b><small>{data.level.name}</small></div>
          </button>
        </div>
      </aside>
      {open && <button type="button" className="scrim" aria-label="Cerrar menú" onClick={() => setOpen(false)} />}
    </>
  )
}

export function Layout({ page, setPage, children }) {
  const { data } = useSkillbotData()
  const [menu, setMenu] = useState(false)
  const titles = {
    inicio: 'Inicio',
    explorar: 'Explorar',
    detalle: 'Caso de uso',
    desafio: 'Desafío',
    progreso: 'Progreso',
    perfil: 'Perfil',
    ayuda: 'Centro de ayuda',
  }
  return (
    <div className="app">
      <Sidebar page={page} setPage={setPage} open={menu} setOpen={setMenu} />
      <main>
        <header className="topbar">
          <button type="button" className="mobile-menu" aria-label="Abrir menú" aria-expanded={menu} onClick={() => setMenu(true)}>
            <Menu />
          </button>
          <div className="crumb">{titles[page]}</div>
          <div className="top-actions">
            <button type="button" className="xp-pill" onClick={() => setPage('progreso')}>
              <Zap size={15} fill="currentColor" />{data.profile.xp} XP
            </button>
            <button type="button" className="avatar" aria-label={`Perfil de ${data.profile.name}`} onClick={() => setPage('perfil')}>
              {data.profile.initials}
            </button>
          </div>
        </header>
        {children}
      </main>
    </div>
  )
}
