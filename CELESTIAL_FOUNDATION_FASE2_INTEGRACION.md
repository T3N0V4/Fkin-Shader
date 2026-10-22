# Aurora Viva V25.5 - Integracion final Celestial Foundation

Base: V25.4, rama feature/celestial-foundation, T3N0V4/Fkin-Shader.

## Cambios acotados
- core.glsl: SIN CAMBIOS; AVCelestialContext ya existia.
- deferred1.fsh: declaraciones e include de core se mueven ANTES de los modulos
  atmosphere y stars para que el tipo GLSL este definido antes de su uso.
- main() crea UN contexto `skyContext` y lo comparte con get_sky_main,
  get_stars y av_mystical_celestials.
- atmosphere.glsl usa ctx.night y ctx.twilight (mismos calculos de V25.4).
- stars.glsl usa ctx.night; NO cambia generacion, velocidad ni coordenadas.
- renderer.glsl recibe ctx existente para planetas, sin repetir su calculo.
- blackhole.glsl, planets.glsl y los archivos de nubes: SIN CAMBIOS.
- shaders/global/atmosphere/sky.glsl (otros pases): SIN CAMBIOS.

## Alcance del contexto
- Las estrellas usan ctx.night en lugar de nightStrength directamente.
  Iris nightStrength normalmente esta en el rango [0,1], por lo que
  clamp(nightStrength,0,1) tiene el mismo resultado en ese rango.
- El contexto se calcula una vez al entrar en main() y se transmite a los
  modulos, incluso cuando posteriormente no se dibuja cielo. Si existe
  una regresion de FPS, revisar la colocacion del calculo compartido.

## Validaciones estaticas
- GLSL expandido esperado SHA256: ca14ff1ce029f29107fc59972bf3204a1c9c5dc6e97700da10db496ce57525b4
- Orden de definiciones: core antes de atmosphere y stars.
- Sin redefinicion de uniform worldTime/worldDay.
- Rutas del ZIP con '/', nombre versionado V25_5_Integracion_r001/r002/...
- Empaquetado corregido que no publica ni copia ZIP si falla validacion.

## Pruebas manuales antes del commit
- Iris: carga del ZIP, opciones y compilacion.
- Amanecer, mediodia, crepusculo y noche; comparar colores y estrellas.
- Planetas, BH, Distant Horizons, nubes, Nether/End.
- FPS vs V25.4 en misma posicion y ajustes.

## Siguiente paso
2.6: validacion, commit y tag de Celestial Foundation.
