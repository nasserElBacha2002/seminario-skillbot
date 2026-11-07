import { CaseBrowser } from '../components/CaseBrowser'
import { Layout } from '../components/Layout'

export function ExplorePage({ setPage, openCase, area = 'todos', onAreaChange }) {
  return (
    <Layout page="explorar" setPage={setPage}>
      <section className="page explore-page">
        <div className="page-intro">
          <p className="eyebrow">CATÁLOGO</p>
          <h1>Explorá un problema parecido al tuyo</h1>
          <p>Encontrá soluciones prácticas con inteligencia artificial para los desafíos de tu emprendimiento.</p>
        </div>
        <CaseBrowser
          searchId="explore-search"
          area={area}
          onAreaChange={onAreaChange}
          onOpen={(id) => openCase(id, 'explorar')}
        />
      </section>
    </Layout>
  )
}
