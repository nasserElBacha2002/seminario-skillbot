# Fases 2 y 3 — Validación

Fecha de la auditoría: 7 de noviembre de 2026. La fuente de verdad fue el código del repositorio, `supabase/seed.sql`, `supabase/migrations/20261103120000_onboarding_model.sql` y consultas de solo lectura sobre el proyecto remoto ya vinculado. No se modificó ese remoto, no se hizo `db reset` y no se crearon commits.

## A. Estado inicial

El árbol de git estaba limpio. Las Fases 2 y 3 ya estaban en el código, no solo en la conversación.

Ya existía:

- El seed con los 8 casos originales y los 45 nuevos.
- En el remoto, 53 casos publicados, 347 etiquetas y las tres prácticas nuevas.
- El cuestionario de seis preguntas (`OnboardingWizard`, `src/lib/onboarding.js`), el borrador por usuario, “Ahora no” solo en `sessionStorage`, el guardado con `complete_onboarding` y la edición desde Perfil.
- La RPC y las políticas de la migración de onboarding.

No estaba cerrado:

- El porcentaje de progreso dividía por los 53 casos, fichas incluidas.
- El caso del día podía ser una ficha.
- Buscar “Instagram” también devolvía casos de imágenes, porque `instagram` era sinónimo de `imagen`.
- La tarjeta y la pantalla del caso repetían, por separado, la condición de práctica disponible.
- Si la carga fallaba, `Entry` se quedaba en “Cargando…” porque miraba `!data` antes que el error.
- No había pruebas automatizadas.
- `README.md` y el cierre de `SUPABASE_SETUP.md` todavía decían que la app no llamaba `complete_onboarding`.

## B. Problemas detectados

1. `summarize` no existía: `derive()` usaba `raw.useCases.length` como denominador. Agregar fichas bajaba el porcentaje sin que el usuario hubiera perdido progreso.
2. `caseOfTheDay` elegía entre todo el catálogo ordenado por id.
3. El grupo de sinónimos `imagen` incluía `instagram`.
4. `UseCaseCard` y `UseCasePage` no compartían la función de disponibilidad.
5. Un error de red o de esquema en el primer fetch no llegaba a `BootError`.
6. Cobertura real, no un defecto a tapar con etiquetas: `empezar_sin_experiencia`, `copilot` y `notebooklm` no tienen casos. `ninguna` tampoco, y no debe tenerlos: es la opción exclusiva de “no uso herramientas”.
7. Los ocho casos originales tienen `in_practice = false` en la base. Siguen siendo practicables porque `practiceFieldKeys` y el respaldo de `practiceFieldsOf` marcan sus campos. No se reescribió ese contenido.
8. El porcentaje `overallProgress` se calcula y no se muestra en Inicio ni en Progreso. Igual quedó corregido para que un uso posterior no vuelva al denominador de 53.

## C. Correcciones aplicadas

- `isPracticeReady` en `src/lib/practice.js`. La usan la tarjeta, la pantalla del caso, el progreso y el caso del día. Hace falta al menos un campo de práctica, exactamente tres desafíos y una plantilla.
- `summarizePracticeProgress` en `src/lib/progress.js`. El numerador y el denominador usan solo esas prácticas. El progreso guardado de una ficha no se borra y no entra en la cuenta. XP, logros, racha y filas de `use_case_progress` no se tocan.
- `caseOfTheDay` ignora las fichas. Si no hay prácticas, devuelve `null`. Inicio muestra “Hoy no hay una práctica disponible.”
- Se sacó `instagram` del grupo de `imagen` / `foto` / `redes`. El título o la descripción que dicen Instagram siguen encontrando el caso.
- `Entry` muestra el error de carga antes del estado de espera.
- `npm test` corre `node --test` sobre los módulos puros. No se agregó un framework.

No se cambió el seed, la migración ni el remoto.

## D. Catálogo

Consulta de solo lectura al remoto, después del seed ya aplicado:

| Grupo | Cantidad |
|---|---|
| Publicados | 53 |
| Marketing | 15 |
| Finanzas | 15 |
| Administración | 15 |
| Originales, `area` null | 8 |
| Títulos distintos | 53 |
| Etiquetas | 347 |
| Etiquetas con id inexistente en `onboarding_options` | 0 |
| Claves de etiqueta duplicadas | 0 |
| Casos nuevos incompletos (sin título, resumen, situación, aprendizaje, dificultad o duración) | 0 |

Los 42 casos que no son `auditoria-instagram`, `diagnostico-financiero` ni `pedidos-multicanal` no tienen campos, desafíos ni plantilla.

Los ocho originales siguen con campos, 3 desafíos, 3 opciones correctas y plantilla. Sus ids no cambiaron.

### Prácticas nuevas

| Caso | Campos | Pasos | Desafíos | Plantilla |
|---|---|---|---|---|
| `auditoria-instagram` | cuenta, periodo, metricas, objetivo, piezas | 5 | 3 | sí |
| `diagnostico-financiero` | periodo, ventas, gastos, caja, deudas | 5 | 3 | sí |
| `pedidos-multicanal` | canales, pedidos, estados, problema | 5 | 3 | sí |

En el desafío financiero, el escenario informa ventas $800.000 y gastos $650.000. La resta es $150.000 y el margen sobre ventas es 18,75 %. La respuesta de la IA que el desafío marca como incorrecta dice “margen real 35 %”. La opción correcta es rechazar ese margen porque no sale de esos totales. No se simula acceso a un banco.

Instagram y los pedidos se resuelven con datos que la persona pega. Las opciones correctas rechazan pedir acceso a la cuenta o inventar un estado.

### Matriz de problemas

Cada fila es un `onboarding_options.kind = 'problem'`. Los casos son los ids etiquetados en el remoto.

| Problema | Casos | Ids |
|---|---|---|
| `ahorrar_tiempo_repetitivo` (transversal) | 5 | asistente-de-tareas, dejar-escrito-el-proceso, pedidos-multicanal, respuestas-que-se-repiten, seguimiento-de-pedidos |
| `armar_precios` | 5 | costos-de-un-producto, precio-cubre-costo, promo-sin-romper-precio, punto-de-equilibrio, simular-precio |
| `atender_clientes` | 1 | historial-de-reclamos |
| `atraer_clientes` | 4 | campana-presupuesto, embudo-consultas, lanzamiento-oferta, retomar-consultas |
| `cobrar_a_tiempo` | 2 | a-quien-cobrar, hueco-de-caja |
| `controlar_gastos` | 7 | clasificar-comprobantes, costos-de-un-producto, diagnostico-financiero, gastos-que-se-repiten, plata-del-negocio, precio-cubre-costo, rentabilidad-por-producto |
| `coordinar_pendientes` | 7 | control-de-recepcion, donde-se-traba, elegir-proveedor, pedidos-multicanal, primera-semana-de-alguien, reparto-semanal, reunion-de-la-semana |
| `crear_contenido` | 3 | calendario-contenidos, piezas-de-campana, tendencias-rubro |
| `decidir_con_informacion` (transversal) | 7 | analisis-competidores, elegir-canales, elegir-proveedor, evaluar-una-compra, que-hacer-esta-semana, que-reponer, tendencias-rubro |
| `documentar_procesos` | 3 | asistente-de-tareas, dejar-escrito-el-proceso, primera-semana-de-alguien |
| `entender_ventas` | 8 | cierre-del-dia, diagnostico-financiero, meses-flojos, punto-de-equilibrio, rentabilidad-por-producto, simular-precio, tablero-del-mes, tres-escenarios |
| `explicar_oferta` | 6 | analisis-competidores, lanzamiento-oferta, objeciones-de-venta, piezas-de-campana, promo-sin-romper-precio, propuesta-valor |
| `hacer_seguimiento` | 4 | historial-de-reclamos, pendientes-del-dia, retomar-consultas, seguimiento-de-pedidos |
| `medir_resultados` | 3 | auditoria-instagram, campana-presupuesto, rendimiento-anuncios |
| `ordenar_comprobantes` | 3 | clasificar-comprobantes, control-de-recepcion, tablero-del-mes |
| `organizar_tareas` | 7 | cierre-del-dia, donde-se-traba, pedidos-multicanal, pendientes-del-dia, que-hacer-esta-semana, que-reponer, reparto-semanal |
| `preparar_reuniones` | 1 | reunion-de-la-semana |
| `proyectar_caja` | 7 | a-quien-cobrar, diagnostico-financiero, evaluar-una-compra, hueco-de-caja, meses-flojos, plata-del-negocio, tres-escenarios |
| `publicar_en_redes` | 3 | auditoria-instagram, calendario-contenidos, elegir-canales |
| `responder_consultas` | 3 | embudo-consultas, objeciones-de-venta, respuestas-que-se-repiten |
| `empezar_sin_experiencia` (transversal) | 0 | — |

`promo-sin-romper-precio` lleva `armar_precios` y también `explicar_oferta`. Es un caso de precio que toca cómo se cuenta la oferta. No se sacó la etiqueta.

Sin casos, y sin etiquetas agregadas para disimularlo: `empezar_sin_experiencia`, `copilot`, `notebooklm`. `ninguna` queda sin casos a propósito.

Los dos problemas transversales con casos mezclan áreas: `decidir_con_informacion` aparece en marketing, finanzas y administración; `ahorrar_tiempo_repetitivo` aparece en administración y en tareas que cruzan atención y operación. El cuestionario no esconde los problemas de las áreas que el usuario no eligió.

## E. Onboarding

Las seis preguntas están en `STEPS`. Los títulos son los pedidos. Las opciones salen de `onboarding_options` por `kind`: `area`, `problem`, `tool`, `experience`, `goal`, `time`.

- Áreas, problemas y herramientas son selección múltiple.
- Experiencia, objetivo y tiempo son selección única.
- `ninguna` reemplaza al resto de las herramientas.
- Un paso vacío no avanza.
- El borrador es `skillbot:${userId}:onboarding` y se borra después de un guardado confirmado.
- “Ahora no” es `sessionStorage` y se limpia al cerrar sesión. No escribe `onboarding_completed_at`.
- Una cuenta nueva no puede posponer. Una cuenta con XP, progreso, actividad, un logro o más de 24 horas de creada, sí.
- Perfil reutiliza el mismo wizard en modo edición y llama a `saveOnboarding`.
- `saveOnboarding` solo reemplaza `data.onboarding`. No recarga logros ni escribe progreso.

La firma usada es la de la migración: `complete_onboarding(p_areas, p_problems, p_tools, p_ai_experience, p_primary_goal, p_available_time)`.

El objeto normalizado, listo para una fase de matching y todavía sin puntaje, es `data.onboarding.answers`:

```js
{
  areas: ['marketing', 'finanzas'],
  problems: ['atraer_clientes', 'controlar_gastos'],
  tools: ['instagram', 'excel'],
  aiExperience: 'alguna_vez',
  primaryGoal: 'conseguir_clientes',
  availableTime: 'de_30_a_60',
  updatedAt: null
}
```

Los ids del ejemplo son los del vocabulario real. Las claves del cliente están en camelCase porque así las consume el wizard. `toOnboardingParams` las traduce a los argumentos de la RPC.

## F. Pruebas

| Prueba | Resultado | Evidencia | Limitación |
|---|---|---|---|
| Definición de práctica y ficha | Pasó | `npm test`, `practice.test.js` | No abre el navegador |
| Progreso sin datos, iniciado, completado y con fichas nuevas | Pasó | `progress.test.js`, 4 pruebas | `overallProgress` no está dibujado en la UI |
| Caso del día determinista y nunca ficha | Pasó | `daily.test.js` | No se recorrió el botón en el navegador |
| Búsqueda de Instagram, vacío y título parcial | Pasó | `search.test.js` | No se probaron los seis filtros de categoría en el navegador |
| Seis preguntas, `ninguna`, mezcla de áreas, normalización, posponer | Pasó | `onboarding.test.js` | No se creó un usuario en el remoto |
| Borrador separado por usuario | Pasó | `storage.test.js`, `localStorage` en memoria | No se recargó el navegador |
| Catálogo 53 / 15 / 15 / 15 / 8 | Pasó | `supabase db query --linked`, solo lectura | No se volvió a correr el seed |
| Etiquetas válidas y matriz | Pasó | Misma consulta | No se juzgó cada una de las 347 a mano |
| Tres guías y cuenta 800.000 − 650.000 | Pasó | Lectura de campos, desafíos y escenario | No se jugaron los tres desafíos en la UI |
| Ocho originales intactos | Pasó | Conteos de campos, pasos, desafíos y opciones correctas | No se abrió cada uno |
| 42 fichas sin práctica | Pasó | Consulta: ningún otro caso nuevo tiene campos, desafíos o plantilla | No se abrió cada ficha |
| RLS de onboarding | Pasó | Políticas leídas en `pg_policy` | No se intentó leer la fila de otro usuario con un JWT ajeno |
| `npm run build` | Pasó | Vite 8, `dist/assets/index-BEPdktSB.js` | Aviso previo de `lucide-react` y del tamaño del chunk. No lo introdujo esta corrección |
| Registro, guardado real, edición en Perfil, logout, cambio de cuenta, mobile 390 px | No ejecutada | — | Escribiría en el remoto o exige la sesión del usuario. El código de esos flujos ya estaba y no se reescribió |

`npm test`: 21 pruebas, 0 fallos.

## G. Seguridad

- El cliente usa `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`. No hay `service_role` en `src/`.
- `complete_onboarding` no recibe un id de perfil. Usa `auth.uid()` y es `security definer` con `search_path` vacío.
- En el remoto, `onboarding_responses` tiene políticas de lectura, alta y actualización propias. No hay política de borrado.
- `onboarding_options` y `use_case_tags` solo tienen política de lectura.
- `saveOnboarding` no llama a `saveUseCaseProgress`, `add_xp` ni `unlockAchievement`.
- No se modificó ninguna política histórica.

No se hizo una prueba de intrusión con dos sesiones. La revisión es el SQL de la migración más las políticas presentes en el remoto.

## H. Archivos

Creados:

- `src/lib/progress.js`
- `src/lib/practice.test.js`
- `src/lib/progress.test.js`
- `src/lib/daily.test.js`
- `src/lib/search.test.js`
- `src/lib/onboarding.test.js`
- `src/lib/storage.test.js`
- `docs/fase-2-3-validacion.md`

Modificados:

- `src/lib/practice.js`
- `src/lib/daily.js`
- `src/lib/search.js`
- `src/context/SkillbotData.jsx`
- `src/pages/UseCasePage.jsx`
- `src/pages/HomePage.jsx`
- `src/components/UseCaseCard.jsx`
- `src/App.jsx`
- `package.json`
- `README.md`
- `SUPABASE_SETUP.md`

No se eliminó ningún archivo. No se tocó `supabase/seed.sql` ni la migración.

## I. Pendientes

- `empezar_sin_experiencia`, `copilot` y `notebooklm` siguen sin casos. No se inventaron etiquetas.
- `atender_clientes` y `preparar_reuniones` tienen un solo caso. Es cobertura baja, no un error de integridad.
- El recorrido autenticado en el navegador (alta, guardado, Perfil, mobile) no se repitió en esta auditoría.
- `overallProgress` sigue sin una barra propia en la pantalla de progreso. El número ya no se diluye cuando alguien lo use.

Nada de eso bloquea el catálogo ni el cuestionario.

## J. Próximas fases

Queda preparado `data.onboarding.answers` y `use_case_tags`, con los mismos ids. La Fase 4 puede puntuar casos de las tres áreas a la vez. Esta auditoría no ordena el explorador ni arma recomendaciones.

La Fase 5, el dashboard personalizado, tampoco está hecha. Inicio sigue mostrando el caso del día entre las prácticas, los casos empezados y los completados.
