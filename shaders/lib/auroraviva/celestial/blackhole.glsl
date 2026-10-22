// Aurora Viva V25 Celestial Foundation — unchanged V24.1 code
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




// V18: both the black hole and the star lens use the SAME moon-locked center.
vec3 av_black_hole_center() {
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosN);
    vec3 moonDir = -sunDir;
    vec3 lateral = cross(vec3(0.0, 1.0, 0.0), moonDir);
    float lateralLen = length(lateral);
    lateral = lateralLen > 0.002 ? lateral / lateralLen : vec3(1.0, 0.0, 0.0);
    return normalize(moonDir * cos(AV_BLACK_HOLE_MOON_SEPARATION)
                     + lateral * sin(AV_BLACK_HOLE_MOON_SEPARATION)
                     + vec3(0.0, 0.038, 0.0));
}

float av_black_hole_night_visibility(vec3 center) {
    float night = smoothstep(0.18, 0.88, nightStrength);
    float weather = 1.0 - rainStrength * 0.84;
    float horizon = smoothstep(-0.075, 0.105, center.y);
    return night * weather * horizon;
}

// Thin gravitational lens approximation. This remaps the sampled background star
// direction (source beta = image theta - EinsteinRadius^2 / theta), with a smooth
// finite cutoff; it is not a full general-relativistic geodesic solver.
// Terrain, foreground clouds and the actual moon are never warped by this pass.
vec3 av_lensed_star_ray(vec3 ray) {
    #ifdef AV_BLACK_HOLE
        if (AV_BLACK_HOLE_STAR_LENSING <= 0.001) return ray;
        vec3 center = av_black_hole_center();
        float visibility = av_black_hole_night_visibility(center);
        if (visibility <= 0.002) return ray;

        float radius = AV_BLACK_HOLE_SIZE;
        float cosAngle = dot(ray, center);
        if (cosAngle < cos(radius * AV_BLACK_HOLE_LENS_RANGE)) return ray;

        vec3 radial = ray - center * cosAngle;
        float separation = length(radial);
        float q = separation / max(radius, 0.00001);
        if (q < 0.68) return ray; // black event horizon will occlude this area

        float falloff = 1.0 - smoothstep(AV_BLACK_HOLE_LENS_RANGE - 0.85,
                                        AV_BLACK_HOLE_LENS_RANGE, q);
        float einstein = radius * 1.32;
        float magnification = 1.0 - AV_BLACK_HOLE_STAR_LENSING * visibility * falloff
                                  * (einstein * einstein) / max(separation * separation, radius * radius * 0.55);
        magnification = clamp(magnification, -0.95, 1.0);
        return normalize(center * cosAngle + radial * magnification);
    #else
        return ray;
    #endif
}

// Draw after stars but before clouds; center and visibility synchronized with lens.
vec3 av_night_black_hole(vec3 sky, vec3 ray) {
    #ifdef AV_BLACK_HOLE
        vec3 center = av_black_hole_center();
        float visibility = smoothstep(0.18, 0.88, nightStrength) * (1.0 - rainStrength * 0.84);
        sky = av_black_hole(sky, ray, center, visibility);
    #endif
    return sky;
}

