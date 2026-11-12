# Fases 4 y 5 — Matching y dashboard

El ranking corre en el navegador. No hay tabla de recomendaciones, no se escribe el puntaje en Supabase y no se llama a un modelo externo.

## 1. Arquitectura

1. `fetchSkillbotData` trae el catálogo publicado, con `use_case_tags(kind, value)`, en la misma consulta de casos.
2. Cada caso queda con `tags`, `area`, `minutes`, `sortOrder` y el resto de los campos que ya usaba la app.
3. `SkillbotDataProvider` calcula `rankUseCases(answers, useCases, options)` cuando cambia `data`.
4. Inicio muestra los seis mejores si el onboarding está completo. Explorar sigue mostrando el catálogo entero y suma el filtro por área.
5. Guardar el cuestionario desde Perfil reemplaza `data.onboarding.answers`. El `useMemo` del provider vuelve a ordenar sin recargar la página y sin tocar progreso, XP ni logros.

## 2. Firma

```js
rankUseCases(answers, useCases, options)
```

`answers` es `data.onboarding.answers`. `options` es el vocabulario agrupado por `kind`. Los ids que no están en ese vocabulario se descartan y no diluyen el puntaje.

Devuelve una lista ordenada:

```js
{
  id,
  score,
  breakdown: { problems, goal, area, compatibility, time },
  reasons: [{ kind, value }],
  practiceReady,
  position
}
```

`compatibility` es la suma de herramientas y experiencia. `score` es la suma de los cinco valores de `breakdown`. El resultado está entre 0 y 100.

## 3. Fórmulas

| Criterio | Máximo | Cálculo |
|---|---:|---|
| Problemas | 40 | Si no hay intersección, 0. Si hay, `40 * (0,5 + 0,5 * aciertos / problemas del usuario)`. |
| Objetivo | 25 | 25 si `primaryGoal` está entre las etiquetas `goal`. Si no, 0. |
| Área | 20 | `20 * áreas compartidas / áreas elegidas`. |
| Herramientas | 6 | `6 * herramientas compartidas / herramientas reales del usuario`. |
| Experiencia | 4 | Según la distancia entre niveles. |
| Tiempo | 5 | 5 si el caso entra en la franja. Si no, `5 * capacidad / minutos del caso`. |

Las etiquetas del caso que no coinciden no suman. Por eso un caso con muchas etiquetas no gana solo por tener más.

El medio punto fijo del primer problema hace que una coincidencia concreta supere a un caso que solo comparte el área. Con dos dificultades y un acierto, problemas vale 30. El área de un solo rubro, cuando el usuario eligió uno, vale 20.

### Área

Se toma la unión de `use_cases.area` y las etiquetas `area`. Si la columna y la etiqueta dicen lo mismo, cuenta una sola vez. Un caso de otra área queda en la lista con 0 en este criterio y puede ganar por el problema.

### Herramientas y experiencia

`ninguna` se elimina antes de comparar. No suma puntos.

La etiqueta vieja `diseno` se lee como `canva`, que es el id del onboarding. No se comparan nombres visibles ni se usa `use_case_tools.id` para el puntaje. Esas filas siguen sirviendo para mostrar la herramienta recomendada en el caso.

Niveles de experiencia, de menor a mayor: `nunca` (0), `alguna_vez` (1), `seguido` (2), `en_el_negocio` (3). El nivel del caso es el más alto entre sus etiquetas `experience`.

| Distancia caso − usuario | Puntos |
|---|---:|
| 0 o el usuario está por encima | 4 |
| el caso pide un nivel más | 2 |
| el caso pide dos o más | 1 |
| el caso no tiene etiqueta, o la respuesta no es válida | 0 |

Un principiante no desaparece del catálogo. Un usuario de `en_el_negocio` puede hacer un caso etiquetado para `nunca` y recibe los 4 puntos.

### Tiempo

La franja es un máximo, no una duración obligatoria.

| Id | Capacidad |
|---|---|
| `menos_15` | 15 minutos |
| `de_15_a_30` | 30 minutos |
| `de_30_a_60` | 60 minutos |
| `mas_de_60` | sin techo |

Un caso de 20 minutos con `de_30_a_60` recibe 5. Un caso de 60 minutos con `menos_15` recibe 1,25. Si el caso no tiene minutos, este criterio vale 0.

## 4. Orden

1. Mayor `score`.
2. Menor `sortOrder`.
3. Id ascendente.

No hay azar. La misma entrada produce la misma lista. `position` empieza en 1.

`practiceReady` usa `isPracticeReady`. Una ficha no pierde puntos por no tener guía.

## 5. Razones

Solo se guardan las coincidencias que aportaron puntos: cada problema, el objetivo, cada área, cada herramienta, la experiencia y el tiempo.

La tarjeta muestra una sola frase, en este orden de prioridad: problema, objetivo, área, herramienta, experiencia, tiempo. El texto sale del `label` de `onboarding_options`. Si no hay label, no se inventa una frase.

Ejemplos:

- `Te recomendamos este caso porque marcaste «Controlar gastos».`
- `Coincide con tu objetivo de conseguir clientes.`
- `Está relacionado con tu interés en Marketing.`

## 6. Sin onboarding

`personalized` es verdadero solo si `onboarding_completed_at` tiene valor y hay alguna respuesta distinta de `ninguna`.

Quien no completó, o eligió posponer, ve el catálogo, el caso del día, los casos empezados y un botón a Perfil. No se arma un ranking con XP ni con el progreso. No se muestran porcentajes.

## 7. Inicio

1. Encabezado. Con respuestas, explica que el orden sale de lo marcado. Sin ellas, invita a completar el cuestionario.
2. Seis casos con puntaje mayor que 0, si hay personalización. Cada tarjeta trae título, área, resumen, duración, dificultad, si es práctica o ficha, y el motivo. No muestra el número.
3. Tres accesos: Marketing, Finanzas y Administración. Abren Explorar con esa área. No repiten las tarjetas de arriba. Las áreas no elegidas siguen visibles.
4. Casos empezados y completados, como antes.
5. Caso del día, solo si `caseOfTheDay` devuelve una práctica.

Si el catálogo viene vacío, se dice eso. La carga y el error siguen en `Entry` y `Shell`, antes de llegar a Inicio.

## 8. Explorar

El filtro visible es solo el área del negocio: Todas, Marketing, Finanzas y Administración. Todas incluye los 53 casos publicados, también los ocho que tienen `area` null. Cada área muestra los casos de ese valor.

`categories` y `use_case_categories` siguen en la base y no se usan como filtro. La búsqueda se combina con el área elegida. Si no hay resultados, se puede limpiar el texto sin cambiar el área. El cuestionario no oculta casos.

## 9. Edición

`saveOnboarding` escribe la RPC y reemplaza `answers` y `completedAt` en el estado. No llama a progreso ni a logros. Al volver a Inicio, las tarjetas salen del ranking nuevo.

## 10. Pruebas

`npm test`: 35 pruebas, 0 fallos. Incluye las 21 anteriores y las del matching: una área, varias áreas, problema que gana fuera del área, mismo rubro con distinto puntaje, objetivo exacto, problema compartido, experiencia inicial y avanzada, `ninguna`, herramienta sin cobertura, alias `diseno`/`canva`, tiempo mayor y menor, ficha, empate por `sort_order`, empate por id, respuestas vacías, ids inválidos y caso sin etiquetas. Cada prueba controla que la suma de `breakdown` sea el `score` y que el rango sea 0–100.

`npm run build` terminó bien. Vite avisó, como antes, del tamaño del chunk y de `use client` en `lucide-react`.

No se recorrió el dashboard con una sesión real: hacerlo habría escrito o dependido de una cuenta en el remoto. El layout usa la grilla ya existente: una columna hasta 570 px, dos hasta 850 px y tres en escritorio. Las áreas del inicio pasan a una columna solo por debajo de 570 px. Los filtros hacen salto de línea.

## 11. Limitaciones

- Los ocho casos originales no tienen etiquetas. Solo pueden sumar por tiempo, si tienen duración. Siguen en Explorar, en Todas.
- `copilot`, `notebooklm` y `empezar_sin_experiencia` no tienen casos. Elegirlos no suma en ese criterio.
- El número del score no se muestra. Está en `recommendations` por si más adelante hace falta.
- No se verificó el dashboard en el navegador con un usuario autenticado.

## 12. Después

Una fase posterior puede mostrar el desglose o afinar los pesos. El lugar para hacerlo es `src/lib/matching.js`. No hace falta una migración.
