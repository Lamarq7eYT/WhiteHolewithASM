#version 150 compatibility

in vec2 g_uv;
in vec2 g_ndc;

out vec4 fragColor;

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_camera_yaw;
uniform float u_camera_pitch;
uniform float u_camera_distance;
uniform vec2 u_projection_center;

const float PI = 3.14159265358979323846;
const float TAU = 6.28318530717958647692;
const float RS = 1.15;
const float HORIZON = RS * 0.25;
const float PHOTON_RHO = RS * 0.9330127;
const float FAR_LIMIT = 64.0;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec3 p)
{
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
    float nxy0 = mix(nx00, nx10, f.y);
    float nxy1 = mix(nx01, nx11, f.y);
    return mix(nxy0, nxy1, f.z);
}

float fbm(vec3 p)
{
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; ++i) {
        v += a * value_noise(p);
        p = p * 2.03 + vec3(17.1, 9.2, 5.7);
        a *= 0.5;
    }
    return v;
}

float dlogn_dr(float r)
{
    float a = RS / max(4.0 * r, 0.0001);
    a = min(a, 0.985);
    return -(a / max(r, 0.0001)) * (3.0 / (1.0 + a) + 1.0 / max(1.0 - a, 0.015));
}

vec3 grad_logn(vec3 p)
{
    float r = length(p);
    return normalize(p) * dlogn_dr(r);
}

vec3 sky(vec3 dir)
{
    float y = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 base = mix(vec3(0.001, 0.002, 0.006), vec3(0.010, 0.014, 0.026), y);

    float band = exp(-pow(abs(dir.y + 0.12 * sin(4.0 * dir.x)), 1.45) * 9.0);
    float purpleVeil = exp(-pow(abs(dir.x + 0.24 + 0.18 * sin(5.0 * dir.y)), 1.35) * 11.0);
    vec3 nebula = vec3(0.16, 0.20, 0.38) * band * 0.26;
    nebula += vec3(0.30, 0.12, 0.42) * purpleVeil * smoothstep(-0.2, 0.8, dir.y) * 0.18;

    vec2 sphere = vec2(atan(dir.z, dir.x) / TAU + 0.5, asin(dir.y) / PI + 0.5);
    vec2 grid = sphere * vec2(760.0, 380.0);
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;
    float rnd = hash12(cell);
    float star = smoothstep(0.9915, 1.0, rnd) * exp(-dot(local, local) * 128.0);
    float hot = smoothstep(0.9987, 1.0, rnd);
    vec3 starColor = mix(vec3(0.80, 0.88, 1.00), vec3(1.00, 0.72, 0.42), hash12(cell + 7.13));

    return base + nebula + starColor * star * (2.5 + 8.0 * hot);
}

vec3 lensed_sky(vec3 dir, float closest, vec3 closestPoint)
{
    vec3 n = normalize(closestPoint);
    vec3 tangent = normalize(cross(n, vec3(0.0, 1.0, 0.0)));
    if (dot(tangent, tangent) < 0.1) {
        tangent = normalize(cross(n, vec3(1.0, 0.0, 0.0)));
    }

    float photon = exp(-pow(closest - PHOTON_RHO, 2.0) * 18.0);
    float shear = smoothstep(4.5, 0.55, closest);
    float weight = clamp(photon * 1.45 + shear * 0.28, 0.0, 1.25);
    float stretch = 0.018 + 0.050 * weight;

    vec3 base = sky(dir);
    vec3 ghostA = sky(normalize(dir + tangent * stretch));
    vec3 ghostB = sky(normalize(dir - tangent * stretch * 1.45));
    vec3 ghostC = sky(normalize(dir + tangent * stretch * 2.15 + n * 0.018));
    vec3 arcs = (ghostA + ghostB * 0.8 + ghostC * 0.45) * weight;
    vec3 causticTint = vec3(0.36, 0.74, 1.10) * photon * 0.32;

    return base + arcs + causticTint;
}

vec3 horizon_emission(vec3 p, vec3 dir, float travel)
{
    vec3 n = normalize(p);
    float polar = abs(n.y);
    float az = atan(n.z, n.x);

    float filaments = 0.5 + 0.5 * sin(18.0 * az + 9.0 * n.y + u_time * 1.7);
    filaments *= 0.65 + 0.35 * value_noise(n * 9.0 + vec3(0.0, u_time * 0.4, 0.0));

    float photosphere = sqrt(max(1.0 - RS / max(RS * 1.045, 0.001), 0.0009));
    float causalCone = pow(smoothstep(0.10, 1.0, polar), 2.0);
    float limb = pow(1.0 - abs(dot(n, -dir)), 1.35);
    float equator = exp(-abs(n.y) * 34.0);
    float flicker = 0.90 + 0.07 * sin(u_time * 7.1 + az * 5.0);
    flicker += 0.08 * fbm(n * 11.0 + vec3(u_time * 0.6, 0.0, -u_time * 0.25));

    vec3 thermal = mix(vec3(1.00, 0.78, 0.58), vec3(0.72, 1.00, 1.25), causalCone);
    vec3 whiteCore = vec3(2.30, 2.38, 2.30) * (0.78 + 0.22 * filaments);
    vec3 cyanRim = vec3(0.22, 1.35, 1.75) * (0.45 + 3.25 * limb);
    vec3 equatorFlash = vec3(2.55, 2.25, 1.70) * equator * (1.0 + 0.4 * filaments);
    vec3 chroma = vec3(0.08, 0.32, 0.42) * pow(limb, 1.6);

    return (whiteCore + thermal + cyanRim + equatorFlash + chroma) * flicker * (0.12 / photosphere) * exp(-0.014 * travel);
}

vec3 local_emission(vec3 p, vec3 dir)
{
    float r = length(p);
    vec3 n = p / max(r, 0.0001);
    float shell = exp(-abs(r - HORIZON * 1.42) * 5.6);
    float cyl = length(p.xz);
    float az = atan(p.z, p.x);

    float diskWindow = smoothstep(HORIZON * 1.35, HORIZON * 3.1, cyl) * (1.0 - smoothstep(8.5, 13.5, cyl));
    float diskThickness = exp(-abs(p.y) * (8.0 / (1.0 + cyl * 0.10)));
    float spiral = 0.5 + 0.5 * sin(az * 10.0 + cyl * 2.7 - u_time * 0.65);
    float turbulence = fbm(vec3(p.xz * 0.72, u_time * 0.26));
    float ridges = 1.0 - abs(2.0 * fbm(vec3(p.xz * 1.35 + vec2(u_time * 0.08, -u_time * 0.04), cyl * 0.12)) - 1.0);
    float clumps = smoothstep(0.32, 0.92, turbulence);
    float disk = diskWindow * diskThickness * (0.38 + 0.62 * spiral) * (0.40 + 0.80 * ridges) * (0.55 + 0.65 * clumps);
    vec3 diskColor = mix(vec3(0.05, 0.70, 1.05), vec3(1.90, 2.05, 1.95), smoothstep(0.3, 2.8, cyl));
    vec3 diskGlow = diskColor * disk * (0.045 + 0.18 / (0.55 + cyl));

    float equatorialBurst = exp(-abs(p.y) * 18.0) * exp(-cyl * 0.85);
    vec3 midline = vec3(2.30, 2.45, 2.35) * equatorialBurst * 0.32;

    float twist = sin(abs(p.y) * 3.8 - u_time * 5.0 + az * 7.0);
    float jetCore = exp(-cyl * cyl * (18.0 + 5.0 * twist));
    float jetLength = smoothstep(HORIZON * 1.4, 2.0, abs(p.y)) * (1.0 - smoothstep(22.0, 36.0, abs(p.y)));
    float edge = exp(-pow(cyl - (0.16 + 0.035 * twist), 2.0) * 95.0);
    float braided = 0.58 + 0.42 * sin(34.0 * az + abs(p.y) * 7.0 - u_time * 4.0);
    float jetNoise = 0.62 + 0.55 * fbm(vec3(p.xz * 8.0, abs(p.y) * 0.7 - u_time * 3.0));
    float particleCells = hash12(floor(vec2(abs(p.y) * 9.0 - u_time * 18.0, az * 28.0)));
    float particles = smoothstep(0.972, 1.0, particleCells) * exp(-cyl * cyl * 24.0) * jetLength;
    vec3 jet = vec3(0.78, 0.84, 1.65) * (jetCore * braided * jetNoise + edge * 0.55) * jetLength * 0.70;
    jet += vec3(1.25, 1.35, 2.20) * particles * 0.55;

    float throat = exp(-abs(r - HORIZON * 1.08) * 14.0);
    float grazing = pow(1.0 - abs(dot(n, dir)), 3.0);
    vec3 caustic = vec3(0.54, 1.10, 1.35) * throat * grazing * 0.16;

    return diskGlow + midline + jet + caustic;
}

vec3 trace_white_hole(vec3 ro, vec3 rd)
{
    vec3 p = ro;
    vec3 d = normalize(rd);
    vec3 glow = vec3(0.0);
    float travel = 0.0;
    float closest = 999.0;
    vec3 closestPoint = p;

    for (int i = 0; i < 260; ++i) {
        float r = length(p);
        if (r < closest) {
            closest = r;
            closestPoint = p;
        }

        if (r < HORIZON * 1.018) {
            return glow + horizon_emission(p, d, travel);
        }

        if (r > FAR_LIMIT && dot(p, d) > 0.0) {
            vec3 bg = lensed_sky(d, closest, closestPoint);
            float photonRing = exp(-pow(closest - PHOTON_RHO, 2.0) * 26.0);
            float horizonRim = exp(-pow(max(closest - HORIZON * 1.65, 0.0), 2.0) * 10.0);
            bg += vec3(0.70, 0.90, 1.30) * photonRing * 1.35;
            bg += vec3(1.00, 0.62, 0.30) * horizonRim * 0.28;
            return glow + bg;
        }

        float stepLen = clamp(r * 0.040, 0.010, 0.24);
        vec3 g = grad_logn(p);
        d = normalize(d + (g - d * dot(d, g)) * stepLen);
        p += d * stepLen;
        travel += stepLen;

        vec3 e = local_emission(p, d);
        float extinction = exp(-0.010 * travel);
        glow += e * stepLen * extinction;
    }

    return glow + lensed_sky(d, closest, closestPoint) * 0.25;
}

void main()
{
    vec2 ndc = g_ndc;
    vec2 pixel = ndc + u_projection_center;
    float aspect = max(u_resolution.x / max(u_resolution.y, 1.0), 0.25);
    pixel.x *= aspect;

    float yaw = u_camera_yaw;
    float pitch = clamp(u_camera_pitch, -1.42, 1.42);
    float distance = max(u_camera_distance, 3.0);
    float cp = cos(pitch);
    vec3 eye = distance * vec3(sin(yaw) * cp, sin(pitch), cos(yaw) * cp);
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 forward = normalize(target - eye);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);

    float fov = radians(74.0);
    vec2 film = pixel * tan(fov * 0.5);
    vec3 rd = normalize(right * film.x + up * film.y + forward);
    vec3 color = trace_white_hole(eye, rd);

    float vignette = smoothstep(1.25, 0.18, length(ndc));
    color *= 0.72 + 0.28 * vignette;
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(0.4545));

    fragColor = vec4(color, 1.0);
}
