// Aurora Viva V25 Celestial Foundation — unchanged V24.1 code
vec3 av_planet_surface_classic(vec3 sky, vec3 ray, vec3 center, vec3 sunDir,
                       vec3 baseColor, float radius, float bands, float visibility,
                       float style, bool ringed) {
    if (visibility <= 0.001 || center.y < -0.095) return sky;
    float outerRadius = radius * (ringed ? 2.85 : 1.36);
    if (dot(ray, center) < cos(outerRadius)) return sky;

    vec3 tangentX = normalize(vec3(-center.z, 0.0, center.x));
    vec3 tangentY = cross(center, tangentX);
    vec2 p = vec2(dot(ray, tangentX), dot(ray, tangentY));
    float r = length(p);

    float horizonFade = smoothstep(-0.075, 0.105, center.y);
    visibility *= horizonFade;
    if (visibility < 0.001) return sky;

    float halo = av_mask(r, radius * 0.98, radius * 1.36) * (1.0 - av_mask(r, radius * 0.93, radius * 1.00));
    vec3 haloColor = baseColor;

    vec2 tiltP = vec2(0.0);
    float ringPresence = 0.0;
    if (ringed) {
        tiltP = vec2(p.x * 0.84 + p.y * 0.54, -p.x * 0.54 + p.y * 0.84);
        float e = length(vec2(tiltP.x / (radius * 2.55), tiltP.y / (radius * 0.62)));
        float ringOuter = smoothstep(0.48, 0.54, e) * (1.0 - smoothstep(0.99, 1.03, e));
        float ringGap = 1.0 - smoothstep(0.66, 0.71, e) * (1.0 - smoothstep(0.78, 0.83, e));
        float ringBands = 0.72 + 0.28 * sin(e * 56.0 + 0.8) * sin(e * 18.0 + 1.9);
        float backHalf = smoothstep(0.02, -0.07, tiltP.y);
        float frontHalf = smoothstep(-0.02, 0.07, tiltP.y);
        float ringLit = clamp(dot(-center, sunDir) * 0.58 + 0.50, 0.18, 1.0);
        vec3 ringColor = mix(vec3(0.42, 0.33, 0.25), vec3(0.86, 0.73, 0.55), ringLit);
        ringPresence = ringOuter * ringGap;
        sky = mix(sky, ringColor * ringBands * 0.72, clamp(ringPresence * visibility * backHalf * 0.72, 0.0, 0.95));
        sky = mix(sky, ringColor * ringBands * 0.95, clamp(ringPresence * visibility * frontHalf * 0.22 * (1.0 - smoothstep(0.0, radius * 0.96, r)), 0.0, 0.85));
        haloColor = mix(haloColor, vec3(0.96, 0.78, 0.56), 0.22);
    }

    sky += haloColor * halo * visibility * (0.12 + 0.10 * bands);

    float disc = av_mask(r, radius - 0.0017, radius + 0.0024);
    if (disc > 0.0001) {
        float x = clamp(p.x / radius, -1.0, 1.0);
        float y = clamp(p.y / radius, -1.0, 1.0);
        float z = sqrt(max(0.0, 1.0 - x*x - y*y));
        vec3 normal = normalize(tangentX * x + tangentY * y - center * z);

        float lightDot = dot(normal, sunDir);
        float phase = smoothstep(-0.30, 0.20, lightDot);
        float diffuse = max(lightDot, 0.0);
        float backscatter = pow(clamp(1.0 - max(lightDot, 0.0), 0.0, 1.0), 2.2);
        float rim = pow(1.0 - z, 2.7);

        float lon = atan(x, z + 1e-5);
        float lat = asin(clamp(y, -1.0, 1.0));
        float stripes = 0.5 + 0.5 * sin(lat * 18.0 + sin(lon * 4.0 + 0.5) * 1.8);
        float swirls  = 0.5 + 0.5 * sin(lon * 7.0 - lat * 10.5 + sin(lat * 5.0) * 1.4);
        float mottles = 0.5 + 0.5 * sin(lon * 12.0 + lat * 13.0 + sin(lon * 3.5) * 2.0);
        float craters = pow(max(0.0, sin(lon * 17.0 + 1.4) * sin(lat * 15.0 - 0.6)), 5.0);
        float veins   = pow(0.5 + 0.5 * sin(lon * 11.0 - lat * 19.0 + sin(lon * 5.0) * 1.2), 2.0);
        float storm = exp(-((lon - 0.55) * (lon - 0.55) * 10.0 + (lat + 0.18) * (lat + 0.18) * 42.0));

        vec3 color = baseColor;
        if (style < 0.5) {
            float bandMix = mix(stripes, swirls, 0.32);
            color *= mix(0.72, 1.24, bandMix);
            color += vec3(0.18, 0.11, 0.05) * storm * 0.22;
        } else if (style < 1.5) {
            float cloudMix = mix(stripes, swirls, 0.68);
            color *= mix(0.70, 1.22, cloudMix);
            color += vec3(0.10, 0.18, 0.24) * pow(1.0 - abs(y), 2.2) * 0.18;
            color += vec3(0.05, 0.12, 0.18) * veins * 0.10;
        } else if (style < 2.5) {
            color *= mix(0.72, 1.18, mottles);
            color += vec3(0.16, 0.05, 0.20) * veins * 0.28;
            color += vec3(0.07, 0.03, 0.10) * pow(1.0 - abs(y), 3.0) * 0.16;
        } else {
            color *= mix(0.68, 1.15, mottles);
            color -= vec3(0.14, 0.07, 0.03) * craters * 0.55;
            color += vec3(0.11, 0.05, 0.02) * swirls * 0.12;
        }

        float nightSide = mix(0.10, 1.0, phase);
        float diffuseTerm = 0.14 + diffuse * 0.88 + backscatter * 0.04;
        color *= diffuseTerm * nightSide;
        color += baseColor * rim * (0.07 + 0.13 * phase);
        color += baseColor * pow(clamp(1.0 - phase, 0.0, 1.0), 2.0) * rim * 0.10;

        if (ringed) {
            float shadowBand = exp(-pow(tiltP.y / (radius * 0.22), 2.0)) * smoothstep(0.16, 0.92, ringPresence);
            color *= 1.0 - shadowBand * 0.14;
        }

        sky = mix(sky, color, clamp(disc * visibility, 0.0, 0.995));
        sky += haloColor * rim * visibility * 0.018;
    }
    return sky;
}

// V24: restrained material and consistent solar lighting for all four planets.
// Classic visuals remain available through the Planet appearance setting.
vec3 av_planet_surface(vec3 sky, vec3 ray, vec3 center, vec3 sunDir,
                       vec3 baseColor, float radius, float bands, float visibility,
                       float style, bool ringed) {
    #if AV_PLANET_STYLE == 0
        return av_planet_surface_classic(sky, ray, center, sunDir,
                                        baseColor, radius, bands, visibility, style, ringed);
    #else
        if (visibility <= 0.0001 || center.y < -0.09) return sky;
        float influence = radius * (ringed ? 2.65 : 1.38);
        if (dot(ray, center) < cos(influence)) return sky;

        vec3 axisX = normalize(vec3(-center.z, 0.0, center.x));
        vec3 axisY = cross(center, axisX);
        vec2 p = vec2(dot(ray, axisX), dot(ray, axisY));
        float r = length(p);
        visibility *= smoothstep(-0.075, 0.105, center.y);
        visibility *= AV_PLANET_VISIBILITY;
        if (visibility < 0.0001) return sky;

        // Every body shares the same subtle atmospheric scattering model.
        float halo = exp(-pow((r - radius * 1.02) / max(radius * 0.19, 0.0005), 2.0));
        halo *= smoothstep(radius * 0.93, radius * 1.01, r);
        sky += baseColor * halo * visibility * AV_PLANET_ATMOSPHERE * 0.065;

        vec2 ringP = vec2(0.0);
        float ringOpacity = 0.0;
        float frontRing = 0.0;
        vec3 ringColor = vec3(0.0);
        if (ringed) {
            ringP = vec2(p.x * 0.84 + p.y * 0.54, -p.x * 0.54 + p.y * 0.84);
            float ellipse = length(vec2(ringP.x / (radius * 2.55), ringP.y / (radius * 0.64)));
            float outer = smoothstep(0.44, 0.50, ellipse) * (1.0 - smoothstep(0.94, 1.01, ellipse));
            float gap = 1.0 - 0.75 * smoothstep(0.66, 0.685, ellipse)
                                     * (1.0 - smoothstep(0.735, 0.76, ellipse));
            float dust = 0.81 + 0.12 * sin(ellipse * 64.0 + 0.7)
                              + 0.07 * sin(ellipse * 25.0 + 2.0);
            ringOpacity = outer * gap * clamp(dust, 0.56, 1.0) * visibility;
            frontRing = smoothstep(-0.012 * radius, 0.012 * radius, ringP.y);
            ringColor = mix(vec3(0.22, 0.16, 0.12), vec3(0.59, 0.43, 0.30),
                            clamp(0.48 + 0.52 * dot(-center, sunDir), 0.12, 1.0));
            sky = mix(sky, ringColor, clamp(ringOpacity * (1.0 - frontRing) * 0.65, 0.0, 0.85));
        }

        float disc = 1.0 - smoothstep(radius - 0.0014, radius + 0.0014, r);
        if (disc > 0.00001) {
            float x = clamp(p.x / radius, -1.0, 1.0);
            float y = clamp(p.y / radius, -1.0, 1.0);
            float z = sqrt(max(0.0, 1.0 - x*x - y*y));
            vec3 normal = normalize(axisX*x + axisY*y - center*z);

            float latitude = asin(clamp(y,-1.0,1.0));
            float longitude = atan(x, z + 0.0001);
            vec2 uv = vec2(longitude * 0.159155 + 0.5, latitude * 0.31831 + 0.5);
            float big = texture(noisetex, uv * vec2(2.5, 2.0) + vec2(0.17, 0.31)).r;
            float mid = texture(noisetex, uv * vec2(7.0, 5.0) + vec2(0.71, 0.23)).r;
            float fine = texture(noisetex, uv * vec2(17.0, 11.0) + vec2(0.45, 0.84)).r;
            vec3 material = baseColor;
            float polar = smoothstep(0.72, 0.98, abs(y));
            if (style < 0.5) {
                float stripes = 0.5 + 0.5 * sin(latitude * 19.0 + (big - 0.5) * 5.0
                                                   + (mid - 0.5) * 1.5);
                material *= mix(0.67, 1.23, stripes) * mix(0.91, 1.06, big);
                material = mix(material, vec3(0.56, 0.45, 0.38), polar * 0.18);
            } else if (style < 1.5) {
                float cloud = clamp(0.33 + 0.56*big + 0.22*mid, 0.0, 1.0);
                material *= mix(0.65, 1.13, cloud);
                material = mix(material, vec3(0.64, 0.68, 0.70), polar * 0.36);
            } else if (style < 2.5) {
                float minerals = clamp(0.35 + (big-0.5)*1.0 + (fine-0.5)*0.4, 0.0, 1.0);
                material *= mix(0.68, 1.12, minerals);
                material = mix(material, vec3(0.47, 0.42, 0.50), polar * 0.25);
            } else {
                float patches = clamp(0.46 + (big-0.5)*0.75 + (mid-0.5)*0.45, 0.0, 1.0);
                material *= mix(0.55, 1.19, patches);
                float craters = pow(max(0.0, fine - 0.64) * 2.0, 2.0);
                material *= 1.0 - craters * 0.20;
            }

            // Shared day/night terminator; dark hemisphere stays opaque, not transparent.
            float nl = dot(normal, normalize(sunDir));
            float lit = smoothstep(-0.09, 0.24, nl);
            float illumination = 0.065 + 0.89 * max(nl, 0.0);
            material *= illumination * mix(0.33, 1.0, lit);
            material += baseColor * pow(1.0 - z, 3.1) * lit
                        * AV_PLANET_ATMOSPHERE * 0.080;
            sky = mix(sky, material, clamp(disc * visibility, 0.0, 1.0));
        }
        if (ringed) {
            // Front of the ring occludes the globe, with no painted 'Saturn glow'.
            sky = mix(sky, ringColor, clamp(ringOpacity * frontRing * 0.73, 0.0, 0.86));
        }
        return sky;
    #endif
}


