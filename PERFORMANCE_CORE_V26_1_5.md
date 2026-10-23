# Aurora Viva V26.1.5 - Performance Core

**Base:** V26.1.3 MovimientoSuave (el mismo shader con el catálogo de 7.600 estrellas).

## Cambios

- `av_celestial_context_base()` reúne únicamente los datos que utiliza la atmósfera y la niebla sobre el terreno.
- `av_celestial_complete_sky()` conserva la **misma** interpolación sub-tick y dirección del Sol/Luna que en V26.1.3. Ahora se invoca solo en la rama de cielo visible (`Depth >= 1` y `PlayerPos.y > 0`).
- Se conserva la proyección del atlas, los planetas, el agujero negro, las nubes, los reflejos y las sombras.
- `Build-AuroraViva-V26.ps1` valida hash SHA256 del `deferred1.fsh` reconstruido e incrementa nombres `AuroraViva_V26_1_5_PerformanceCore_r001.zip`, `r002`, etc.

## Qué no promete

La GPU o el compilador GLSL pueden ya estar optimizando operaciones uniformes. Por eso esta modificación **no garantiza una mejora grande de FPS** y no corrige el salto de 8 a 9 chunks si su causa es geometría/driver. La prueba debe compararse con V26.1.3 en el mismo lugar, 8 chunks Vanilla y DH 64, con ajustes iguales.

## Validación

Se reconstruyó la V26.1.3 desde el origen modular y resultó idéntica byte a byte al ZIP funcional. Se comprobó que las fórmulas temporales y el orden de módulos quedan intactos. Se comprobó integridad y rutas internas con `/`. **No se ejecutó Minecraft ni PowerShell en Windows**.

## Rollback

El instalador acepta solo tres archivos de origen V26.1.3. Antes de sobrescribir, guarda copias en `%TEMP%`. No crea commit y no borra la versión anterior de Modrinth.
