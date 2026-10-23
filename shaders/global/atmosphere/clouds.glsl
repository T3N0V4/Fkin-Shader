vec3 blend_vl(vec3 OldColor, vec4 NewColor) {
    return OldColor * NewColor.a + NewColor.rgb;
}

vec4 get_clouds_flat(vec3 ViewPosN, vec3 PlayerPos, vec3 PlayerPosN, vec3 SunGlare) {
    vec2 CloudPos = PlayerPos.xz / (PlayerPos.y + length(PlayerPos.xz) / 6);

    const float ACTUAL_CLOUD_SPEED = 0;//CLOUD_SPEED / 100.;
    float Animation = float(frameTimeCounter) * ACTUAL_CLOUD_SPEED;
    CloudPos += cameraPosition.xz / 512;
    CloudPos = (CloudPos + Animation) * 32;

    float Noise = noise(CloudPos);
    float CloudAmount = CLOUD_AMOUNT / 100.0 + (rainStrength + thunderStrength) / 5;
    Noise *= smoothstep(0.0, 0.4 - CLOUD_OPACITY, Noise - 0.6 + CloudAmount);
    if(Noise < 0.01) return vec4(0,0,0,1);

    // Ultimate RTX raytraced ptgi 2000 cloud lighting
    float Absorbtion = noise(CloudPos + slpPlayerN.xz * 8);
    const float DENSITY = 1.5;

    vec3 CloudColorRaw = (SKY_GROUND * 2 + SunGlare);
    vec3 CloudColor = CloudColorRaw * 0.25 / PI;

    float VdotL = dot(ViewPosN, slpN);
    float MiePhase = max(xlf_phase(VdotL, 0.7) * 1.5, 1 / PI);
    CloudColor += SUN_DIRECT * MiePhase * exp(-Absorbtion * 1.5 * DENSITY);

    #ifdef IS_IRIS
        if(lightningBoltPosition.w > 0) {  
            CloudColor += vec3(1) * exp(-DENSITY * distance(lightningBoltPosition.xz / far, PlayerPosN.xz) * 4);
        }
    #endif

    float Transmittance = exp(-Noise * DENSITY);
    return vec4(CloudColor * Noise * DENSITY, Transmittance);
}

// V26.1.12: wisps occupy a real world-space layer, never an angular sky texture.
// This lets the camera fly through the clouds instead of dragging them upward.
vec4 get_clouds_wispy(vec3 ViewPosN, vec3 PlayerPos, vec3 PlayerPosN,
                      vec3 SunGlare, float maxDistance) {
    const float bottomY = AV_WISPY_CLOUD_BASE_HEIGHT;
    const float topY = bottomY + AV_WISPY_CLOUD_THICKNESS;
    if (abs(PlayerPosN.y) < 0.0001 || maxDistance <= 0.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    float t0 = (bottomY - cameraPosition.y) / PlayerPosN.y;
    float t1 = (topY - cameraPosition.y) / PlayerPosN.y;
    float entry = max(0.0, min(t0, t1));
    float leave = min(max(t0, t1), maxDistance);
    if (leave <= entry + 0.001) return vec4(0.0, 0.0, 0.0, 1.0);

    // Thin, lightweight volume: three samples, fixed world-space density.
    const int wispySteps = 3;
    float stepLength = (leave - entry) / float(wispySteps);
    vec3 pos = cameraPosition + PlayerPosN * (entry + stepLength * 0.5);
    vec2 wind = frameTimeCounter * vec2(12.0, 6.0) * CLOUD_SPEED;
    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);
    float phase = max(xlf_phase(dot(ViewPosN, slpN), 0.7), 1.0 / PI);
    vec3 lightColor = (SKY_GROUND * 3.5 + SunGlare) * ISOTROPIC_PHASE
                       + SUN_DIRECT * phase;
    for (int i = 0; i < wispySteps; ++i) {
        vec2 uv = (pos.xz - wind) * 0.00013;
        float shape = texture(noisetex, uv).r;
        float detail = texture(noisetex, uv * 3.2 + vec2(0.23, 0.47)).b;
        float vertical = smoothstep(bottomY, bottomY + 9.0, pos.y)
                       * (1.0 - smoothstep(topY - 9.0, topY, pos.y));
        float density = smoothstep(0.45, 0.78, shape)
                      * (0.65 + 0.35 * detail) * vertical;
        float attenuation = exp(-density * stepLength * 0.035);
        scattering += lightColor * (1.0 - attenuation) * transmittance;
        transmittance *= attenuation;
        pos += PlayerPosN * stepLength;
    }
    // Near the geometric horizon, transition gently into the background air.
    float fade = 1.0 - smoothstep(1800.0, 4400.0, entry);
    return vec4(scattering * fade, mix(1.0, transmittance, fade));
}

vec4 get_clouds_wispy(vec3 ViewPosN, vec3 PlayerPos, vec3 PlayerPosN,
                      vec3 SunGlare) {
    return get_clouds_wispy(ViewPosN, PlayerPos, PlayerPosN, SunGlare, 1000000.0);
}

vec4 get_clouds_volumetric(vec3 ViewPosN, vec3 PlayerPosN, vec3 SunGlare, float Dither, float maxDistance) {
    // Aurora Viva V26.1.6: fixed WORLD Y, not a plane attached to the camera.
    const float PLANE_BOTTOM = AV_CLOUD_BASE_HEIGHT;
    const float PLANE_TOP = AV_CLOUD_BASE_HEIGHT + AV_CLOUD_LAYER_THICKNESS;

    const float CLOUD_EXTINCTION = 0.5;
    const float CLOUD_SCATTERING = CLOUD_EXTINCTION;

    const int SAMPLE_COUNT = 12;
    int SampleCount = clamp(int(((1 - PlayerPosN.y) * 0.75 + 0.25) * SAMPLE_COUNT + 1), 2, SAMPLE_COUNT);

    // Solve both intersections in camera-relative ray space. The volume is
    // anchored to absolute world Y; rays going away from the layer do no work.
    if (abs(PlayerPosN.y) < 0.0001) return vec4(0.0, 0.0, 0.0, 1.0);
    float RayBottom = (PLANE_BOTTOM - cameraPosition.y) / PlayerPosN.y;
    float RayTop = (PLANE_TOP - cameraPosition.y) / PlayerPosN.y;
    float RayEnter = max(0.0, min(RayBottom, RayTop));
    float RayExit = min(max(RayBottom, RayTop), maxDistance);
    if (RayExit <= RayEnter + 0.001) return vec4(0.0, 0.0, 0.0, 1.0);

    vec3 Step = PlayerPosN * ((RayExit - RayEnter) / float(SampleCount));
    float StepSize = length(Step);
    vec3 Pos = cameraPosition + PlayerPosN * RayEnter + Step * Dither;

    vec3 Wind = frameTimeCounter * vec3(12, 0, 16) * CLOUD_SPEED;
    float CloudAmount = (CLOUD_AMOUNT - 12) / 10.0 + (rainStrength + thunderStrength * 0.5);
    
    float VdotL = dot(ViewPosN, slpN);
    float Phase = max(xlf_phase(VdotL, 0.7) * 1.5, 1 / PI);

    vec3 TotalScattering = vec3(0); float TotalTransmittance = 1;
    for(int i = 1; i <= SampleCount; i++) {
        float Base = texture(noisetex, (Pos.xz - Wind.xz) * 0.00007).r;

        float Alt = rescale(PLANE_BOTTOM, PLANE_TOP, Pos.y);
        float HeightDensity = linstep(0.0, 0.75, 1 - Alt) * linstep(0.0, 0.2, Alt);
        float CoverageThreshold = clamp(0.42 - 0.08 * CloudAmount, 0.18, 0.64);
        Base = smoothstep(CoverageThreshold, 0.90, Base) * HeightDensity * HeightDensity;

        if(Base < 1e-4) {
            Pos += Step;
            continue;
        }

        float DetailTop = texture(colortex6, (Pos) / vec3(64) * 0.05).r;
        float DetailBottom = texture(colortex6, (Pos) / vec3(64) * 0.0125).r;
        Base = max(0, Base - DetailBottom * DetailTop * 0.1);

        float fms = CLOUD_SCATTERING * (1 - exp(-2.5 * Base * CLOUD_EXTINCTION)) / CLOUD_EXTINCTION;
        float MS = ISOTROPIC_PHASE * fms / (1 - fms);

        vec3 Scattering = (mix(SKY_TOP, SKY_GROUND, 0.65) * 2.16 + SunGlare * 1.07) * ISOTROPIC_PHASE;

        float LightFactor = linstep(PLANE_BOTTOM, PLANE_TOP, Pos.y) * 0.7 + 0.3;
        Scattering += SUN_DIRECT * (Phase + MS) * 1.58 * LightFactor;

        float Transmittance = exp(-Base * StepSize * CLOUD_EXTINCTION);
        Scattering *= CLOUD_SCATTERING * TotalTransmittance * (1 - Transmittance) / CLOUD_EXTINCTION;

        TotalScattering += Scattering;
        TotalTransmittance *= Transmittance;

        if(TotalTransmittance < 0.01) break;

        Pos += Step;
    }

    // At grazing angles the layer spans many kilometres. Fade the far portion
    // into exactly the same air color as the rest of the sky, no horizon band.
    float distanceFade = 1.0 - smoothstep(1200.0, 3400.0, RayEnter);
    vec4 FinalColor = vec4(TotalScattering * distanceFade,
                           mix(1.0, TotalTransmittance, distanceFade));
    return FinalColor;
}

// Calls from water reflections and sky retain unbounded scene depth.
vec4 get_clouds_volumetric(vec3 ViewPosN, vec3 PlayerPosN, vec3 SunGlare, float Dither) {
    return get_clouds_volumetric(ViewPosN, PlayerPosN, SunGlare, Dither, 1000000.0);
}

#ifdef DEFERRED
    #define BLOCKY_CLOUD_TEXTURE colortex3
#else
    #define BLOCKY_CLOUD_TEXTURE colortex7
#endif

vec4 get_clouds_blocky_volumetric(vec3 ViewPosN, vec3 PlayerPosN, vec3 SunGlare, float Dither, const bool IsSecondLayer) {
    float PLANE_TOP = !IsSecondLayer ? 110.0 : 510;
    float PLANE_BOTTOM = !IsSecondLayer ? 100.0 : 500;
    float CLOUD_SIZE = !IsSecondLayer ? 0.00025 : 0.0001;
    const float CLOUD_SCALE = 0.1; // Scale everything down to reduce precision loss

    const float CLOUD_EXTINCTION = 0.5;
    const float CLOUD_SCATTERING = CLOUD_EXTINCTION;

    const int SAMPLE_COUNT = 16;

    vec3 StartPos = PLANE_BOTTOM / PlayerPosN.y * PlayerPosN; 
    vec3 EndPos = PLANE_TOP / PlayerPosN.y * PlayerPosN; 
    vec3 Pos = StartPos + vec3(cameraPosition.x, 0, cameraPosition.z) * CLOUD_SCALE;

    float Wind = frameTimeCounter * 4 * CLOUD_SPEED * CLOUD_SCALE;
    Pos.x += Wind;
    Pos.z += IsSecondLayer ? 10000 : 0;

    float Density = texture(BLOCKY_CLOUD_TEXTURE, Pos.xz * CLOUD_SIZE).a; // Sample right at the beginning
    vec2 TextureSize = textureSize(BLOCKY_CLOUD_TEXTURE, 0);
    if(Density < 1e-2) { 
        // Travel to the edge of the next texel
        for(int i = 1; i < SAMPLE_COUNT; i++) {
            vec2 TexelPos = fract(Pos.xz * CLOUD_SIZE * TextureSize);
            vec2 DistToNext = ((step(0, PlayerPosN.xz)) - TexelPos) / PlayerPosN.xz / TextureSize;
            Pos += (PlayerPosN * min(DistToNext.x, DistToNext.y)) / CLOUD_SIZE;
            Pos += 0.005 * sign(vec3(PlayerPosN.x, 0, PlayerPosN.z)); // Bias to make sure we sample the correct texel
            
            if(Pos.y > PLANE_TOP) { // Break if we go too high
                break;
            }
            Density = texture(BLOCKY_CLOUD_TEXTURE, Pos.xz * CLOUD_SIZE).a;
            
            if(Density > 1e-2) {
                break;
            }
        }
    }
    if(Density < 1e-2) return vec4(0,0,0,1);

    // Lighting

    // Same DDA, for the sun ray
    vec3 SunOffset = slpPlayerN;

    vec3 SunSamplePos = Pos;
    float SunT = 1;
    for(int i = 1; i <= 6; i++) {
        vec3 TexelPos;
        TexelPos.xz = fract(SunSamplePos.xz * CLOUD_SIZE * TextureSize);
        TexelPos.y = rescale(PLANE_BOTTOM, PLANE_TOP, SunSamplePos.y);
        vec3 DistToNext = ((step(0, SunOffset)) - TexelPos) / SunOffset / vec3(TextureSize.x, 1. / (PLANE_TOP - PLANE_BOTTOM), TextureSize.y);
        DistToNext.xz /= CLOUD_SIZE;
        float MinDist = min_component(DistToNext);
        SunSamplePos += SunOffset * MinDist;
        SunSamplePos += 0.001 * sign(SunOffset); // Bias to make sure we sample the correct texel

        float SunSample = texture(BLOCKY_CLOUD_TEXTURE, SunSamplePos.xz * CLOUD_SIZE).a;
        SunT *= exp(-(MinDist * 0.3) * CLOUD_EXTINCTION); 
        if(SunT < 1e-4 || SunSamplePos.y > PLANE_TOP || SunSamplePos.y < PLANE_BOTTOM || SunSample < 1e-2) break;
    }

    float LightFactor = linstep(PLANE_BOTTOM, PLANE_TOP, Pos.y) * 0.7 + 0.3;
    vec3 Scattering = (SKY_GROUND + SunGlare) * LightFactor;

    float VdotL = dot(ViewPosN, slpN);
    float Phase = max(xlf_phase(VdotL, 0.7) * 1.5, 1 / PI);

    if(IsSecondLayer) SunT = mix(1.0, SunT, 0.5);
    Scattering += SUN_DIRECT * Phase * SunT;

    float Transmittance = exp(-Density * 2 * CLOUD_EXTINCTION);
    if(IsSecondLayer) Transmittance = mix(1.0, Transmittance, 0.25);
    Scattering *= CLOUD_SCATTERING * (1 - Transmittance) / CLOUD_EXTINCTION;


    vec4 FinalColor = vec4(Scattering, Transmittance);


    return FinalColor;
}


vec3 get_clouds(vec3 ViewPosN, vec3 PlayerPos, vec3 PlayerPosN, vec3 SunGlare, vec3 SkyColor, float Dither) {
    vec3 originalSky = SkyColor;
#if CLOUD_STYLE == 0
    return SkyColor;
#elif CLOUD_STYLE == 2
    vec4 mainCloud = get_clouds_volumetric(ViewPosN, PlayerPosN, SunGlare, Dither);
#ifdef DOUBLE_CLOUD_LAYERS
    vec4 highCloud = get_clouds_wispy(ViewPosN, PlayerPos, PlayerPosN, SunGlare);
    // Order is based on world altitude, not a permanent foreground overlay.
    if (cameraPosition.y > AV_WISPY_CLOUD_BASE_HEIGHT && PlayerPosN.y < 0.0) {
        SkyColor = blend_vl(SkyColor, mainCloud);
        SkyColor = blend_vl(SkyColor, highCloud);
    } else {
        SkyColor = blend_vl(SkyColor, highCloud);
        SkyColor = blend_vl(SkyColor, mainCloud);
    }
#else
    SkyColor = blend_vl(SkyColor, mainCloud);
#endif
#else
    vec4 cloudColor;
#ifdef DOUBLE_CLOUD_LAYERS
#if CLOUD_STYLE == 1
    cloudColor = get_clouds_wispy(ViewPosN, PlayerPos, PlayerPosN, SunGlare);
    SkyColor = blend_vl(SkyColor, cloudColor);
#elif CLOUD_STYLE == 3
    cloudColor = get_clouds_blocky_volumetric(ViewPosN, PlayerPosN, SunGlare, Dither, true);
    SkyColor = blend_vl(SkyColor, cloudColor);
#endif
#endif
#if CLOUD_STYLE == 1
    cloudColor = get_clouds_flat(ViewPosN, PlayerPos, PlayerPosN, SunGlare);
#elif CLOUD_STYLE == 3
    cloudColor = get_clouds_blocky_volumetric(ViewPosN, PlayerPosN, SunGlare, Dither, false);
#endif
    SkyColor = blend_vl(SkyColor, cloudColor);
#endif
    // When the camera is above the real volume, looking downward must NOT
    // hide clouds. Original code zeroed the weight for every negative ray.
    float viewFactor = PlayerPosN.y >= 0.0
        ? linstep(0.0, 0.2, PlayerPosN.y)
        : (cameraPosition.y > AV_CLOUD_BASE_HEIGHT
            ? linstep(0.0, 0.2, -PlayerPosN.y) : 0.0);
    return mix(originalSky, SkyColor, clamp(viewFactor * (CLOUD_OPACITY + 0.5), 0.0, 1.0));
}
