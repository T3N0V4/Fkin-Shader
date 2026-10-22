// Aurora Viva V26.1.7 - original atmosphere interpolation.
// A single radiance palette for skies, fog, and water reflections.
#ifndef AV_ATMOSPHERE_GRADIENT
#define AV_ATMOSPHERE_GRADIENT
vec3 av_atmosphere_gradient(vec3 viewDir, vec3 sunGlare) {
    float elevation = clamp(dot(normalize(viewDir), normalize(gbufferModelView[1].xyz)), -1.0, 1.0);
    float above = max(elevation, 0.0);
    float horizon = exp(-abs(elevation) * 7.0);
    float middle = exp(-above * 2.4);
    // Three continuously joined regions, no flat cutoff or fixed-height texture.
    vec3 midColor = mix(SKY_TOP, SKY_GROUND, 0.62);
    vec3 sky = mix(SKY_TOP, midColor, middle * 0.69);
    sky = mix(sky, SKY_GROUND + sunGlare, horizon * 0.84);

    // Physically motivated direction weighting: sunsets brighten mostly near
    // the solar azimuth and at low elevations; clouds/fog share this radiance.
    float towardSun = max(dot(normalize(viewDir), normalize(sunPosN)), 0.0);
    float sunElevation = abs(dot(normalize(sunPosN), normalize(gbufferModelView[1].xyz)));
    float grazing = exp(-sunElevation * 7.0);
    float twilight = clamp(sunriseStrength + sunsetStrength, 0.0, 1.0);
    float rainAttenuation = 1.0 - 0.65 * clamp(rainStrength, 0.0, 1.0);
    vec3 warmScatter = vec3(0.019, 0.007, 0.003) *
        twilight * grazing * (0.22 + 0.78 * towardSun * towardSun * towardSun) *
        horizon * rainAttenuation;
    sky += warmScatter;

    // Below the mathematical horizon transition smoothly into atmospheric fog.
    // This is not the DH terrain fade; it is the *same* sky color seen behind it.
    float below = clamp(-elevation * 4.0, 0.0, 1.0);
    sky = mix(sky, SKY_GROUND + sunGlare * 0.35, below * 0.72);
    return max(sky, vec3(0.0));
}
#endif
