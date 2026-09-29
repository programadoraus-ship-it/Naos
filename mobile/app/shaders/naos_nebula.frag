#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uTime;
uniform float uWarpStrength;

out vec4 fragColor;

// ============================================================
// HASH
// ============================================================

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);

    return fract(p.x * p.y);
}

// ============================================================
// NOISE
// ============================================================

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );
}

// ============================================================
// FBM
// ============================================================

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 5; i++) {
        value += noise(p) * amplitude;

        p *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// ============================================================
// DISTORSIÓN ESPACIAL
// ============================================================

vec2 spatialDistortion(
    vec2 uv,
    float time
) {
    vec2 p = uv;

    p.x += time * 0.025;

    float waveX =
        sin(
            p.y * 7.0 +
            time * 1.2
        ) *
        0.012;

    float waveY =
        sin(
            p.x * 5.0 -
            time * 0.9
        ) *
        0.009;

    p.x += waveX;
    p.y += waveY;

    return p;
}

// ============================================================
// WARP
// ============================================================

float warpLines(
    vec2 uv,
    float time
) {
    vec2 center =
        vec2(
            0.34,
            0.50
        );

    vec2 delta =
        uv -
        center;

    float radius =
        length(delta);

    float angle =
        atan(
            delta.y,
            delta.x
        );

    // --------------------------------------------------------
    // LÍNEAS RADIALES
    // --------------------------------------------------------

    float radial =
        sin(
            radius * 95.0 -
            time * 7.0
        );

    // --------------------------------------------------------
    // VARIACIÓN ANGULAR
    // --------------------------------------------------------

    float angular =
        sin(
            angle * 8.0 +
            time * 0.7
        );

    float lines =
        radial *
        (
            0.55 +
            angular * 0.20
        );

    // --------------------------------------------------------
    // MÁSCARA
    // --------------------------------------------------------

    float mask =
        smoothstep(
            0.10,
            0.75,
            radius
        );

    mask *=
        1.0 -
        smoothstep(
            0.68,
            0.95,
            radius
        );

    return
        max(
            lines,
            0.0
        ) *
        mask;
}

// ============================================================
// DISTORSIÓN LOCAL
// ============================================================

vec2 localWarp(
    vec2 uv,
    float time,
    float warpStrength
) {
    vec2 center =
        vec2(
            0.34,
            0.50
        );

    vec2 offset =
        uv -
        center;

    float radius =
        length(offset);

    float influence =
        1.0 -
        smoothstep(
            0.04,
            0.45,
            radius
        );

    // --------------------------------------------------------
    // ONDA
    // --------------------------------------------------------

    float wave =
        sin(
            radius * 35.0 -
            time * 4.5
        );

    // --------------------------------------------------------
    // FUERZA
    // --------------------------------------------------------

    float strength =
        wave *
        influence *
        0.008 *
        warpStrength;

    vec2 direction =
        normalize(
            offset +
            vec2(
                0.0001,
                0.0001
            )
        );

    return uv +
        direction *
        strength;
}

// ============================================================
// WARP DE VELOCIDAD
// ============================================================

float velocityWarp(
    vec2 uv,
    float time,
    float warpStrength
) {
    vec2 center =
        vec2(
            0.34,
            0.50
        );

    vec2 delta =
        uv -
        center;

    float radius =
        length(delta);

    // --------------------------------------------------------
    // LÍNEAS ALARGADAS
    // --------------------------------------------------------

    float streak =
        sin(
            radius * 150.0 -
            time * 12.0
        );

    streak =
        smoothstep(
            0.35,
            1.0,
            streak
        );

    // --------------------------------------------------------
    // MÁS FUERTE EN LOS BORDES
    // --------------------------------------------------------

    float edge =
        smoothstep(
            0.18,
            0.80,
            radius
        );

    // --------------------------------------------------------
    // INTENSIDAD
    // --------------------------------------------------------

    return
        streak *
        edge *
        warpStrength;
}

// ============================================================
// MAIN
// ============================================================

void main() {
    vec2 resolution =
        vec2(
            uWidth,
            uHeight
        );

    vec2 uv =
        FlutterFragCoord().xy /
        resolution;

    float time =
        uTime;

    // --------------------------------------------------------
    // LIMITAR WARP
    // --------------------------------------------------------

    float warpStrength =
        clamp(
            uWarpStrength,
            0.0,
            1.0
        );

    // --------------------------------------------------------
    // DISTORSIÓN GLOBAL
    // --------------------------------------------------------

    vec2 distortedUV =
        spatialDistortion(
            uv,
            time
        );

    // --------------------------------------------------------
    // DISTORSIÓN LOCAL
    // --------------------------------------------------------

    distortedUV =
        localWarp(
            distortedUV,
            time,
            warpStrength
        );

    // --------------------------------------------------------
    // CENTRO
    // --------------------------------------------------------

    vec2 centered =
        distortedUV -
        0.5;

    centered.x *=
        resolution.x /
        resolution.y;

    // --------------------------------------------------------
    // NEBULOSA
    // --------------------------------------------------------

    vec2 nebulaUV =
        centered *
        2.2;

    nebulaUV.x +=
        time *
        0.018;

    nebulaUV.y +=
        sin(
            time * 0.4
        ) *
        0.025;

    // --------------------------------------------------------
    // CAPA PRINCIPAL
    // --------------------------------------------------------

    float n1 =
        fbm(
            nebulaUV *
            1.15
        );

    // --------------------------------------------------------
    // CAPA SECUNDARIA
    // --------------------------------------------------------

    float n2 =
        fbm(
            nebulaUV *
            2.4 +
            vec2(
                time * 0.012,
                -time * 0.008
            )
        );

    float cloud =
        n1 * 0.65 +
        n2 * 0.35;

    // --------------------------------------------------------
    // PROFUNDIDAD
    // --------------------------------------------------------

    float distanceFromCenter =
        length(centered);

    float falloff =
        1.0 -
        smoothstep(
            0.12,
            0.90,
            distanceFromCenter
        );

    cloud *=
        falloff;

    // --------------------------------------------------------
    // COLORES ESPACIALES
    // --------------------------------------------------------

    vec3 deepSpace =
        vec3(
            0.005,
            0.008,
            0.035
        );

    vec3 violet =
        vec3(
            0.10,
            0.075,
            0.35
        );

    vec3 blue =
        vec3(
            0.06,
            0.15,
            0.50
        );

    vec3 nebulaColor =
        mix(
            violet,
            blue,
            n2
        );

    // --------------------------------------------------------
    // WARP NORMAL
    // --------------------------------------------------------

    float warp =
        warpLines(
            distortedUV,
            time
        );

    float warpIntensity =
        warp *
        0.055 *
        warpStrength;

    vec3 warpColor =
        vec3(
            0.20,
            0.32,
            0.85
        );

    nebulaColor +=
        warpColor *
        warpIntensity;

    // --------------------------------------------------------
    // WARP POR VELOCIDAD
    // --------------------------------------------------------

    float velocityEffect =
        velocityWarp(
            distortedUV,
            time,
            warpStrength
        );

    vec3 velocityColor =
        vec3(
            0.30,
            0.45,
            1.00
        );

    nebulaColor +=
        velocityColor *
        velocityEffect *
        0.035;

    // --------------------------------------------------------
    // DISTORSIÓN LUMINOSA
    // --------------------------------------------------------

    float distortion =
        abs(
            sin(
                distanceFromCenter * 28.0 -
                time * 2.5
            )
        );

    distortion *=
        0.018 *
        falloff *
        (
            0.5 +
            warpStrength * 0.5
        );

    nebulaColor +=
        vec3(
            0.025,
            0.035,
            0.10
        ) *
        distortion;

    // --------------------------------------------------------
    // INTENSIDAD BASE
    // --------------------------------------------------------

    float intensity =
        cloud *
        0.22;

    intensity *=
        falloff;

    // --------------------------------------------------------
    // INTENSIDAD DEL WARP
    // --------------------------------------------------------

    intensity +=
        warpIntensity *
        (
            0.20 +
            warpStrength * 0.35
        );

    intensity +=
        velocityEffect *
        0.012;

    // --------------------------------------------------------
    // RESULTADO
    // --------------------------------------------------------

    vec3 finalColor =
        deepSpace +
        nebulaColor *
        intensity;

    fragColor =
        vec4(
            finalColor,
            intensity
        );
}