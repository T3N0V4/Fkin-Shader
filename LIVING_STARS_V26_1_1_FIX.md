# Aurora Viva V26.1.1 - Starfield Fix

## Problemas corregidos

- Patrón repetitivo en hileras de estrellas: la proyección sobre un solo plano se sustituyó por seis caras del cielo.
- Dispersión más aleatoria: cada estrella ocupa una posición variable dentro de su celda y se usa un hash sin senos para seleccionar las celdas.
- Trabajo de GPU: se descartan las celdas vacías antes de calcular el tamaño, bordes, color, Luna y parpadeo. Menos puntos totales por defecto.
- Se conservan las opciones Sky > Living Stars (AV_LIVING_STARS, AV_STAR_DENSITY, AV_STAR_VARIETY, AV_STAR_TWINKLE).
- El modo AV_LIVING_STARS=0 sigue usando las estrellas clásicas.

## Scope

Solo cambia `stars.glsl` y `Build-AuroraViva-V26.ps1`. No se alteran nubes, planetas, disco ni agujero negro.
El ZIP se genera con nombre único `AuroraViva_V26_1_1_StarfieldFix_rNNN.zip`.

## Comprobación pendiente dentro de Minecraft

Noche despejada: distribución sin líneas; movimiento entre días; FPS comparados en misma zona y configuración; Iris con valor clásico 0 y nuevo 1; sin errores de shader.
NOTA: la corrección es una optimización razonada del código, no una medición de FPS real.
