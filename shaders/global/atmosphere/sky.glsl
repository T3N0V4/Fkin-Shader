#include "/lib/auroraviva/atmosphere/gradient.glsl"
float fogify(float x, float w) {
    return w / (x * x + w);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}




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


#if AV_BH_CURVED_DISK == 0
vec3 av_black_hole_legacy(vec3 sky, vec3 ray, vec3 center, float visibility) {
    #ifdef AV_BLACK_HOLE
        if (visibility <= 0.001 || center.y < -0.095) return sky;
        float radius = AV_BLACK_HOLE_SIZE;
        float outerRadius = radius * 3.95 * AV_BLACK_HOLE_HALO_SOFTNESS;
        if (dot(ray, center) < cos(outerRadius)) return sky;

        vec3 tangentX = normalize(vec3(-center.z, 0.0, center.x));
        vec3 tangentY = cross(center, tangentX);
        vec2 p = vec2(dot(ray, tangentX), dot(ray, tangentY));
        float r = length(p);
        float q = r / radius;
        visibility *= smoothstep(-0.075, 0.105, center.y);
        if (visibility <= 0.001) return sky;

        vec2 diskP = vec2(p.x * 0.90 + p.y * 0.44, -p.x * 0.44 + p.y * 0.90);
        vec2 diskPlane = vec2(diskP.x / (radius * 3.08), diskP.y / (radius * (0.77 / AV_BLACK_HOLE_DISK_THICKNESS)));
        float e = length(diskPlane);
        float angle = atan(diskPlane.y, diskPlane.x);
        float diskMask = smoothstep(0.25, 0.39, e) * (1.0 - smoothstep(0.87, 1.05, e));
        float frontSide = smoothstep(-0.09, 0.08, diskP.y);
        float backSide = 1.0 - frontSide;
        float t = frameTimeCounter;

        float innerShadow = exp(-pow((q - 1.00) / 0.16, 2.0));
        float lensShadow  = exp(-pow((q - 1.28) / 0.34, 2.0));
        sky *= 1.0 - visibility * AV_BLACK_HOLE_LENS_DARKENING * (innerShadow * 0.17 + lensShadow * 0.05);

        float spin = t * (0.0062 + 0.0014 * AV_BLACK_HOLE_GAS_DETAIL) / (0.18 + e * e);
        vec2 orbit = vec2(cos(angle - spin), sin(angle - spin)) * e;
        float broad = texture(noisetex, orbit * 0.20 + vec2(0.271, 0.437)).r;
        vec2 warp = vec2(broad - 0.5, 0.5 - broad) * 0.13;
        float mid  = texture(noisetex, (orbit + warp) * 0.78 + vec2(0.593, 0.137)).r;
        float fine = texture(noisetex, (orbit - warp * 0.45) * 2.35 + vec2(0.127, 0.725)).r;
        float wisps = texture(noisetex, (orbit + vec2(mid - 0.5, broad - 0.5) * 0.25) * 4.6 + vec2(0.811, 0.311)).r;

        float density = clamp(0.52 + (broad - 0.5) * 1.15 + (mid - 0.5) * 0.88 + (fine - 0.5) * 0.42, 0.08, 1.10);
        float laneField = smoothstep(0.54, 0.91, 1.0 - mid) * (1.0 - smoothstep(0.82, 1.01, e));
        float wispField = smoothstep(0.56, 0.94, wisps);
        float heat = 1.0 - smoothstep(0.28, 1.00, e);

        vec3 soot   = vec3(0.17, 0.10, 0.09);
        vec3 copper = vec3(0.55, 0.29, 0.17);
        vec3 amber  = vec3(0.92, 0.60, 0.34);
        vec3 pearl  = vec3(1.00, 0.89, 0.72);
        vec3 gasColor = mix(copper, amber, smoothstep(0.10, 0.93, heat));
        gasColor = mix(gasColor, pearl, pow(heat, 3.2) * 0.34 + wispField * 0.08);
        gasColor = mix(gasColor, soot, laneField * 0.34 + (1.0 - density) * 0.30);

        float beaming = clamp(0.82 - 0.26 * diskPlane.x / max(e, 0.0001), 0.48, 1.14);
        gasColor *= beaming * (0.76 + density * 0.34);

        // Main volumetric disk.
        float volumeAccum = 0.0;
        vec3  volumeColor = vec3(0.0);
        for (int i = 0; i < 5; ++i) {
            float layer = (float(i) - 2.0) / 2.0;
            float layerY = diskPlane.y + layer * 0.16 * AV_BLACK_HOLE_DISK_THICKNESS;
            float layerR = length(vec2(diskPlane.x, layerY));
            float layerMask = smoothstep(0.22, 0.38, layerR) * (1.0 - smoothstep(0.88, 1.06, layerR));
            float falloff = exp(-abs(layer) * 1.25);
            float swirl = texture(noisetex, (vec2(cos(angle - spin * (1.0 + layer * 0.12)), sin(angle - spin * (1.0 + layer * 0.12))) * layerR + warp * (0.65 + layer * 0.08)) * (1.15 + abs(layer) * 0.55) + vec2(0.13 * float(i), 0.21)).r;
            float localDensity = clamp(density * 0.72 + (swirl - 0.5) * 0.65 + falloff * 0.20, 0.0, 1.15);
            float op = layerMask * localDensity * falloff;
            vec3 localColor = mix(gasColor * 0.78, gasColor * (1.04 + 0.08 * layer), 0.56 + 0.18 * localDensity);
            localColor = mix(localColor, pearl, smoothstep(0.74, 1.05, localDensity) * heat * 0.18);
            volumeColor += localColor * op;
            volumeAccum += op;
        }
        if (volumeAccum > 0.0001) volumeColor /= volumeAccum;
        float gasOpacity = clamp(diskMask * visibility * (0.64 + 0.24 * density + 0.12 * volumeAccum), 0.0, 0.96);

        // Extra far-side curvature: a faint mirrored disk produced by bent light, not hard flares.
        float farAccum = 0.0;
        vec3  farColor = vec3(0.0);
        if (backSide > 0.001) {
            for (int j = 0; j < 2; ++j) {
                float sgn = j == 0 ? -1.0 : 1.0;
                for (int i = 0; i < 3; ++i) {
                    float layer = (float(i) - 1.0);
                    float bend = (0.18 + 0.20 / (0.40 + abs(diskPlane.x))) * AV_BLACK_HOLE_FARSIDE_CURVE;
                    float yWarp = sgn * (bend + abs(diskPlane.y) * 1.65 + layer * 0.10 * AV_BLACK_HOLE_DISK_THICKNESS);
                    float xWarp = diskPlane.x * (0.86 + 0.04 * abs(layer));
                    float rWarp = length(vec2(xWarp, yWarp));
                    float mask = smoothstep(0.20, 0.34, rWarp) * (1.0 - smoothstep(0.76, 0.98, rWarp));
                    mask *= (1.0 - smoothstep(0.90, 1.12, q)); // strongest close to the hole
                    float swirl = texture(noisetex, (vec2(cos(angle - spin * 1.15 + float(i)*0.15), sin(angle - spin * 1.15 + float(i)*0.15)) * rWarp + warp * 0.55) * 1.35 + vec2(0.22 * float(j), 0.18 * float(i))).r;
                    float ld = clamp(0.48 + (swirl - 0.5) * 0.70 + (mid - 0.5) * 0.25, 0.0, 1.0);
                    float op = mask * ld * exp(-abs(layer) * 0.9);
                    vec3 localColor = mix(gasColor * 0.74, mix(gasColor, pearl, 0.18), 0.50 + 0.18 * ld);
                    farColor += localColor * op;
                    farAccum += op;
                }
            }
        }
        if (farAccum > 0.0001) farColor /= farAccum;

        // Give the central shadow more depth so it doesn't read like a flat black disc.
        float eventHorizon = 1.0 - smoothstep(0.880, 0.996, q);
        float deepCore = 1.0 - smoothstep(0.56, 0.86, q);
        float shadowShell = exp(-pow((q - 0.97) / 0.085, 2.0));
        float captureShell = exp(-pow((q - 1.06) / 0.13, 2.0));
        float sideLight = clamp(0.56 - 0.26 * diskPlane.x / max(e, 0.0001), 0.20, 0.92);
        float verticalLift = clamp(0.60 + 0.40 * (0.5 + 0.5 * diskPlane.y / max(e, 0.0001)), 0.55, 1.0);
        vec3 coreColor = vec3(0.00004, 0.00006, 0.00012);
        vec3 edgeCool = vec3(0.010, 0.013, 0.020);
        vec3 edgeWarm = vec3(0.019, 0.014, 0.010);
        vec3 shadowColor = mix(coreColor, mix(edgeCool, edgeWarm, sideLight), pow(clamp(q, 0.0, 1.0), 1.85));
        shadowColor *= mix(0.86, 1.03, verticalLift);
        float horizonOpacity = clamp((eventHorizon * 1.35 + shadowShell * 0.22) * visibility * AV_BLACK_HOLE_SHADOW_DEPTH, 0.0, 1.0);
        sky = mix(sky, shadowColor, horizonOpacity);
        sky *= 1.0 - captureShell * visibility * 0.020 * AV_BLACK_HOLE_SHADOW_DEPTH;
        sky *= 1.0 - deepCore * visibility * 0.035 * AV_BLACK_HOLE_SHADOW_DEPTH;

        float backOpacity = clamp(gasOpacity * backSide * 0.52, 0.0, 0.56);
        sky = mix(sky, volumeColor * 0.83, backOpacity);

        float farOpacity = clamp(farAccum * visibility * backSide * 0.22, 0.0, 0.18);
        sky = mix(sky, farColor, farOpacity);

        float photonRing = exp(-pow((q - 1.054) / 0.050, 2.0));
        float contactRim = exp(-pow((q - 1.00) / 0.060, 2.0));
        float innerHalo  = exp(-pow((q - 1.14) / (0.18 * AV_BLACK_HOLE_HALO_SOFTNESS), 2.0));
        float outerHalo  = exp(-pow((q - 1.44) / (0.52 * AV_BLACK_HOLE_HALO_SOFTNESS), 2.0));
        float rimAsym = clamp(0.73 - 0.18 * diskPlane.x / max(e, 0.0001), 0.52, 0.96);
        vec3 rimColor = mix(vec3(0.68, 0.52, 0.36), vec3(0.96, 0.86, 0.73), 0.40 + heat * 0.10);
        float pulse = 0.988 + 0.012 * sin(t * 0.09 + broad * 3.0);
        sky += rimColor * photonRing * rimAsym * visibility * AV_BLACK_HOLE_GLOW * 0.10 * pulse;
        sky += mix(vec3(0.12, 0.15, 0.22), vec3(0.26, 0.22, 0.18), sideLight) * contactRim * visibility * 0.030 * AV_BLACK_HOLE_SHADOW_DEPTH;
        sky += mix(vec3(0.28, 0.33, 0.44), vec3(0.68, 0.43, 0.29), 0.44 + heat * 0.18)
               * visibility * AV_BLACK_HOLE_GLOW * pulse
               * (innerHalo * 0.020 + outerHalo * 0.007);

        float outsideHorizon = smoothstep(1.00, 1.12, q);
        float frontOpacity = clamp(gasOpacity * frontSide * 0.86 * outsideHorizon, 0.0, 0.90);
        sky = mix(sky, volumeColor, frontOpacity);
    #endif
    return sky;
}


#endif // AV_BH_CURVED_DISK == 0



// V21 - denser disk structure: thinner profile, clearer bands and streaks,
// and stronger asymmetry so the accretion flow feels more alive.
// Aurora Viva V24.1 - Bounded shear and seamless texture renewal.
// The previous differential rotation accumulated unbounded angular shear
// with frameTimeCounter. Two phase-offset material fields are crossfaded,
// always hiding the wrap of the renewing field. This avoids radial grid lines
// after long sessions, while preserving a moving flow and the V24 sky.
#if AV_BH_CURVED_DISK == 1
vec4 av_bh_flow_material(float orbitPhi, float orbitRadius, float sampleTime, float turbulence) {
    float flowVelocity = 0.085 / (0.30 + 0.095 * pow(orbitRadius, 1.30));
    // Keep phase bounded for stable sine/cosine at long playtimes.
    float phi = mod(orbitPhi - sampleTime * flowVelocity, 6.28318530718);
    vec2 orbitUV = vec2(cos(phi), sin(phi)) * orbitRadius;
    float broad = texture(noisetex, orbitUV * 0.071 + vec2(0.271, 0.437)).r;
    float eddyAngle = (broad - 0.5) * 0.48 * turbulence;
    vec2 eddyUV = vec2(cos(phi + eddyAngle), sin(phi + eddyAngle)) * orbitRadius;
    float mid = texture(noisetex, eddyUV * 0.26 + vec2(0.593, 0.137)).r;
    float fine = texture(noisetex, (eddyUV + vec2(mid - 0.5, broad - 0.5)
                     * (0.30 * turbulence)) * 0.82 + vec2(0.127, 0.725)).r;
    float filamentA = 0.5 + 0.5 * sin(phi * 7.0 + orbitRadius * 2.7
                      + (broad - 0.5) * 1.4 * turbulence);
    float filamentB = 0.5 + 0.5 * sin(phi * 13.0 - orbitRadius * 1.6
                      + (mid - 0.5) * 1.6 * turbulence);
    return vec4(broad, mid, fine, mix(filamentA, filamentB, 0.45));
}
#endif

vec3 av_black_hole(vec3 sky, vec3 ray, vec3 center, float visibility) {
    #ifdef AV_BLACK_HOLE
        #if AV_BH_CURVED_DISK == 0
            return av_black_hole_legacy(sky, ray, center, visibility);
        #else
            if (visibility <= 0.001 || center.y < -0.095) return sky;
            float radius = AV_BLACK_HOLE_SIZE;
            float cosAngle = dot(ray, center);
            if (cosAngle < cos(radius * 3.75)) return sky;

            vec3 axisX = normalize(vec3(-center.z, 0.0, center.x));
            vec3 axisY = cross(center, axisX);
            vec3 viewRay = normalize(vec3(dot(ray, axisX), dot(ray, axisY), cosAngle));
            float nightFade = visibility * smoothstep(-0.075, 0.105, center.y);
            if (nightFade <= 0.001) return sky;

            vec3 diskNormal = normalize(vec3(-0.44 * 0.968, 0.90 * 0.968, 0.25));
            vec3 diskRight  = normalize(vec3(0.90, 0.44, 0.0));
            vec3 diskUp     = normalize(cross(diskNormal, diskRight));

            const float CAMERA_DISTANCE = 29.0;
            const float RS = 0.70;
            vec3 pos = vec3(0.0, 0.0, -CAMERA_DISTANCE);
            vec3 vel = viewRay;
            float impact2 = CAMERA_DISTANCE * CAMERA_DISTANCE * dot(viewRay.xy, viewRay.xy);
            float opticalDepth = 0.0;
            vec3 radiance = vec3(0.0);
            float throughput = 1.0;
            bool swallowed = false;
            // V23: advection of a real rotating flow, not a global light pulse.
            // Faster at the inner radius; farther gas travels more slowly.
            float flowTime = frameTimeCounter * AV_BH_FLOW_SPEED;

            for (int step = 0; step < AV_BH_TRACE_QUALITY; ++step) {
                float dist = length(pos);
                float ds = clamp(dist * 0.14, 0.11, 0.80);
                vec3 prev = pos;
                float prevHeight = dot(prev, diskNormal);
                float invR5 = 1.0 / max(dist * dist * dist * dist * dist, 0.0001);
                vec3 force = -1.5 * RS * impact2 * invR5 * pos;
                force -= vel * dot(vel, force);
                vel = normalize(vel + force * ds);
                pos += vel * ds;
                dist = length(pos);

                if (dist < RS) { swallowed = true; break; }
                float height = dot(pos, diskNormal);
                float slope = abs(dot(vel, diskNormal));
                float thickness = 0.17 * AV_BLACK_HOLE_DISK_THICKNESS;
                float proximity = thickness + 0.44 * ds * slope;
                if (min(abs(prevHeight), abs(height)) < proximity || prevHeight * height < 0.0) {
                    float segmentDenom = prevHeight - height;
                    float u = abs(segmentDenom) > 0.0001 ? clamp(prevHeight / segmentDenom, 0.0, 1.0) : 0.5;
                    vec3 spot = mix(prev, pos, u);
                    float planeHeight = dot(spot, diskNormal);
                    spot -= diskNormal * planeHeight;
                    float orbitRadius = length(spot);
                    if (orbitRadius > 2.05 && orbitRadius < 9.00) {
                        float radialMask = smoothstep(2.15, 2.70, orbitRadius)
                                         * (1.0 - smoothstep(7.9, 8.95, orbitRadius));
                        vec2 flatPos = vec2(dot(spot, diskRight), dot(spot, diskUp));
                        float orbitPhi = atan(flatPos.y, flatPos.x);
                        // V24.1: keep differential flow but never wind the texture
                        // indefinitely. Two 36-second-offset material fields fade
                        // through a 72-second cycle, hiding each restart at zero
                        // weight. Night/day changes do not accumulate deformation.
                        vec4 gasField;
                        #if AV_BH_FLOW_STABILITY == 1
                            const float AV_BH_CYCLE = 72.0;
                            float phaseA = mod(flowTime, AV_BH_CYCLE);
                            float phaseB = mod(flowTime + 0.5 * AV_BH_CYCLE, AV_BH_CYCLE);
                            float blendA = sin(3.14159265359 * phaseA / AV_BH_CYCLE);
                            blendA *= blendA;
                            vec4 fieldA = av_bh_flow_material(orbitPhi, orbitRadius, phaseA, AV_BH_TURBULENCE);
                            vec4 fieldB = av_bh_flow_material(orbitPhi, orbitRadius, phaseB, AV_BH_TURBULENCE);
                            gasField = mix(fieldB, fieldA, blendA);
                        #else
                            gasField = av_bh_flow_material(orbitPhi, orbitRadius, flowTime, AV_BH_TURBULENCE);
                        #endif
                        float broad = gasField.x;
                        float mid = gasField.y;
                        float fine = gasField.z;
                        float streaks = gasField.w;
                        float bandInner = exp(-pow((orbitRadius - 2.85) / 0.62, 2.0));
                        float bandMid   = exp(-pow((orbitRadius - 4.35) / 1.05, 2.0));
                        float bandOuter = exp(-pow((orbitRadius - 6.55) / 1.55, 2.0));
                        float lane = clamp(0.72 + (streaks - 0.5) * (0.75 + 0.17 * AV_BH_TURBULENCE)
                                           + (fine - 0.5) * (0.32 + 0.12 * AV_BH_TURBULENCE), 0.22, 1.38);
                        float density = clamp((0.54 + AV_BLACK_HOLE_GAS_DETAIL *
                                              (0.62 * (broad - 0.5) + 0.42 * (mid - 0.5)
                                               + 0.18 * (fine - 0.5))) * lane, 0.06, 1.22);
                        float heat = clamp((8.7 - orbitRadius) / 6.4, 0.0, 1.0);
                        vec3 soot   = vec3(0.20, 0.11, 0.10);
                        vec3 copper = vec3(0.55, 0.29, 0.17);
                        vec3 amber  = vec3(0.92, 0.60, 0.35);
                        vec3 ivory  = vec3(1.00, 0.87, 0.68);
                        // V22: spot is the physically sampled hit on the inclined disk.
                        // Camera starts at negative Z. Back-side samples naturally arrive
                        // later along the bent ray and are attenuated by near-side gas.
                        float backFraction = smoothstep(-0.85, 0.85, spot.z);
                        float frontFraction = 1.0 - backFraction;
                        float sideStrength = AV_BH_FRONT_BACK_SEPARATION;

                        vec3 gas = mix(copper, amber, smoothstep(0.08, 0.92, heat));
                        gas = mix(gas, ivory, pow(heat, 3.4) * 0.22 + bandInner * 0.20 + bandMid * 0.10);
                        gas = mix(gas, soot, (1.0 - density) * 0.46 + (1.0 - lane) * 0.18);
                        float albedo = clamp(0.78 + bandInner * 0.38 + bandMid * 0.16 - bandOuter * 0.12, 0.55, 1.34);
                        gas *= albedo;
                        // Gravitational redshift: inner gas emits a little less visible
                        // energy; far-side gas is subtly cooler, not a separate colored arc.
                        float gravityRedshift = sqrt(max(0.06, 1.0 - RS / max(orbitRadius, RS + 0.05)));
                        gas *= mix(1.0, gravityRedshift, 0.22);
                        vec3 farSideTint = gas * vec3(0.91, 0.94, 1.03);
                        gas = mix(gas, farSideTint, backFraction * sideStrength * 0.28);

                        vec3 spinDir = normalize(cross(diskNormal, spot));
                        float doppler = dot(spinDir, -vel);
                        float beam = pow(clamp(1.0 + 0.42 * doppler, 0.50, 1.58), 2.3);
                        gas *= beam * (0.74 + 0.30 * density);

                        // Actual line-of-sight layering: the nearer stream is a little
                        // thicker and absorbs the farther stream. The far stream stays
                        // thinner and less luminous, so its gravitationally lifted
                        // image is visibly behind the foreground flow.
                        float thicknessScale = 1.0 + sideStrength *
                                              (0.08 * frontFraction - 0.22 * backFraction);
                        float localThickness = max(thickness * mix(1.0, 0.82, bandInner)
                                                   * thicknessScale, 0.045);
                        float fade = exp(-pow(planeHeight / localThickness, 2.0));
                        float opticalScale = 1.0 + sideStrength *
                                             (0.17 * frontFraction - 0.23 * backFraction);
                        float absorb = radialMask * fade * density
                                     * mix(1.40, 1.12, bandOuter) * mix(0.92, 1.18, bandInner)
                                     * opticalScale * ds / max(slope, 0.18);
                        float alpha = 1.0 - exp(-absorb);
                        alpha = clamp(alpha, 0.0, 0.80);
                        vec3 emissive = gas * (0.40 + 0.34 * bandInner + 0.18 * bandMid + 0.10 * heat);
                        float luminousScale = 1.0 + sideStrength *
                                               (0.08 * frontFraction - 0.22 * backFraction);
                        radiance += throughput * alpha * emissive * luminousScale;
                        throughput *= 1.0 - alpha;
                        opticalDepth += alpha;
                        if (throughput < 0.02) break;
                    }
                }
                if (pos.z > 13.0 && dist > 16.0 && dot(pos, vel) > 0.0) break;
            }

            float q = length(viewRay.xy) / max(radius, 0.0001);
            float core = 1.0 - smoothstep(0.52, 0.90, q);
            float shadowShell = exp(-pow((q - 0.96) / 0.10, 2.0));
            float captureShell = exp(-pow((q - 1.05) / 0.13, 2.0));
            float photonRing = exp(-pow((q - 1.035) / 0.052, 2.0));
            float halo = exp(-pow((q - 1.22) / (0.18 * AV_BLACK_HOLE_HALO_SOFTNESS), 2.0));
            float sideLight = clamp(0.55 - 0.34 * viewRay.x / max(length(viewRay.xy), 0.0001), 0.18, 0.96);

            vec3 coreColor = vec3(0.00004, 0.00005, 0.00010);
            vec3 edgeCool = vec3(0.010, 0.013, 0.020);
            vec3 edgeWarm = vec3(0.019, 0.014, 0.010);
            vec3 shadowColor = mix(coreColor, mix(edgeCool, edgeWarm, sideLight), pow(clamp(q, 0.0, 1.0), 1.72));

            vec3 behind = swallowed ? shadowColor : sky;
            float shellOcc = clamp(core * 0.30 + shadowShell * 0.16, 0.0, 0.74)
                           * nightFade * AV_BLACK_HOLE_SHADOW_DEPTH;
            behind = mix(behind, shadowColor, shellOcc);
            vec3 result = behind * throughput + radiance * nightFade;

            float gasPresence = smoothstep(0.014, 0.24, opticalDepth);
            result += mix(vec3(0.10, 0.12, 0.18), vec3(0.34, 0.24, 0.16), sideLight)
                      * photonRing * gasPresence * nightFade * 0.034 * AV_BLACK_HOLE_SHADOW_DEPTH;
            result += vec3(0.52, 0.35, 0.24) * halo * gasPresence
                      * nightFade * AV_BLACK_HOLE_GLOW * 0.011;
            result *= 1.0 - captureShell * 0.018 * nightFade * AV_BLACK_HOLE_SHADOW_DEPTH;
            return mix(sky, result, clamp(nightFade, 0.0, 1.0));
        #endif
    #else
        return sky;
    #endif
}




// Draw after stars, but before clouds. Celestial geometry remains moon-locked.
vec3 av_night_black_hole(vec3 sky, vec3 ray) {
    #ifdef AV_BLACK_HOLE
        vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosN);
        vec3 moonDir = -sunDir;
        vec3 lateral = cross(vec3(0.0, 1.0, 0.0), moonDir);
        float lateralLen = length(lateral);
        lateral = lateralLen > 0.002 ? lateral / lateralLen : vec3(1.0, 0.0, 0.0);
        vec3 blackHole = normalize(moonDir * cos(AV_BLACK_HOLE_MOON_SEPARATION)
                                 + lateral * sin(AV_BLACK_HOLE_MOON_SEPARATION)
                                 + vec3(0.0, 0.038, 0.0));
        float blackHoleVisibility = smoothstep(0.18, 0.88, nightStrength) * (1.0 - rainStrength * 0.84);
        sky = av_black_hole(sky, ray, blackHole, blackHoleVisibility);
    #endif
    return sky;
}

vec3 av_mystical_celestials(vec3 sky, vec3 ray) {
    if (ray.y < -0.003) return sky;

    float dayPhase = float(worldTime) / 24000.0;
    float days = float(worldDay);
    float twilight = clamp(sunriseStrength + sunsetStrength, 0.0, 1.0);
    float weather = 1.0 - rainStrength * 0.84;
    float night = clamp(nightStrength, 0.0, 1.0);
    float day = clamp(dayStrength, 0.0, 1.0);

    float visibility = clamp(0.15 * day + 0.88 * twilight + night, 0.0, 1.0) * weather;
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosN);

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




vec3 round_sun(float Dist) {
    Dist = Dist * 0.5 + 0.5;
    const vec3 SUN_COLOR = vec3(5, 3.5, 0.8);
    const vec3 MOON_COLOR = vec3(1, 1.5, 2.5);
    
    vec3 Color = SUN_COLOR * (1 - smoothstep(0., 0.0015, 1 - Dist));
    Color += MOON_COLOR * (smoothstep(0.9995, 1., 1 - Dist));
    Color *= 1 - rainStrength;
    return Color;
}

vec3 square_sun(vec3 PlayerPosN) {
    const vec3 SUN_COLOR = vec3(5, 3.5, 0.8);
    const vec3 MOON_COLOR = vec3(1, 1.5, 2.5);

    float LHeight = sin(sunAngle * PI * 2);
    float IsPastNoon = 1 - step(0.25, sunAngle) * step(sunAngle, 0.75) * 2;
    vec3 SunPos = vec3(sqrt(1 - pow2(LHeight)) * IsPastNoon, LHeight, 0);

    float Deg = SUN_PATH_ROTATION / 180.0 * PI;
    float c = cos(Deg), s = sin(Deg);
    mat3 Rot = mat3(1,0,0,0,c,s,0,-s,c);
    PlayerPosN = Rot * PlayerPosN;

    float Dist = len_sq(PlayerPosN - SunPos);
    float DistMoon = len_sq(PlayerPosN + SunPos);
    vec3 Color = SUN_COLOR * (1-linstep(0.05, 0.07, Dist));
    Color += MOON_COLOR * (1-linstep(0.04, 0.05, DistMoon));
    Color *= 1 - rainStrength;
    return Color;
}

vec3 get_sun_glare(float Dist) {
    const vec3 SUN_GLARE = to_linear(vec3(f_SUN_GLARE_R, f_SUN_GLARE_G, f_SUN_GLARE_B));

    float DarkenFactor = 1 - rainStrength * RAIN_SKY_DARKENING;
    #ifdef IS_IRIS
        DarkenFactor *= 1 - thunderStrength * 0.75;
    #endif

    vec3 SunGlare = SUN_GLARE * DarkenFactor;
    float Visibility = sunsetStrength + sunriseStrength;
    Visibility = pow2(Visibility);

    return SunGlare * pow2(Dist * 0.5 + 0.5) * Visibility;
}

vec3 get_sky(vec3 ViewPosN, vec3 SunGlare) {
    vec3 baseColor = av_atmosphere_gradient(ViewPosN, SunGlare);

    #ifdef DIMENSION_OVERWORLD
        // V24. Atmospheric depth only; stars, clouds and moon geometry remain untouched.
        float night = clamp(nightStrength, 0.0, 1.0);
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
        float twilight = clamp(sunriseStrength + sunsetStrength, 0.0, 1.0);
        baseColor += vec3(0.0065, 0.0037, 0.0075) * horizon * twilight
                     * AV_NIGHT_HORIZON_GLOW * weather;
    #endif
    return max(baseColor, vec3(0.0));
}

float get_stars(vec3 PlayerPos) {
    vec3 StarCoord = PlayerPos / (PlayerPos.y + length(PlayerPos.xz));
    StarCoord.x += frameTimeCounter * 0.001;
    const float ACTUAL_STAR_SIZE = STAR_SIZE * 512;
    StarCoord = floor(StarCoord * ACTUAL_STAR_SIZE) / ACTUAL_STAR_SIZE;

    float Visibility = smoothstep(0.0, 0.1, StarCoord.y); // Smoothly fade out stars near the bottom of the sky
    #ifdef DIMENSION_OVERWORLD
    Visibility *= nightStrength;
    #endif
    return max(0, random(StarCoord.xz) - 0.996) * 50 * Visibility * STAR_STRENGTH;
}

vec3 get_aurora(vec3 PlayerPosN, float Dither) {
    float AuroraStrength = AURORA_STRENGTH * nightStrength;
    #ifndef AURORA_EVERYWHERE
        AuroraStrength *= precipitationSmooth - 1;
    #endif
    if(AuroraStrength <= 0.01) return vec3(0);
    
    const vec3 COLOR_TOP = pow(vec3(28, 255, 218) / 255.0, vec3(2.2));
    const vec3 COLOR_BOTTOM = pow(vec3(122, 255, 28) / 255.0, vec3(2.2));

    // Calculate intersection with aurora plane
    const float PLANE_TOP = 10.0 + AURORA_HEIGHT;
    const float PLANE_BOTTOM = 10.0;

    vec3 StartPos = PLANE_BOTTOM / PlayerPosN.y * PlayerPosN; 
    vec3 EndPos = PLANE_TOP / PlayerPosN.y * PlayerPosN;

    const int SAMPLE_COUNT = 2;

    vec3 Step = (EndPos - StartPos) / SAMPLE_COUNT;
    vec3 Pos = Step * Dither + StartPos;

    vec2 Wind = frameTimeCounter * vec2(0.25, 0.33);

    vec3 AuroraColor = vec3(0);
    for(int i = 1; i <= SAMPLE_COUNT; i++) {
        float Noise = texture(noisetex, (Pos.xz - Wind) / vec2(100, 200)).r;

        Noise = pow2(pow4(Noise));
        Noise *= smoothstep(0.0, 0.2, PlayerPosN.y);
        AuroraColor += Noise * mix(COLOR_BOTTOM, COLOR_TOP, smoothstep(0, 1, (i + Dither - 1.0) / SAMPLE_COUNT));

        Pos += Step;
    }

    return AuroraColor * AuroraStrength / SAMPLE_COUNT;
}

vec3 get_end_sky(vec3 ViewPosN, vec3 PlayerPosN) {
    const vec3 SkyT = to_linear(vec3(f_END_SKY_T_R, f_END_SKY_T_G, f_END_SKY_T_B));
    const vec3 SkyG1 = to_linear(vec3(f_END_AURORA1_R, f_END_AURORA1_G, f_END_AURORA1_B));
    const vec3 SkyG2 = to_linear(vec3(f_END_AURORA2_R, f_END_AURORA2_G, f_END_AURORA2_B));

    float upDot = dot(ViewPosN, gbufferModelView[1].xyz); //not much, what's up with you?

    vec2 RotPos1 = rotate(PlayerPosN.xz, frameTimeCounter * 0.02);
    vec2 RotPos2 = rotate(PlayerPosN.xz, -frameTimeCounter * 0.007);

    float Noise1 = fbm_fast(RotPos1 * 160, 2);
    float Noise2 = fbm_fast(RotPos2 * 280, 2);
    float VerticalFactor = 1 - abs(upDot);
    vec3 SkyG = (SkyG1 * Noise1 + SkyG2 * Noise2) * VerticalFactor; // End lights

    #if MC_VERSION >= 12109
        float DistFromFlash = distance(PlayerPosN.xz, normalize(view_player(endFlashPosition, false)).xz);
        float BoostFromFlash = (1 + max(0, 5 - DistFromFlash * 8) * endFlashIntensity); 
        SkyG *= BoostFromFlash;
    #endif

    vec3 Final = SkyT + SkyG * (fogify(upDot + 0.2, 0.05)); 

    Final *= 1 - fogify(max(upDot + 0.2, 0), 0.02); // Void at the bottom

    return Final;
}

vec3 get_sky_main(vec3 ViewPosN, vec3 PlayerPosN, vec3 SunGlare) {
    #ifdef DIMENSION_OVERWORLD
        vec3 SkyColor = get_sky(ViewPosN, SunGlare);
        // The compiled deferred1 pass is authoritative for planet rendering.
        // Celestials are blended only onto sky pixels in deferred1 main().
    #elif defined DIMENSION_END
        vec3 SkyColor = get_end_sky(ViewPosN, PlayerPosN);
    #elif defined DIMENSION_NETHER
        vec3 fogColorL = to_linear(fogColor.rgb);
        fogColorL += 1e-6; // Need to prevent nans when fog is vec3(0)
        vec3 SkyColor = mix(fogColorL, normalize(fogColorL), 0.4) / 3;
    #elif defined DIMENSION_GENERIC
        float upDot = dot(ViewPosN, gbufferModelView[1].xyz);
        vec3 SkyColor = to_linear(fogColor.rgb) * mix(1.0, fogify(max(upDot + 0.2, 0), 0.02), 0.7);
    #endif

    return SkyColor;
}

vec3 get_rainbow(vec3 PlayerPos, vec3 PlayerPosN) {
    #if RAINBOWS == 1
        if(rainbowStrength < 0.0001) return vec3(0);
    #endif
    const float SIZE = 10.0;
    bool IsPastNoon = sunriseStrength <= sunsetStrength && sunAngleAtHome > 0.25;
    float P = 100 * (float(IsPastNoon) * 2 - 1) / PlayerPosN.x;
    if(P < 0) return vec3(0);

    vec3 RainbowPlane = P * PlayerPosN;
    
    float LHeight = sin(sunAngleAtHome * PI * 2);
    float Hue = distance(vec3((float(IsPastNoon) * 2 - 1) * 100, -100 * LHeight, 0), RainbowPlane) / SIZE;
    if(Hue < SIZE || Hue > SIZE + 1) return vec3(0);

    float Len = length(PlayerPos);
    float Brightness = pow4(1 - clamp((P - Len) / 100, 0, 1));

    float LHeight45 = max(0, sin(fract(sunAngle * 4) / 4 * PI * 8 - PI / 2)); // Peaks at 45deg
    Brightness *= LHeight45;

    float EdgeFade = smoothstep(0.0, 0.5, 1-abs(Hue - SIZE - 0.5)*2);
    Brightness *= EdgeFade;

    #if RAINBOWS == 1
        Brightness *= rainbowStrength;
    #endif

    vec3 Col = hsv_to_rgb(vec3(1 - (Hue + 0.15), 1, 0.15 * Brightness));

    return Col * SUN_DIRECT * RAINBOW_STRENGTH * (1 - nightStrength);
}
