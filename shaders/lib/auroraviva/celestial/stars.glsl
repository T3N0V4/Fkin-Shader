// Aurora Viva V26.1.2 - texture atlas star catalog, sparse and non-grid distribution
// Prebaked random spherical positions: one texture lookup, no per-pixel hashing.
#if defined(DIMENSION_OVERWORLD) && AV_LIVING_STARS == 1
uniform sampler2D avStarCatalog;
#endif

vec3 get_stars(vec3 PlayerPos, AVCelestialContext ctx) {
#if defined(DIMENSION_OVERWORLD) && AV_LIVING_STARS == 1
    // Early discard: do no extra work on daytime or below the horizon.
    if (ctx.night < 0.003) return vec3(0.0);
    vec3 ray = normalize(PlayerPos);
    if (ray.y <= 0.020) return vec3(0.0);

    // Sidereal rotation; stable across night/day, relaunch and sleep.
    float phase = AV_TAU * (ctx.dayPhase * 1.00072 + fract(ctx.dayIndex * 0.00072));
    float ca = cos(phase), sa = sin(phase);
    vec3 d = vec3(ray.x * ca - ray.z * sa, ray.y, ray.x * sa + ray.z * ca);
    vec3 a = abs(d);
    vec2 uvFace;
    vec2 tile;
    if (a.x >= a.y && a.x >= a.z) {
        uvFace = d.zy / a.x;
        tile = vec2(d.x >= 0.0 ? 0.0 : 1.0, 0.0);
    } else if (a.y >= a.z) {
        uvFace = d.xz / a.y;
        tile = vec2(d.y >= 0.0 ? 2.0 : 0.0, d.y >= 0.0 ? 0.0 : 1.0);
    } else {
        uvFace = d.xy / a.z;
        tile = vec2(d.z >= 0.0 ? 1.0 : 2.0, 1.0);
    }

    // Atlas of 6 square cube faces, no procedural grid / stripe artifacts.
    vec2 localUV = clamp(uvFace * 0.5 + 0.5, vec2(0.004), vec2(0.996));
    vec2 atlasUV = (tile + localUV) * vec2(1.0 / 3.0, 0.5);
    vec4 star = texture(avStarCatalog, atlasUV);
    float intensity = max(star.r, max(star.g, star.b));
    if (intensity <= 0.003) return vec3(0.0);

    // Alpha carries a random selection rank, so Star Density still works.
    float density = clamp(AV_STAR_DENSITY, 0.5, 1.5);
    float cutoff = mix(0.55, 0.045, density - 0.5);
    float keep = smoothstep(cutoff - 0.10, cutoff + 0.015, star.a);
    if (keep < 0.003) return vec3(0.0);

    // Costly twinkling math is done only where an actual star is visible.
    float twinkle = 1.0;
    if (AV_STAR_TWINKLE > 0.001) {
        float rate = 0.58 + star.a * 0.83;
        twinkle += AV_STAR_TWINKLE * 0.14 * sin(frameTimeCounter * rate + star.g * 6.28318);
    }
    vec3 col = mix(vec3(dot(star.rgb, vec3(0.2126, 0.7152, 0.0722))),
                   star.rgb, clamp(AV_STAR_VARIETY, 0.0, 1.0));
    float horizon = smoothstep(0.03, 0.19, ray.y);
    float moonFade = smoothstep(0.91, 0.995, dot(ray, ctx.moonDir));
    float visible = ctx.night * ctx.weather * horizon * (1.0 - 0.22 * moonFade);
    return col * (keep * visible * twinkle * STAR_STRENGTH * 1.35);
#else
    // Legacy V25 mode and The End remain unchanged.
    vec3 StarCoord = PlayerPos / (PlayerPos.y + length(PlayerPos.xz));
    StarCoord.x += frameTimeCounter * 0.001;
    const float ACTUAL_STAR_SIZE = STAR_SIZE * 512;
    StarCoord = floor(StarCoord * ACTUAL_STAR_SIZE) / ACTUAL_STAR_SIZE;
    float Visibility = smoothstep(0.0, 0.1, StarCoord.y);
    #ifdef DIMENSION_OVERWORLD
    Visibility *= ctx.night;
    #endif
    float legacy = max(0, random(StarCoord.xz) - 0.996) * 50 * Visibility * STAR_STRENGTH;
    return vec3(legacy);
#endif
}
