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

AVCelestialContext av_celestial_context() {
    AVCelestialContext c;
    c.dayPhase = float(worldTime) / 24000.0;
    c.dayIndex = float(worldDay);
    c.twilight = clamp(sunriseStrength + sunsetStrength, 0.0, 1.0);
    c.weather = 1.0 - rainStrength * 0.84;
    c.night = clamp(nightStrength, 0.0, 1.0);
    c.day = clamp(dayStrength, 0.0, 1.0);
    c.visibility = clamp(0.15 * c.day + 0.88 * c.twilight + c.night, 0.0, 1.0) * c.weather;
    c.sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosN);
    c.moonDir = -c.sunDir;
    return c;
}

