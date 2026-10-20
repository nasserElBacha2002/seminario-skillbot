-- Saca de la base el texto interno de la encuesta que se muestra en la ficha
-- del caso ("SALE DE LA ENCUESTA" y las menciones).
--
-- Borra las filas, no la tabla: la app sigue consultando use_case_survey_tasks
-- y, si no hay filas, esa sección no se renderiza.
--
-- Pegar en el SQL Editor y ejecutar. No vuelve a correr seed.sql completo,
-- porque ese archivo vuelve a insertar estas filas.

delete from public.use_case_survey_tasks;
