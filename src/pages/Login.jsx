import { ArrowRight, Bot, Sparkles, Zap } from 'lucide-react'
import { Logo } from '../components/Layout'

export function Login({ onLogin }) {
  return (
    <div className="login">
      <section className="login-panel">
        <Logo />
        <div className="login-copy">
          <p className="eyebrow">EMPEZÁ POR EL PROBLEMA</p>
          <h1>Bienvenido a<br /><em>SkillBot</em></h1>
          <p>Decinos qué necesitás resolver. Te armamos un pedido listo para usar con IA.</p>
        </div>
        <div className="login-art">
          <div className="art-card a"><Bot size={28} /><b>Resolvé</b><small>una tarea concreta</small></div>
          <div className="art-card b"><Sparkles size={24} /><b>Llevate</b><small>un pedido listo</small></div>
          <div className="art-orb"><Zap size={33} fill="currentColor" /></div>
          <i className="line l1" /><i className="line l2" />
        </div>
        <small className="login-footer">SkillBot · De la necesidad al resultado</small>
      </section>
      <section className="login-form-wrap">
        <form className="login-form" onSubmit={(event) => { event.preventDefault(); onLogin() }}>
          <div className="mobile-logo"><Logo /></div>
          <h2>Entrá a la demo</h2>
          <p>No hace falta una cuenta real. Entrá y elegí qué querés resolver.</p>
          <label>Email<input type="email" autoComplete="username" placeholder="nombre@ejemplo.com" defaultValue="martin@email.com" /></label>
          <label>Contraseña<input type="password" autoComplete="current-password" placeholder="••••••••" defaultValue="12345678" /></label>
          <button type="submit" className="primary login-button">Entrar <ArrowRight size={18} /></button>
          <p className="demo-note"><Sparkles size={15} /> Demo académica · Podés ingresar con cualquier dato</p>
        </form>
      </section>
    </div>
  )
}
