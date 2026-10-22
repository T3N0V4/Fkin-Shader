// Aurora Viva V25 Celestial Foundation — unchanged V24.1 code
// AURORA VIVA - BLACK HOLE V7
// Keeps the celestial cycles and upgraded planets from V6, and adds a configurable
// black hole with a luminous accretion disk intended as groundwork for future events.
const float AV_TAU = 6.28318530718;

vec3 av_orbital_direction(float angle, float node, float tilt) {
    float ca = cos(angle), sa = sin(angle);
    float cn = cos(node), sn = sin(node), ct = cos(tilt), st = sin(tilt);
    return normalize(vec3(ca * cn - sa * st * sn, sa * ct, ca * sn + sa * st * cn));
}

float av_mask(float r, float edge0, float edge1) {
    return 1.0 - smoothstep(edge0, edge1, r);
}

// V25.4: shared observational state for the celestial renderer.
// Coordinates are WORLD-space; atmosphere still uses view-space sunPosN.
// The old source expressions are preserved to avoid visual drift.
struct AVCelestialContext {
    float dayPhase;
    float dayIndex;
    float twilight;
    float weather;
    float night;
    float day;
    float visibility;
    vec3 sunDir;
    vec3 moonDir;
};

// V26.1.5 Performance Core: atmosphere/fog requires only a cheap context.
// Do not evaluate the orbital interpolation and world-space sun direction
// for every terrain/water pixel. Complete them only for visible sky pixels.
AVCelestialContext av_celestial_context_base() {
    AVCelestialContext c;
    c.dayPhase = float(worldTime) / 24000.0;
    c.dayIndex = float(worldDay);
    c.twilight = clamp(sunriseStrength + sunsetStrength, 0.0, 1.0);
    c.weather = 1.0 - rainStrength * 0.84;
    c.night = clamp(nightStrength, 0.0, 1.0);
    c.day = clamp(dayStrength, 0.0, 1.0);
    c.visibility = clamp(0.15 * c.day + 0.88 * c.twilight + c.night, 0.0, 1.0) * c.weather;
    c.sunDir = vec3(0.0);
    c.moonDir = vec3(0.0);
    return c;
}

// SAME math as V26.1.3, moved to the sky-only branch.
void av_celestial_complete_sky(inout AVCelestialContext c) {
#if defined(DIMENSION_OVERWORLD) && AV_CELESTIAL_SMOOTH_TIME == 1
    float rawCycle = fract(c.dayPhase - 0.25);
    float cosAngle = cos(rawCycle * 3.141592653589793);
    float expectedSunAngle = fract((2.0 / 3.0) * rawCycle +
                                  (1.0 - cosAngle) / 6.0 + 0.25);
    float angleDiff = fract(sunAngle - expectedSunAngle + 0.5) - 0.5;
    float slope = (2.0 / 3.0) + (3.141592653589793 / 6.0) *
                  sin(rawCycle * 3.141592653589793);
    float fractionOfTick = clamp(angleDiff * 24000.0 / max(slope, 0.01), 0.0, 1.0);
    c.dayPhase += fractionOfTick / 24000.0;
#endif
    c.sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosN);
    c.moonDir = -c.sunDir;
}

