# Aurora Viva V25.4 - Celestial Core (fase 2.4)

Base: V25.3, rama feature/celestial-foundation de T3N0V4/Fkin-Shader.

## Cambios
- core.glsl: AVCelestialContext y av_celestial_context() con reloj del mundo,
  dia/noche, atardecer, clima, visibilidad y direcciones solares/lunares en mundo.
- renderer.glsl: usa el contexto compartido para renderizar los cuatro planetas.
- El codigo del agujero negro, las estrellas y la atmosfera NO cambia.
- Esta fase NO cambia el movimiento de estrellas basado en frameTimeCounter.
- El compilador genera siempre un ZIP nuevo V25_4_CelestialCore_r001/r002/... e
  inspecciona estructura de Iris, y valida el SHA256 del GLSL expandido.

## Validacion estatica
- SHA256 esperado deferred1.fsh expandido: 3bbb91231cd259e1830d7bb22cb37eb238be2f50dccc6956acdaefbf171e9601
- Las formulas en core son las mismas expresiones que antes estaban en renderer.
- worldTime/worldDay ya se declaran antes del include core.glsl.
- No prueba de Minecraft, GPU, ni rendimiento automatica en este entorno.

## Probar en juego
Dia, amanecer, noche, cuatro planetas, sombra solar, agujero negro, nubes,
Distant Horizons y reinicio de dia. Validar FPS antes del commit.

## Proxima fase
Mover dependencias compartidas de atmosfera y estrellas de forma incremental,
no mover sky.glsl global sin auditar los pases que lo consumen.
