# Aurora Viva V25 — Celestial Foundation (fase 1)

Refactor conservador de `shaders/program/deferred1.fsh` basado en V24.1.

## Separación
- `core.glsl`: constante TAU y herramientas orbitales/de máscara.
- `planets.glsl`: superficies y materiales planetarios.
- `blackhole.glsl`: disco, flujo, lente y funciones del agujero negro.
- `renderer.glsl`: posiciones y composición de los cuatro planetas.

Los cuatro includes absolutos se expanden exactamente al código GLSL V24.1 original (sin las cuatro cabeceras de comentario nuevas). Mantener el orden de includes es indispensable.

No se modificaron atmósfera, estrellas, nubes, shaders.properties ni ajustes de Iris.
`shaders/global/atmosphere/sky.glsl` y `get_stars()` siguen donde estaban; la siguiente fase integrará sus interfaces cuando podamos probar la compilación en Iris.

Prueba necesaria en Minecraft: mundo normal con y sin shaders, día, crepúsculo, noche, agujero negro, planetas, nubes y opciones Iris.
