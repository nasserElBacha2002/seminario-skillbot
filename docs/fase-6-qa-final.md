# Fase 6 — QA final

Fecha de la revisión: 7 de noviembre de 2026. No se crearon commits ni se hizo push. No se escribieron datos en el proyecto remoto.

## A. Resumen ejecutivo

El MVP está implementado y es demostrable en código: autenticación, onboarding, ranking, dashboard, catálogo, prácticas, fichas, progreso y ayuda. Las 35 pruebas automáticas pasan y el build de producción termina bien.

**Veredicto: listo con limitaciones documentadas.**

No se declara validado de punta a punta. El recorrido con una cuenta (registro, cuestionario, práctica, XP y edición de preferencias) no se ejecutó, porque habría creado o modificado datos en el remoto. Lo que sí se comprobó está separado abajo de lo que solo se inspeccionó.

## B. Auditoría inicial

Estado de git al empezar, rama `perfil-usuario` (`85c3d5d`), sin commit de las fases 2 a 5:

- 16 archivos modificados (225 inserciones, 87 borrados).
- Sin seguimiento: `docs/fase-2-3-validacion.md`, `docs/fase-4-5-matching-dashboard.md`, `src/lib/matching.js` y las pruebas de matching, onboarding, práctica, progreso, búsqueda, caso del día y borrador.

`npm test` inicial de esta fase no se volvió a correr antes de editar: la corrida previa de la corrección del explorador había dado 35/35 y el build había pasado. Se repitieron ambos después de las correcciones de esta fase.

Navegación real, en `src/App.jsx`: no hay React Router. `Gate` muestra Auth, recuperación de contraseña o la app. `Entry` muestra el onboarding o `Shell`. `Shell` cambia entre inicio, explorar, detalle, progreso, ayuda y perfil.

### Hallazgos

| Severidad | Hallazgo | Qué se hizo |
|---|---|---|
| Medio | La ayuda decía que se filtra por categoría y que el buscador está en Inicio. Ese filtro ya no existe y la búsqueda está en Explorar. | Texto actualizado. |
| Medio | Una ficha se mostraba con el estilo de error: “Este caso todavía no tiene la práctica armada.” | Pasó a una nota de ficha, sin botón de práctica. |
| Medio | Textos de producto seguían hablando de “tareas cotidianas”, el parcial y “filtrar por categoría”. | Login, inicio, progreso, ayuda, perfil por defecto y README. |
| Medio | En pantallas angostas, el título de sección y “Ver todos los casos” quedaban en la misma fila. | La fila pasa a columna por debajo de 570 px. |
| Bajo | Las tarjetas de los 8 casos sin área mostraban el nombre histórico de categoría (Presentaciones, Estudio, etc.). | Si no hay área, no se muestra esa etiqueta. El caso sigue en Todas. |
| Bajo | El bundle JS pesa unos 582 kB. Vite avisa por el tamaño y por `"use client"` de lucide. | No se partió el bundle: el cambio no es chico y no mejora una función rota. |
| Bajo | `overallProgress` se calcula y se prueba, pero Progreso no muestra ese porcentaje. Muestra la cantidad de prácticas completadas. | Se dejó así. El rótulo ahora dice “Prácticas completadas”. |

No apareció un defecto crítico ni alto en el código ni en las consultas de solo lectura.

## C. Correcciones

- `src/components/HelpFaq.jsx`: la ayuda describe Explorar por área y las prácticas, no el filtro viejo.
- `src/pages/UseCasePage.jsx` y `src/styles.css`: la ficha informa el problema y el error frecuente. No abre desafíos.
- `src/components/UseCaseCard.jsx`: la etiqueta visible es el área. Sin área, no se inventa una categoría.
- `src/pages/HomePage.jsx`, `src/pages/ProgressPage.jsx`, `src/pages/HelpPage.jsx`, `src/components/AuthLayout.jsx`, `src/lib/queries.js`: textos alineados con emprendimientos.
- `src/styles.css`: títulos de sección en una columna bajo 570 px.
- `README.md` y `SUPABASE_SETUP.md`: el producto, el filtro visible y el estado de verificación.

No se tocaron el ranking, el seed, las migraciones ni el remoto.

## D. Pruebas funcionales

| Qué | Cómo | Resultado |
|---|---|---|
| 35 pruebas de matching, onboarding, práctica, progreso, búsqueda, caso del día y borrador | `npm test` | 35 pasaron, 0 fallaron |
| Build | `npm run build` | Pasó. JS 582,27 kB. Avisos de lucide y de chunk > 500 kB |
| Catálogo | Consulta de solo lectura | 53 publicados, 15/15/15, 8 sin área, 347 etiquetas, 0 etiquetas inválidas, 50 opciones de onboarding, 11 casos con plantilla, 3 desafíos y campos |
| Filtro de Explorar | Inspección de `CaseBrowser` | Solo área. Todas no filtra `area`. Cada área compara `item.area` |
| Login vacío | Clic en Entrar en el navegador | Alerta “Completá el email y la contraseña.” |
| Registro y recuperación | Navegación, sin enviar el formulario | Se ven “Creá tu cuenta” y “Restablecé tu contraseña” |

No se probó una contraseña incorrecta contra Supabase: eso no escribe datos, pero tampoco aporta más que el mensaje ya escrito en `Login.jsx` para `invalid_credentials`. No se envió el mail de recuperación.

## E. Pruebas end-to-end

No se hizo el recorrido autenticado.

Impedimento: la app en `http://localhost:5173` habla con el proyecto remoto. Crear una cuenta, completar el onboarding o terminar una práctica escribiría perfiles, respuestas, progreso y XP ahí. Esta fase no autoriza esa escritura.

Qué sí se recorrió, sin sesión:

1. Login en escritorio.
2. Login en 390 px, sin desborde horizontal (`scrollWidth` 390).
3. El mismo login en 570, 850 y 1440 px, sin desborde.
4. Validación de campos vacíos.
5. Pantalla de registro.
6. Pantalla de recuperación, sin enviar el enlace.

Pendiente, y por eso el veredicto no es “listo” a secas:

- Persistencia de sesión, cierre y cambio de cuenta.
- Onboarding completo, borrador, posponer y edición desde Perfil.
- Ranking visible después de guardar y al cambiar preferencias.
- Abrir una práctica, responder los tres desafíos y ver XP al recargar.
- Abrir una ficha en el navegador.
- Consola y red dentro de la app autenticada.

## F. Seguridad

Consultas de solo lectura sobre el remoto:

- 26 tablas `public`, las 26 con RLS.
- `onboarding_responses`: SELECT, INSERT y UPDATE solo para `authenticated`, políticas de la propia fila. No hay DELETE.
- `profiles`: solo SELECT de la propia fila. No hay política de UPDATE: el cliente no cambia XP ni nivel directo.
- `use_case_progress`: SELECT, INSERT y UPDATE de la propia fila.
- `use_case_tags`: SELECT para `anon` y `authenticated`.
- `complete_onboarding`, `complete_practice_challenge`, `resolve_use_case` y `update_profile_name` son `security definer`, con execute para `authenticated` y sin execute para `anon`.
- `add_xp(integer)` existe, es `security definer` y no tiene execute ni para `anon` ni para `authenticated`.
- En `src/` no aparece `service_role`. `.env.example` pide solo la anon key.

`complete_onboarding` usa `auth.uid()` y no recibe un id de perfil. No se debilitó ninguna política.

## G. Responsive

Comprobado en el navegador, solo en las pantallas de autenticación:

| Ancho | Desborde horizontal |
|---|---|
| 390 px | No |
| 570 px | No |
| 850 px | No |
| 1440 px | No |

En 390 el panel violeta de login se oculta y queda el formulario, como ya estaba en el CSS. Inicio, Explorar, el caso y Progreso no se vieron con sesión, así que esas grillas no tienen captura de esta fase. El CSS ya pasa la grilla de casos a 2 columnas a 850 px y a 1 a 570 px, y las áreas a 1 columna a 570 px. Se corrigió el título de sección para que no compita con el botón en esa misma anchura.

## H. Supabase

El esquema versionado tiene 14 migraciones, de `20261006232500_init_skillbot.sql` a `20261103120000_onboarding_model.sql`, y el catálogo en `supabase/seed.sql`.

La base remota, leída y no modificada, coincide con el catálogo esperado: 53 publicados, 15 por área, 8 sin área, 347 etiquetas válidas, 11 prácticas con plantilla y tres desafíos, 50 opciones de onboarding. Las 42 fichas son el resto (53 − 11).

`README.md` y `SUPABASE_SETUP.md` describen el orden de migraciones, el seed, las variables `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`, y que no hay que usar `service_role` ni `db reset` contra el remoto.

## I. Rendimiento

El catálogo, las etiquetas y el onboarding se leen una vez al entrar (`fetchSkillbotData`). El ranking corre en memoria con `useMemo` y no se guarda. No se detectó una consulta duplicada que justificara un cambio.

El JS de producción pesa 582 kB (gzip 166 kB). Partirlo implicaría rehacer la carga de pantallas. No se hizo.

## J. Documentación

Revisados: `docs/fase-0-auditoria.md`, `docs/fase-2-3-validacion.md`, `docs/fase-4-5-matching-dashboard.md`, `README.md`, `SUPABASE_SETUP.md`, migraciones, `package.json` y `.env.example`.

Actualizados en esta fase: `README.md`, `SUPABASE_SETUP.md` y este informe. La auditoría de la fase 0 se dejó como documento histórico.

## K. Limitaciones pendientes

- No hay evidencia de navegador del flujo autenticado.
- No hay despliegue de producción.
- El porcentaje general de prácticas se calcula y se prueba, pero la pantalla de Progreso muestra la cantidad, no ese porcentaje.
- El bundle supera 500 kB.
- `add_xp(uuid, integer)` sigue definido en migraciones viejas. En el remoto actual no está esa firma. No se borró nada en la base.

## L. Estado Git

Sin commit y sin push. Rama `perfil-usuario`. El diff contra `85c3d5d` tiene 20 archivos modificados: 255 inserciones y 102 borrados. Incluye las fases 2 a 5 y las correcciones de esta fase.

Sin seguimiento, además de las pruebas y de `src/lib/matching.js`: `docs/fase-2-3-validacion.md`, `docs/fase-4-5-matching-dashboard.md` y `docs/fase-6-qa-final.md`.
