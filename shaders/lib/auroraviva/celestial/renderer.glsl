// Aurora Viva V25 Celestial Foundation — unchanged V24.1 code
vec3 av_mystical_celestials(vec3 sky, vec3 ray) {
    if (ray.y < -0.003) return sky;

    // Shared day, weather and solar geometry. Equivalent to V25.3 expressions.
    AVCelestialContext ctx = av_celestial_context();
    float dayPhase = ctx.dayPhase;
    float days = ctx.dayIndex;
    float visibility = ctx.visibility;
    vec3 sunDir = ctx.sunDir;

    // V24 atmosphere tint is applied once inside get_sky().

    vec3 gold = av_orbital_direction(AV_TAU * (dayPhase + 0.50 + days * 0.004), 0.24, 0.16);
    vec3 blue = av_orbital_direction(AV_TAU * (dayPhase + 0.28 + days * 0.019), 2.10, -0.24);
    vec3 purple = av_orbital_direction(AV_TAU * (dayPhase + 0.68 - days * 0.011), 3.95, 0.30);
    vec3 red = av_orbital_direction(AV_TAU * (dayPhase + 0.12 + days * 0.031), 5.20, -0.18);

    float goldGlare = 1.0 - smoothstep(0.66, 0.985, dot(gold, sunDir));
    float blueGlare = 1.0 - smoothstep(0.66, 0.985, dot(blue, sunDir));
    float purpleGlare = 1.0 - smoothstep(0.66, 0.985, dot(purple, sunDir));
    float redGlare = 1.0 - smoothstep(0.66, 0.985, dot(red, sunDir));

    sky = av_planet_surface(sky, ray, gold, sunDir, vec3(0.68, 0.51, 0.33),
                           0.058, 0.09, visibility * goldGlare, 0.0, true);
    sky = av_planet_surface(sky, ray, blue, sunDir, vec3(0.36, 0.53, 0.63),
                           0.064, 0.08, visibility * blueGlare, 1.0, false);
    sky = av_planet_surface(sky, ray, purple, sunDir, vec3(0.52, 0.42, 0.56),
                           0.050, 0.07, visibility * purpleGlare, 2.0, false);
    sky = av_planet_surface(sky, ray, red, sunDir, vec3(0.66, 0.37, 0.28),
                           0.040, 0.10, visibility * redGlare, 3.0, false);

    return sky;
}
// END AURORA VIVA - BLACK HOLE V7
