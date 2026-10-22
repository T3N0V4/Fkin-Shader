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

