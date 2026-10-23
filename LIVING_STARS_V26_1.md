# Aurora Viva V26.1 - Living Stars

Baseline: V25.5 Celestial Foundation (tag v25.6-celestial-foundation).

## Cambios visuales intencionales
- Estrellas de distintos tamanos, intensidades y tonos sutilmente calidos/frios.
- Posicion determinista segun worldTime/worldDay; sin desplazamiento acumulado por sesion.
- Parpadeo discreto, solo en brillo, sin cambiar sus coordenadas.
- Atenuacion por clima y proximidad de la Luna. Sin nuevos recursos/texturas.
- Boton AV_LIVING_STARS=0 para recuperar estrellas V25.5.
- Nether y End siguen con la formula original; Sol, planetas, nubes y agujero negro intactos.

## Construccion e instalacion
Ejecutar Build-AuroraViva-V26.ps1 -InstallToModrinth. Nombres r001, r002... sin sobrescribir.
El script reconstruye deferred1.fsh y valida SHA256 antes de publicar el ZIP.

## Pruebas pendientes
Compilacion real en Iris, noche y amanecer, cielo despejado/lluvioso, Luna cercana,
End, FPS 1440p y lente gravitacional del agujero negro. No hacer commit hasta probar.
