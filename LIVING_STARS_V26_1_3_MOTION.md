# Aurora Viva V26.1.3 - Smooth Celestial Motion

El atlas estelar de V26.1.2 se conserva sin cambios. Este parche ataca los saltos
que pueden aparecer cuando las estrellas y los planetas usan worldTime entero.

* core.glsl: usa sunAngle (interpolado por fotograma) para recuperar la fraccion
  del tick de Minecraft. Toggle AV_CELESTIAL_SMOOTH_TIME=1; valor 0 para comparar.
* renderer.glsl: los cuatro planetas cambian su deriva discreta por deriva continua
  sobre el tiempo absoluto: `(days + dayPhase) * drift`.
* stars.glsl, blackhole.glsl, atlas, nubes: no se modifican.
* shader ZIP unico V26_1_3_MovimientoSuave_r001, r002 etc; rutas internas `/`.

Diagnostico: comparar suavidad con toggle 1 y 0. Para FPS, probar por separado
AV_BH_TRACE_QUALITY=56 y 72; AV_BLACK_HOLE Off vs On; AV_LIVING_STARS 0/1.
La interpolacion del reloj no corrige caidas reales de FPS/TPS/driver.
No generar commit hasta comprobar en Iris y el mismo mundo.
