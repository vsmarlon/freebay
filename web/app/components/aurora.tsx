import { useCallback } from 'react';
import auroraNoiseUrl from './aurora-noise.webp';

const fragment = `precision mediump float;
uniform vec2 uSize;
uniform float uTime;
uniform float uDark;
uniform sampler2D uNoise;
float sampleNoise(vec2 p) {
  vec2 uv = fract(p * 0.125);
  return texture2D(uNoise, (uv * 255.0 + 0.5) / 256.0).r;
}
void main() {
  vec2 uv = gl_FragCoord.xy / uSize;
  uv.x *= uSize.x / uSize.y;
  float t = uTime * 0.06;
  vec2 warpedUv = uv * 2.0;
  vec2 q = vec2(sampleNoise(warpedUv + vec2(0.0, t)), sampleNoise(warpedUv + vec2(5.2, 1.3 - t)));
  float n = sampleNoise(warpedUv + 4.0 * q + t * 0.3);
  float q1 = floor(n * 6.0) / 6.0;
  vec3 col;
  if (uDark > 0.5) {
    col = mix(vec3(0.039), vec3(0.400, 0.000, 0.384), q1);
    col = mix(col, vec3(0.541, 0.063, 0.514), smoothstep(0.55, 0.9, q1));
    col += vec3(1.000, 0.616, 0.933) * step(0.86, q1) * 0.28;
  } else {
    col = mix(vec3(0.937, 0.900, 0.773), vec3(0.541, 0.063, 0.514), q1 * 0.58);
    col = mix(col, vec3(0.400, 0.000, 0.384), step(0.62, q1) * 0.22);
    col += vec3(1.000, 0.616, 0.933) * step(0.78, q1) * 0.09;
  }
  gl_FragColor = vec4(col, 1.0);
}`;

export function Aurora() {
  const bind = useCallback((element: HTMLCanvasElement | null) => {
    if (!element) return;
    // ponytail: the aurora is an ambient wash — low-power GPU slice, no antialias; visual quality is insensitive to these.
    // preserveDrawingBuffer: without it the compositor may hand screenshots/Playwright a blank canvas; the buffer is 1x-DPR and 24fps, so the copy cost is negligible.
    const gl = element?.getContext('webgl', {
      powerPreference: 'low-power',
      antialias: false,
      alpha: false,
      preserveDrawingBuffer: true,
    });
    if (!element || !gl) return;
    const compile = (type: number, source: string) => {
      const shader = gl.createShader(type);
      if (!shader) return null;
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      return gl.getShaderParameter(shader, gl.COMPILE_STATUS) ? shader : null;
    };
    const vertex = compile(
      gl.VERTEX_SHADER,
      'attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}',
    );
    const pixel = compile(gl.FRAGMENT_SHADER, fragment);
    if (!vertex || !pixel) return;
    const program = gl.createProgram();
    if (!program) return;
    gl.attachShader(program, vertex);
    gl.attachShader(program, pixel);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) return;
    gl.useProgram(program);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
    const position = gl.getAttribLocation(program, 'p');
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
    const size = gl.getUniformLocation(program, 'uSize');
    const time = gl.getUniformLocation(program, 'uTime');
    const dark = gl.getUniformLocation(program, 'uDark');
    const noiseSampler = gl.getUniformLocation(program, 'uNoise');
    const texture = gl.createTexture();
    if (!texture) return;
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.uniform1i(noiseSampler, 0);
    let textureReady = false;
    let frame = 0;
    const started = performance.now();
    // ponytail: 1x canvas + 24fps cap — ambient wash, measured starving the main thread at 39fps full-DPR; the user asked the animation to run regardless of browser motion prefs.
    const FRAME_MS = 1000 / 24;
    let last = 0;
    const render = (now: number) => {
      if (now - last >= FRAME_MS) {
        last = now;
        const ratio = Math.min(devicePixelRatio || 1, 1);
        const width = Math.round(innerWidth * ratio);
        const height = Math.round(innerHeight * ratio);
        if (element.width !== width || element.height !== height) {
          element.width = width;
          element.height = height;
          gl.viewport(0, 0, width, height);
        }
        if (textureReady) {
          gl.uniform2f(size, width, height);
          gl.uniform1f(
            time,
            document.documentElement.dataset.aurora === 'off' ? 0 : (now - started) / 1000,
          );
          gl.uniform1f(dark, document.documentElement.dataset.theme === 'dark' ? 1 : 0);
          gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        }
      }
      if (document.documentElement.dataset.aurora !== 'off') frame = requestAnimationFrame(render);
    };
    const start = () => {
      cancelAnimationFrame(frame);
      last = 0;
      render(performance.now());
    };
    const image = new Image();
    image.onload = () => {
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
      textureReady = true;
      start();
    };
    image.src = auroraNoiseUrl;
    start();
    window.addEventListener('resize', start);
    const observer = new MutationObserver(start);
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme', 'data-aurora'],
    });
    return () => {
      cancelAnimationFrame(frame);
      image.onload = null;
      window.removeEventListener('resize', start);
      observer.disconnect();
      gl.deleteTexture(texture);
      gl.deleteBuffer(buffer);
      gl.deleteProgram(program);
    };
  }, []);
  return (
    <>
      <div className="aurora-static" aria-hidden="true" />
      <canvas className="aurora-canvas" ref={bind} aria-hidden="true" />
    </>
  );
}
