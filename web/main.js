const canvas = document.getElementById('glcanvas');
const gl = canvas.getContext('webgl2', { antialias: false, alpha: false, powerPreference: 'high-performance' });

if (!gl) {
  document.body.innerHTML = '<main style="padding:24px;color:white;font-family:sans-serif">WebGL2 is not available in this browser.</main>';
  throw new Error('WebGL2 unavailable');
}

const vertexSource = `#version 300 es
precision highp float;
const vec2 POSITIONS[3] = vec2[3](
  vec2(-1.0, -1.0),
  vec2( 3.0, -1.0),
  vec2(-1.0,  3.0)
);
out vec2 v_uv;
void main() {
  vec2 p = POSITIONS[gl_VertexID];
  v_uv = p * 0.5 + 0.5;
  gl_Position = vec4(p, 0.0, 1.0);
}`;

const fragmentSource = `#version 300 es
precision highp float;
in vec2 v_uv;
out vec4 outColor;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_yaw;
uniform float u_pitch;
uniform float u_distance;

const float PI = 3.141592653589793;
const float TAU = 6.283185307179586;
const float RS = 1.15;
const float HORIZON = RS * 0.25;
const float PHOTON_RHO = RS * 0.9330127;
const float FAR_LIMIT = 48.0;

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float n000 = hash12(i.xy + vec2(17.0, 31.0) * i.z);
  float n100 = hash12(i.xy + vec2(1.0, 0.0) + vec2(17.0, 31.0) * i.z);
  float n010 = hash12(i.xy + vec2(0.0, 1.0) + vec2(17.0, 31.0) * i.z);
  float n110 = hash12(i.xy + vec2(1.0, 1.0) + vec2(17.0, 31.0) * i.z);
  float n001 = hash12(i.xy + vec2(17.0, 31.0) * (i.z + 1.0));
  float n101 = hash12(i.xy + vec2(1.0, 0.0) + vec2(17.0, 31.0) * (i.z + 1.0));
  float n011 = hash12(i.xy + vec2(0.0, 1.0) + vec2(17.0, 31.0) * (i.z + 1.0));
  float n111 = hash12(i.xy + vec2(1.0, 1.0) + vec2(17.0, 31.0) * (i.z + 1.0));
  float nx00 = mix(n000, n100, f.x);
  float nx10 = mix(n010, n110, f.x);
  float nx01 = mix(n001, n101, f.x);
  float nx11 = mix(n011, n111, f.x);
  return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

float fbm(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; ++i) {
    v += a * valueNoise(p);
    p = p * 2.03 + vec3(17.1, 9.2, 5.7);
    a *= 0.5;
  }
  return v;
}

float dlognDr(float r) {
  float a = RS / max(4.0 * r, 0.0001);
  a = min(a, 0.985);
  return -(a / max(r, 0.0001)) * (3.0 / (1.0 + a) + 1.0 / max(1.0 - a, 0.015));
}

vec3 rayAccel(vec3 p, vec3 d) {
  float r = length(p);
  vec3 g = normalize(p) * dlognDr(r);
  return g - d * dot(d, g);
}

void stepGeo(inout vec3 p, inout vec3 d, float h) {
  vec3 a1 = rayAccel(p, d);
  vec3 midD = normalize(d + a1 * 0.5 * h);
  vec3 midP = p + d * 0.5 * h;
  vec3 a2 = rayAccel(midP, midD);
  p += midD * h;
  d = normalize(d + a2 * h);
}

vec3 sky(vec3 dir) {
  float y = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
  vec3 base = mix(vec3(0.001, 0.002, 0.006), vec3(0.01, 0.014, 0.026), y);
  float band = exp(-pow(abs(dir.y + 0.12 * sin(4.0 * dir.x)), 1.45) * 9.0);
  vec3 nebula = vec3(0.16, 0.2, 0.38) * band * 0.28;
  vec2 sphere = vec2(atan(dir.z, dir.x) / TAU + 0.5, asin(dir.y) / PI + 0.5);
  vec2 grid = sphere * vec2(520.0, 260.0);
  vec2 cell = floor(grid);
  vec2 local = fract(grid) - 0.5;
  float rnd = hash12(cell);
  float star = smoothstep(0.989, 1.0, rnd) * exp(-dot(local, local) * 120.0);
  vec3 starColor = mix(vec3(0.72, 0.88, 1.0), vec3(1.0, 0.72, 0.42), hash12(cell + 7.13));
  return base + nebula + starColor * star * 4.0;
}

vec3 localEmission(vec3 p, vec3 dir) {
  float r = length(p);
  float cyl = length(p.xz);
  float az = atan(p.z, p.x);
  float diskWindow = smoothstep(HORIZON * 1.4, HORIZON * 3.1, cyl) * (1.0 - smoothstep(7.5, 12.0, cyl));
  float diskThickness = exp(-abs(p.y) * (8.0 / (1.0 + cyl * 0.1)));
  float spiral = 0.5 + 0.5 * sin(az * 10.0 + cyl * 2.7 - u_time * 0.65);
  float ridges = 1.0 - abs(2.0 * fbm(vec3(p.xz * 1.25 + vec2(u_time * 0.08, -u_time * 0.04), cyl * 0.12)) - 1.0);
  float disk = diskWindow * diskThickness * (0.35 + 0.65 * spiral) * (0.55 + 0.75 * ridges);
  vec3 diskGlow = mix(vec3(0.05, 0.7, 1.05), vec3(1.9, 2.05, 1.95), smoothstep(0.4, 3.4, cyl)) * disk * 0.18;

  float twist = sin(abs(p.y) * 3.8 - u_time * 5.0 + az * 7.0);
  float jetCore = exp(-cyl * cyl * (18.0 + 5.0 * twist));
  float jetLength = smoothstep(HORIZON * 1.4, 2.0, abs(p.y)) * (1.0 - smoothstep(18.0, 28.0, abs(p.y)));
  float braided = 0.58 + 0.42 * sin(34.0 * az + abs(p.y) * 7.0 - u_time * 4.0);
  vec3 jet = vec3(0.78, 0.84, 1.65) * jetCore * braided * jetLength * 0.9;

  float throat = exp(-abs(r - HORIZON * 1.08) * 13.0);
  float grazing = pow(1.0 - abs(dot(normalize(p), dir)), 3.0);
  vec3 caustic = vec3(0.54, 1.1, 1.35) * throat * grazing * 0.2;
  return diskGlow + jet + caustic;
}

vec3 horizonEmission(vec3 p, vec3 dir, float travel) {
  vec3 n = normalize(p);
  float polar = abs(n.y);
  float az = atan(n.z, n.x);
  float filaments = 0.5 + 0.5 * sin(18.0 * az + 9.0 * n.y + u_time * 1.7);
  filaments *= 0.65 + 0.35 * valueNoise(n * 9.0 + vec3(0.0, u_time * 0.4, 0.0));
  float limb = pow(1.0 - abs(dot(n, -dir)), 1.35);
  float causalCone = pow(smoothstep(0.10, 1.0, polar), 2.0);
  vec3 thermal = mix(vec3(1.0, 0.78, 0.58), vec3(0.72, 1.0, 1.25), causalCone);
  vec3 whiteCore = vec3(2.3, 2.38, 2.3) * (0.78 + 0.22 * filaments);
  vec3 cyanRim = vec3(0.22, 1.35, 1.75) * (0.45 + 3.25 * limb);
  return (whiteCore + thermal + cyanRim) * exp(-0.014 * travel);
}

vec3 trace(vec3 ro, vec3 rd) {
  vec3 p = ro;
  vec3 d = normalize(rd);
  vec3 glow = vec3(0.0);
  float travel = 0.0;
  float closest = 999.0;
  vec3 closestPoint = p;

  for (int i = 0; i < 190; ++i) {
    float r = length(p);
    if (r < closest) { closest = r; closestPoint = p; }
    if (r < HORIZON * 1.018) return glow + horizonEmission(p, d, travel);
    if (r > FAR_LIMIT && dot(p, d) > 0.0) {
      float photonRing = exp(-pow(closest - PHOTON_RHO, 2.0) * 24.0);
      vec3 bg = sky(d) + vec3(0.70, 0.90, 1.30) * photonRing * 1.45;
      return glow + bg;
    }
    float photonSlow = 1.0 - 0.58 * exp(-pow(r - PHOTON_RHO, 2.0) * 4.0);
    float horizonSlow = smoothstep(HORIZON * 1.01, HORIZON * 2.8, r);
    float h = clamp(r * 0.035, 0.008, 0.2) * max(0.22, photonSlow * horizonSlow);
    stepGeo(p, d, h);
    travel += h;
    glow += localEmission(p, d) * h * exp(-0.009 * travel);
  }
  return glow + sky(d) * 0.25;
}

void main() {
  vec2 ndc = v_uv * 2.0 - 1.0;
  float aspect = max(u_resolution.x / max(u_resolution.y, 1.0), 0.25);
  ndc.x *= aspect;

  float cp = cos(u_pitch);
  vec3 eye = u_distance * vec3(sin(u_yaw) * cp, sin(u_pitch), cos(u_yaw) * cp);
  vec3 forward = normalize(-eye);
  vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
  vec3 up = cross(right, forward);
  vec2 film = ndc * tan(radians(74.0) * 0.5);
  vec3 rd = normalize(right * film.x + up * film.y + forward);

  vec3 color = trace(eye, rd);
  float vignette = smoothstep(1.28, 0.18, length(v_uv * 2.0 - 1.0));
  color *= 0.72 + 0.28 * vignette;
  color = color / (color + vec3(1.0));
  color = pow(color, vec3(0.4545));
  outColor = vec4(color, 1.0);
}`;

function compileShader(type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const log = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(log);
  }
  return shader;
}

function createProgram() {
  const program = gl.createProgram();
  gl.attachShader(program, compileShader(gl.VERTEX_SHADER, vertexSource));
  gl.attachShader(program, compileShader(gl.FRAGMENT_SHADER, fragmentSource));
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(program));
  }
  return program;
}

const program = createProgram();
const vao = gl.createVertexArray();
gl.bindVertexArray(vao);
gl.useProgram(program);

const uniforms = {
  resolution: gl.getUniformLocation(program, 'u_resolution'),
  time: gl.getUniformLocation(program, 'u_time'),
  yaw: gl.getUniformLocation(program, 'u_yaw'),
  pitch: gl.getUniformLocation(program, 'u_pitch'),
  distance: gl.getUniformLocation(program, 'u_distance'),
};

const state = {
  yaw: 0.35,
  pitch: 0.12,
  distance: 6.8,
  dragging: false,
  lastX: 0,
  lastY: 0,
};

function resize() {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const width = Math.floor(canvas.clientWidth * dpr);
  const height = Math.floor(canvas.clientHeight * dpr);
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
  }
}

function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

canvas.addEventListener('pointerdown', (event) => {
  state.dragging = true;
  state.lastX = event.clientX;
  state.lastY = event.clientY;
  canvas.setPointerCapture(event.pointerId);
});

canvas.addEventListener('pointermove', (event) => {
  if (!state.dragging) return;
  const dx = event.clientX - state.lastX;
  const dy = event.clientY - state.lastY;
  state.lastX = event.clientX;
  state.lastY = event.clientY;
  state.yaw += dx * 0.006;
  state.pitch = clamp(state.pitch + dy * 0.006, -1.35, 1.35);
});

canvas.addEventListener('pointerup', () => { state.dragging = false; });
canvas.addEventListener('pointercancel', () => { state.dragging = false; });

canvas.addEventListener('wheel', (event) => {
  event.preventDefault();
  state.distance = clamp(state.distance * Math.exp(event.deltaY * 0.001), 3.2, 18.0);
}, { passive: false });

canvas.addEventListener('dblclick', () => {
  state.yaw = 0.35;
  state.pitch = 0.12;
  state.distance = 6.8;
});

let start = performance.now();
function frame(now) {
  resize();
  gl.useProgram(program);
  gl.uniform2f(uniforms.resolution, canvas.width, canvas.height);
  gl.uniform1f(uniforms.time, (now - start) * 0.001);
  gl.uniform1f(uniforms.yaw, state.yaw);
  gl.uniform1f(uniforms.pitch, state.pitch);
  gl.uniform1f(uniforms.distance, state.distance);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
  requestAnimationFrame(frame);
}

requestAnimationFrame(frame);
