import { CaseBrowser } from '../components/CaseBrowser'
import { Layout } from '../components/Layout'

export function ExplorePage({ setPage, openCase }) {
  return (
    <Layout page="explorar" setPage={setPage}>
      <section className="page explore-page">
        <div className="page-intro">
          <p className="eyebrow">POR TIPO DE TAREA</p>
          <h1>Explorá un problema parecido al tuyo</h1>
          <p>Las categorías agrupan necesidades, no herramientas.</p>
        </div>
        <CaseBrowser searchId="explore-search" onOpen={(id) => openCase(id, 'explorar')} />
      </section>
    </Layout>
  )
}
