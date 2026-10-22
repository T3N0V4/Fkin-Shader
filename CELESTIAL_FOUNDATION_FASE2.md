# Aurora Viva V25 - Celestial Foundation, fase 2.1 y 2.2

## Auditoria de dependencias

- `shaders/program/deferred1.fsh` contiene la funcion ACTIVA `get_sky()` y `get_stars()`.
- `shaders/global/atmosphere/sky.glsl` tiene otra implementacion de `get_sky()` y NO se modifica aqui.
- `shaders/global/lighting/gbuffers.fsh` y `gbuffers.vsh` incluyen el archivo global.
- No se elimina ni modifica el codigo de cielo de otros pases en esta fase.
- `get_stars()` y el agujero negro no cambian.

## Cambio de fase 2.2

- La implementacion original de `get_sky()` se extrae sin alteraciones a `shaders/lib/auroraviva/celestial/atmosphere.glsl`.
- `deferred1.fsh` conserva solo un include para esa funcion.
- El generador expande el include y verifica el SHA256 del deferred1.fsh final contra el V24.1 funcional.
- La construccion ZIP usa rutas '/' y un nombre nuevo r001, r002, etc. en cada build.

## Pruebas pendientes en Iris

Verificar amanecer, dia, anochecer, noche, luna, planetas, agujero negro y nube.
Comparar FPS con el V25 estable. No etiquetar como release hasta probarlo.