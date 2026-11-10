#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;
uniform sampler2D uNoise;

out vec4 fragColor;

const vec3 kInk        = vec3(0.039, 0.039, 0.039);
const vec3 kPrimary    = vec3(0.400, 0.000, 0.384);
const vec3 kContainer  = vec3(0.541, 0.063, 0.514);
const vec3 kAccent     = vec3(1.000, 0.616, 0.933);
const vec3 kWarmPaper  = vec3(0.988, 0.976, 0.933);

float sampleNoise(vec2 p) {
    // 256x256 seamless FBM tile over 8 noise units, including matching edges.
    // Wrap explicitly (Flutter samplers clamp), then address texel centers.
    vec2 uv = fract(p * 0.125);
    return texture(uNoise, (uv * 255.0 + 0.5) / 256.0).r;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    uv.x *= uSize.x / uSize.y;

    float t = uTime * 0.06;

    // Domain warp: two texture reads for displacement, one for the final noise.
    vec2 warpedUv = uv * 2.0;
    vec2 q = vec2(sampleNoise(warpedUv + vec2(0.0, t)),
                  sampleNoise(warpedUv + vec2(5.2, 1.3 - t)));
    float n = sampleNoise(warpedUv + 4.0 * q + t * 0.3);

    // posterize: hard bands, never a soft gradient
    float bands = 6.0;
    float q1 = floor(n * bands) / bands;

    vec3 col;
    if (uDark > 0.5) {
        col = mix(kInk, kPrimary, q1);
        col = mix(col, kContainer, smoothstep(0.55, 0.9, q1));
        col += kAccent * step(0.86, q1) * 0.28;
    } else {
        col = mix(kWarmPaper, kContainer, q1 * 0.32);
        col = mix(col, kPrimary, step(0.72, q1) * 0.08);
        col += kAccent * step(0.88, q1) * 0.035;
    }

    fragColor = vec4(col, 1.0);
}
