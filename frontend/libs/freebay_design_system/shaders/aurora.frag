#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;

out vec4 fragColor;

const vec3 kInk        = vec3(0.039, 0.039, 0.039);
const vec3 kPrimary    = vec3(0.400, 0.000, 0.384);
const vec3 kContainer  = vec3(0.541, 0.063, 0.514);
const vec3 kAccent     = vec3(1.000, 0.616, 0.933);
const vec3 kPaper      = vec3(1.000, 1.000, 1.000);

// Stefan Gustavson / Ashima Arts 2D Simplex Noise
// Optimized for mobile GPUs: 0 trigonometric calls, pure SIMD ALU operations
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0 - sqrt(3.0)) / 6.0
                        0.366025403784439,  // 0.5 * (sqrt(3.0) - 1.0)
                       -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0

    // First corner
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                           + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    // Gradients: 41 points on a line, mapped onto a diamond
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * (snoise(p) * 0.5 + 0.5);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    uv.x *= uSize.x / uSize.y;

    float t = uTime * 0.06;

    // Domain warp: fluid aurora waves with 0 trigonometric SFU calls
    vec2 q = vec2(fbm(uv * 2.0 + vec2(0.0, t)),
                  fbm(uv * 2.0 + vec2(5.2, 1.3 - t)));
    float n = fbm(uv * 2.0 + 4.0 * q + t * 0.3);

    // posterize: hard bands, never a soft gradient
    float bands = 6.0;
    float q1 = floor(n * bands) / bands;

    vec3 col;
    if (uDark > 0.5) {
        col = mix(kInk, kPrimary, q1);
        col = mix(col, kContainer, smoothstep(0.55, 0.9, q1));
        col += kAccent * step(0.86, q1) * 0.28;
    } else {
        col = mix(kPaper, kContainer, q1 * 0.16);
        col = mix(col, kPrimary, step(0.86, q1) * 0.10);
    }

    fragColor = vec4(col, 1.0);
}
