// Aurora Viva V25 Fase 2 - atmosphere extraction, logic unchanged
vec3 get_sky(vec3 ViewPosN, vec3 SunGlare, AVCelestialContext ctx) {
    vec3 baseColor = av_atmosphere_gradient(ViewPosN, SunGlare);

    #ifdef DIMENSION_OVERWORLD
        // V24. Atmospheric depth only; stars, clouds and moon geometry remain untouched.
        float night = ctx.night;
        float altitude = clamp(dot(ViewPosN, gbufferModelView[1].xyz), 0.0, 1.0);
        float horizon = exp(-altitude * 5.0);
        float zenith = smoothstep(0.14, 0.93, altitude);
        float depth = night * AV_NIGHT_SKY_DEPTH;
        float weather = 1.0 - rainStrength * 0.70;

        // Deep indigo zenith, soft blue/violet airglow near horizon.
        baseColor *= 1.0 - clamp(depth * (0.035 + 0.095 * zenith), 0.0, 0.24);
        baseColor += vec3(0.0010, 0.0019, 0.0050) * zenith * depth * weather;
        baseColor += vec3(0.0075, 0.0080, 0.0130) * horizon
                     * night * AV_NIGHT_HORIZON_GLOW * weather;

        // Moonlight scattered through the air: not an extra moon or a painted ring.
        vec3 moonRay = -normalize(sunPosN);
        float moonScatter = pow(max(dot(ViewPosN, moonRay), 0.0), 22.0);
        float broadScatter = pow(max(dot(ViewPosN, moonRay), 0.0), 4.0);
        baseColor += vec3(0.008, 0.012, 0.021) * moonScatter
                     * night * depth * (1.0 - rainStrength * 0.80);
        baseColor += vec3(0.0011, 0.0022, 0.0040) * broadScatter
                     * night * depth * weather;

        // Twilight retains Aurora Viva's warmth, with a restrained violet horizon.
        float twilight = ctx.twilight;
        baseColor += vec3(0.0065, 0.0037, 0.0075) * horizon * twilight
                     * AV_NIGHT_HORIZON_GLOW * weather;
    #endif
    return max(baseColor, vec3(0.0));
}
