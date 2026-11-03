import { Bot, Sparkles, Zap } from 'lucide-react'
import { Logo } from './Layout'

export function AuthLayout({ children }) {
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
        {children}
      </section>
    </div>
  )
}
