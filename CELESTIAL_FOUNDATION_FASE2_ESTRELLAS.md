# Aurora Viva V25 - phase 2.3: stars

The active `get_stars(vec3 PlayerPos)` was moved from `shaders/program/deferred1.fsh`
to `shaders/lib/auroraviva/celestial/stars.glsl`, with no formula changes.
The independent legacy `shaders/global/atmosphere/sky.glsl` is left intact.
The PowerShell builder expands atmosphere, stars, core, planets, blackhole and renderer
into the compiled deferred1 file, checks its SHA256 against V24.1 and emits a new
unique V25_3_Estrellas_rNNN.zip with forward-slash ZIP paths.

Pending: actual Iris/Minecraft night sky test and performance comparison.