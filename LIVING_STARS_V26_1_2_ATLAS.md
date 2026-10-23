# Aurora Viva V26.1.2 - Atlas estelar optimizado

## Objetivo
Reducir GPU por pixel: se reemplaza la seleccion procedural de estrellas por UNA muestra a un atlas 3x2 de seis caras celestes.
El catalogo se genera fuera del juego con posiciones aleatorias uniformes sobre una esfera; no forma lineas o cuadrillas. Su distribucion se mantiene entre noches.

## Archivos modificados
- shaders/lib/auroraviva/celestial/stars.glsl
- shaders/shaders.properties
- shaders/img/auroraviva_star_catalog_v26.png (+ .mcmeta)
- Build-AuroraViva-V26.ps1

## Rendimiento
Una sola muestra de textura por pixel visible nocturno, contra varios hashes, fwidth, sin/aleatoriedad por pixel.
El atlas RGBA (3072x2048) ocupa aprox. 24 MiB de memoria descomprimida; RX 6800 XT tiene 16 GB VRAM.
NO prometemos subida de FPS sin medir: nubes, sombras y agujero negro pueden ser mas costosos.

## Opciones
AV_LIVING_STARS=0 mantiene las estrellas originales de V25.
STAR_SIZE: se aplica al modo clasico; el tamano del atlas esta prefijado, evita recalculos de detalle en cada pixel.
AV_STAR_DENSITY, AV_STAR_VARIETY y AV_STAR_TWINKLE siguen utilizandose.

## Validacion
Comparar exactamente misma vista y tiempo nocturno con Living Stars 0 y 1; FPS estable y 1% low.
Comprobar carga de customTexture en latest.log y ausencia de errores por texturas faltantes.
No crear tag ni commit hasta comprobar en Minecraft.
