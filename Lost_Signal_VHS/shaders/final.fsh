#version 120

// Full analog playback/display pass. composite supplies the first tape encode,
// temporal history, and camera instability; this pass adds the deliberately
// heavy second-generation VCR/CRT character that defines the original look.
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int frameCounter;

varying vec2 texcoord;

#include "/lib/settings.glsl"

const float PI = 3.14159265358979323846;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 safeUV(vec2 uv, vec2 pixel) {
    return clamp(uv, pixel * 2.0, vec2(1.0) - pixel * 2.0);
}

vec3 rgbToYiq(vec3 rgb) {
    return vec3(
        dot(rgb, vec3(0.299, 0.587, 0.114)),
        dot(rgb, vec3(0.596, -0.274, -0.322)),
        dot(rgb, vec3(0.211, -0.523, 0.312))
    );
}

vec3 yiqToRgb(vec3 yiq) {
    return vec3(
        yiq.x + 0.956 * yiq.y + 0.621 * yiq.z,
        yiq.x - 0.272 * yiq.y - 0.647 * yiq.z,
        yiq.x - 1.106 * yiq.y + 1.703 * yiq.z
    );
}

// -----------------------------------------------------------------------------
// Tiny procedural VCR font. The intentionally blocky glyphs are softened by
// the tape image and resemble the white deck OSD in the supplied reference.
// -----------------------------------------------------------------------------
float boxMask(vec2 p, vec2 lower, vec2 upper) {
    vec2 insideLower = step(lower, p);
    vec2 insideUpper = vec2(1.0) - step(upper, p);
    return insideLower.x * insideLower.y * insideUpper.x * insideUpper.y;
}

float lineMask(vec2 p, vec2 a, vec2 b, float width) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
    float distanceToLine = length(pa - ba * h);
    return 1.0 - smoothstep(width, width + 0.035, distanceToLine);
}

float glyphP(vec2 p) {
    float g = boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.95));
    g = max(g, boxMask(p, vec2(0.15, 0.80), vec2(0.80, 0.95)));
    g = max(g, boxMask(p, vec2(0.15, 0.47), vec2(0.80, 0.62)));
    g = max(g, boxMask(p, vec2(0.67, 0.53), vec2(0.84, 0.88)));
    return g;
}

float glyphL(vec2 p) {
    return max(boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.95)),
               boxMask(p, vec2(0.15, 0.05), vec2(0.85, 0.20)));
}

float glyphA(vec2 p) {
    float g = boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.85));
    g = max(g, boxMask(p, vec2(0.70, 0.05), vec2(0.87, 0.85)));
    g = max(g, boxMask(p, vec2(0.15, 0.80), vec2(0.80, 0.95)));
    g = max(g, boxMask(p, vec2(0.15, 0.46), vec2(0.80, 0.61)));
    return g;
}

float glyphY(vec2 p) {
    float g = lineMask(p, vec2(0.12, 0.90), vec2(0.48, 0.53), 0.09);
    g = max(g, lineMask(p, vec2(0.84, 0.90), vec2(0.48, 0.53), 0.09));
    g = max(g, boxMask(p, vec2(0.40, 0.05), vec2(0.57, 0.58)));
    return g;
}

float glyphS(vec2 p) {
    float g = boxMask(p, vec2(0.15, 0.80), vec2(0.85, 0.95));
    g = max(g, boxMask(p, vec2(0.08, 0.50), vec2(0.25, 0.88)));
    g = max(g, boxMask(p, vec2(0.15, 0.43), vec2(0.80, 0.58)));
    g = max(g, boxMask(p, vec2(0.70, 0.12), vec2(0.87, 0.52)));
    g = max(g, boxMask(p, vec2(0.12, 0.05), vec2(0.80, 0.20)));
    return g;
}

float glyphT(vec2 p) {
    return max(boxMask(p, vec2(0.08, 0.80), vec2(0.90, 0.95)),
               boxMask(p, vec2(0.41, 0.05), vec2(0.58, 0.88)));
}

float glyphR(vec2 p) {
    float g = glyphP(p);
    g = max(g, lineMask(p, vec2(0.48, 0.50), vec2(0.88, 0.05), 0.09));
    return g;
}

float glyphC(vec2 p) {
    float g = boxMask(p, vec2(0.10, 0.10), vec2(0.27, 0.90));
    g = max(g, boxMask(p, vec2(0.18, 0.80), vec2(0.88, 0.95)));
    g = max(g, boxMask(p, vec2(0.18, 0.05), vec2(0.88, 0.20)));
    return g;
}

float glyphK(vec2 p) {
    float g = boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.95));
    g = max(g, lineMask(p, vec2(0.20, 0.50), vec2(0.84, 0.94), 0.09));
    g = max(g, lineMask(p, vec2(0.20, 0.50), vec2(0.84, 0.06), 0.09));
    return g;
}

float glyphI(vec2 p) {
    float g = boxMask(p, vec2(0.10, 0.80), vec2(0.88, 0.95));
    g = max(g, boxMask(p, vec2(0.41, 0.05), vec2(0.58, 0.90)));
    g = max(g, boxMask(p, vec2(0.10, 0.05), vec2(0.88, 0.20)));
    return g;
}

float glyphN(vec2 p) {
    float g = boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.95));
    g = max(g, boxMask(p, vec2(0.72, 0.05), vec2(0.89, 0.95)));
    g = max(g, lineMask(p, vec2(0.18, 0.88), vec2(0.80, 0.12), 0.08));
    return g;
}

float glyphG(vec2 p) {
    float g = glyphC(p);
    g = max(g, boxMask(p, vec2(0.48, 0.42), vec2(0.88, 0.57)));
    g = max(g, boxMask(p, vec2(0.72, 0.10), vec2(0.89, 0.55)));
    return g;
}

float playbackOsd(vec2 uv, float time) {
    vec2 bigSize = vec2(0.043, 0.082);
    float osd = 0.0;

    // PLAY at upper left.
    osd = max(osd, glyphP((uv - vec2(0.105, 0.825)) / bigSize));
    osd = max(osd, glyphL((uv - vec2(0.150, 0.825)) / bigSize));
    osd = max(osd, glyphA((uv - vec2(0.195, 0.825)) / bigSize));
    osd = max(osd, glyphY((uv - vec2(0.240, 0.825)) / bigSize));

    // Solid playback triangle.
    vec2 triangleUv = (uv - vec2(0.493, 0.827)) / vec2(0.060, 0.085);
    float triangle = step(0.05, triangleUv.x) * step(triangleUv.x, 0.92)
                   * step(abs(triangleUv.y - 0.5), triangleUv.x * 0.53);
    osd = max(osd, triangle);

    // SLP recording speed at upper right.
    osd = max(osd, glyphS((uv - vec2(0.700, 0.825)) / bigSize));
    osd = max(osd, glyphL((uv - vec2(0.745, 0.825)) / bigSize));
    osd = max(osd, glyphP((uv - vec2(0.790, 0.825)) / bigSize));

    // The tracking calibration appears briefly every few seconds, like a VCR
    // being adjusted after playback starts.
    float trackingPulse = 1.0 - step(0.24, fract(time * 0.14));
    vec2 smallSize = vec2(0.027, 0.052);
    float tracking = 0.0;
    tracking = max(tracking, glyphT((uv - vec2(0.080, 0.075)) / smallSize));
    tracking = max(tracking, glyphR((uv - vec2(0.109, 0.075)) / smallSize));
    tracking = max(tracking, glyphA((uv - vec2(0.138, 0.075)) / smallSize));
    tracking = max(tracking, glyphC((uv - vec2(0.167, 0.075)) / smallSize));
    tracking = max(tracking, glyphK((uv - vec2(0.196, 0.075)) / smallSize));
    tracking = max(tracking, glyphI((uv - vec2(0.225, 0.075)) / smallSize));
    tracking = max(tracking, glyphN((uv - vec2(0.254, 0.075)) / smallSize));
    tracking = max(tracking, glyphG((uv - vec2(0.283, 0.075)) / smallSize));

    float dashes = boxMask(uv, vec2(0.350, 0.098), vec2(0.845, 0.111))
                 * step(0.46, fract(uv.x * 34.0));
    float leftBracket = boxMask(uv, vec2(0.333, 0.075), vec2(0.346, 0.135));
    float rightBracket = boxMask(uv, vec2(0.850, 0.075), vec2(0.863, 0.135));
    float markerX = 0.59 + sin(time * 0.43) * 0.10;
    float marker = 1.0 - smoothstep(0.014, 0.019,
                                    length((uv - vec2(markerX, 0.104))
                                           * vec2(1.0, 1.35)));
    tracking = max(tracking, max(dashes, max(leftBracket, rightBracket)));
    tracking = max(tracking, marker);
    osd = max(osd, tracking * trackingPulse);
    return clamp(osd, 0.0, 1.0);
}

void main() {
    vec2 resolution = vec2(viewWidth, viewHeight);
    vec2 pixel = 1.0 / resolution;
    float displayScale = max(1.0, viewHeight / 720.0);
    float time = frameTimeCounter;
    float frame = float(frameCounter);
    float aspect = viewWidth / viewHeight;

    // 4:3 deck playback framing. Center-crop rather than squeeze the world.
    vec2 frameUv = texcoord;
    vec2 sourceUv = texcoord;
    float frameMask = 1.0;

#ifdef VHS_4_3
    float targetAspect = 4.0 / 3.0;
    float playbackWidth = min(1.0, targetAspect / aspect);
    float playbackLeft = 0.5 - playbackWidth * 0.5;
    float playbackRight = 0.5 + playbackWidth * 0.5;
    frameMask = step(playbackLeft, texcoord.x)
              * (1.0 - step(playbackRight, texcoord.x));
    frameUv = vec2((texcoord.x - playbackLeft) / playbackWidth, texcoord.y);
    frameUv = clamp(frameUv, 0.0, 1.0);

    float sourceCropWidth = min(1.0, targetAspect / aspect);
    sourceUv = vec2(0.5 + (frameUv.x - 0.5) * sourceCropWidth, frameUv.y);

    // Avoid all expensive tape taps in the black pillarbox area.
    if (frameMask < 0.5) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
#endif

    // Handheld drift and frame jitter are held rather than smoothly animated,
    // preventing the movement from looking like a modern camera animation.
    vec2 wobblePixels = vec2(
        sin(time * 1.13) + 0.43 * sin(time * 2.71 + 1.2),
        0.62 * sin(time * 0.83 + 2.1) + 0.28 * sin(time * 2.03)
    ) * WOBBLE_STRENGTH * displayScale;
    float jitterFrame = floor(frame * 0.5);
    vec2 jitterPixels = vec2(
        hash21(vec2(jitterFrame, 17.0)) - 0.5,
        hash21(vec2(jitterFrame, 53.0)) - 0.5
    ) * (2.0 * FRAME_JITTER * displayScale);
    sourceUv += (wobblePixels + jitterPixels) * pixel;

    // Horizontal time-base error follows raster lines. Rare gated events create
    // stronger tracking tears without turning into rectangular digital glitches.
    float glitchTick = floor(time * 9.0);
    float glitchEvent = step(1.0 - GLITCH_FREQUENCY,
                             hash21(vec2(glitchTick, 19.37)));
    float lineBlock = floor(frameUv.y * 52.0);
    float glitchBand = glitchEvent
                     * step(0.58, hash21(vec2(lineBlock, glitchTick)));
    float glitchDirection = hash21(vec2(lineBlock + 9.1, glitchTick)) * 2.0 - 1.0;
    float glitchPixels = glitchBand * glitchDirection * GLITCH_STRENGTH;
    float rasterGroup = floor(frameUv.y * 480.0 / 3.0);
    float lineTiming = hash21(vec2(rasterGroup, floor(time * 12.0))) - 0.5;
    lineTiming += sin(frameUv.y * 41.0 + time * 1.7) * 0.18;
    glitchPixels += lineTiming * (0.45 + glitchEvent * GLITCH_STRENGTH * 0.12);

    float trackingY = fract(time * 0.071 + 0.13 * sin(time * 0.19));
    float trackingDistance = abs(frameUv.y - trackingY);
    trackingDistance = min(trackingDistance, 1.0 - trackingDistance);
    float trackingBand = pow(max(0.0, 1.0 - trackingDistance * 42.0), 3.0);
    glitchPixels += trackingBand * sin(time * 17.0) * GLITCH_STRENGTH * 0.22;
    sourceUv.x += glitchPixels * displayScale * pixel.x;

    // Cheap camcorder lens distortion. This happens before all signal damage so
    // noise remains screen-aligned, as it would when added during tape playback.
    vec2 lensUv = sourceUv * 2.0 - 1.0;
    lensUv.x *= aspect;
    float lensRadius2 = dot(lensUv, lensUv);
    lensUv *= 1.0 + LENS_DISTORTION * lensRadius2;
    lensUv.x /= aspect;
    sourceUv = lensUv * 0.5 + 0.5;

    // Do not let lens distortion secretly recreate rounded corners when the
    // rounded-frame option is disabled.
    float lensMask = 1.0;
#ifdef ROUNDED_OVERSCAN
    vec2 sourceInside = smoothstep(vec2(0.0), pixel * 4.0, sourceUv)
                      * (vec2(1.0) - smoothstep(vec2(1.0) - pixel * 4.0,
                                                vec2(1.0), sourceUv));
    lensMask = sourceInside.x * sourceInside.y;
#endif

    // Bottom head-switching noise bends only the overscan area.
    float headZone = 1.0 - smoothstep(0.012, 0.065, frameUv.y);
    float headRandom = hash21(vec2(floor(frameUv.y * 220.0),
                                   floor(time * 24.0))) - 0.5;
    float headWave = sin(frameUv.y * 510.0 + time * 37.0) * 0.5 + headRandom;
    sourceUv.x += headZone * headWave * HEAD_SWITCHING * 0.055;
    sourceUv.y += headZone * headRandom * HEAD_SWITCHING * 0.010;
    sourceUv.x += sin(frameUv.y * 470.0 + time * 2.7)
                * pixel.x * displayScale * 0.80;
    sourceUv = safeUV(sourceUv, pixel);

    // Soften luminance mostly in the horizontal direction. Avoid quantizing the
    // UV itself: discontinuous derivatives caused terrain sampling problems on
    // Minecraft 1.21.11 / Iris 1.10.x on Apple Metal.
    float softRadius = TAPE_SOFTNESS * displayScale;
    vec2 blurX = vec2(pixel.x * softRadius, 0.0);

    vec3 center = texture2D(colortex0, sourceUv).rgb;
    vec3 lumaLeft1 = texture2D(colortex0, safeUV(sourceUv - blurX, pixel)).rgb;
    vec3 lumaRight1 = texture2D(colortex0, safeUV(sourceUv + blurX, pixel)).rgb;
    vec3 lumaLeft2 = texture2D(colortex0, safeUV(sourceUv - blurX * 2.0, pixel)).rgb;
    vec3 lumaRight2 = texture2D(colortex0, safeUV(sourceUv + blurX * 2.0, pixel)).rgb;
    vec3 lumaImage = center * 0.44;
    lumaImage += (lumaLeft1 + lumaRight1) * 0.18;
    lumaImage += (lumaLeft2 + lumaRight2) * 0.10;
    float tapeLuma = dot(lumaImage, vec3(0.299, 0.587, 0.114));

    // Consumer decks sharpen soft luminance electronically. Their crude delay
    // line creates a bright leading halo and a dark trailing halo rather than
    // clean modern sharpening—the strong outlines visible in the references.
    float centerLuma = dot(center, vec3(0.299, 0.587, 0.114));
    float delayedLuma = dot(lumaRight2, vec3(0.299, 0.587, 0.114));
    float lumaOvershoot = (centerLuma - tapeLuma) * 0.62
                        + (tapeLuma - delayedLuma) * 0.24;
    tapeLuma += lumaOvershoot * LUMA_RINGING;

    // Low chroma bandwidth without a fragile render-buffer conversion. Broad
    // asymmetric color taps are combined with the sharper luminance signal.
    vec2 bleed = vec2((CHROMA_BLEED + CHROMA_AMOUNT * 0.50)
                      * displayScale * pixel.x, 0.0);
    float chromaLine = floor(frameUv.y * 240.0);
    float chromaPhase = hash21(vec2(chromaLine, floor(time * 8.0))) - 0.5;
    chromaPhase += sin(frameUv.y * 37.0 + time * 1.3) * 0.18;
    vec2 chromaDrift = vec2(chromaPhase * (0.9 + CHROMA_AMOUNT * 0.22)
                            * displayScale * pixel.x, 0.0);
    vec2 chromaUv = safeUV(sourceUv + chromaDrift, pixel);
    vec3 chromaImage = texture2D(colortex0, chromaUv).rgb * 0.34;
    chromaImage += texture2D(colortex0, safeUV(chromaUv - bleed, pixel)).rgb * 0.25;
    chromaImage += texture2D(colortex0, safeUV(chromaUv + bleed, pixel)).rgb * 0.19;
    chromaImage += texture2D(colortex0, safeUV(chromaUv - bleed * 2.0, pixel)).rgb * 0.13;
    chromaImage += texture2D(colortex0, safeUV(chromaUv + bleed * 2.0, pixel)).rgb * 0.09;
    float chromaLuma = dot(chromaImage, vec3(0.299, 0.587, 0.114));
    vec3 color = vec3(tapeLuma)
               + (chromaImage - vec3(chromaLuma)) * COLOR_SATURATION;

    // Direct R/B displacement adds cheap-camera color fringing while preserving
    // the luminance reconstructed above.
    vec2 splitOffset = vec2(CHROMA_AMOUNT * displayScale * pixel.x, 0.0);
    vec3 splitRgb = vec3(
        texture2D(colortex0, safeUV(chromaUv + splitOffset, pixel)).r,
        center.g,
        texture2D(colortex0, safeUV(chromaUv - splitOffset, pixel)).b
    );
    float splitLuma = dot(splitRgb, vec3(0.299, 0.587, 0.114));
    color += (splitRgb - vec3(splitLuma))
           * clamp(CHROMA_AMOUNT / 9.0, 0.0, 1.0) * 0.42;

    // One-frame-independent spatial echo is the stable 1.21.11 substitute for
    // persistent history. It leaves a soft trail on high-contrast moving edges.
    vec2 echoOffset = vec2((MOTION_SMEAR + 1.0) * displayScale * pixel.x, 0.0);
    vec3 echoRgb = texture2D(colortex0, safeUV(sourceUv - echoOffset, pixel)).rgb;
    color = mix(color, echoRgb, clamp(GHOST_STRENGTH * 0.42, 0.0, 0.18));

    // Signal-domain-looking coarse luma and colored chroma noise.
    vec2 noiseCell = floor(frameUv * vec2(480.0, 480.0)
                           / max(1.0, PIXEL_SCALE * 0.70));
    float grain = hash21(noiseCell + vec2(frame * 1.91, frame * 0.43)) - 0.5;
    float lineNoise = hash21(vec2(floor(frameUv.y * 480.0),
                                  floor(time * 31.0))) - 0.5;
    float chromaNoiseI = hash21(noiseCell * vec2(0.37, 1.0)
                                + vec2(frame * 0.71, 43.1)) - 0.5;
    float chromaNoiseQ = hash21(noiseCell * vec2(0.29, 1.0)
                                + vec2(frame * 0.53, 91.7)) - 0.5;
    color += vec3(grain * NOISE_STRENGTH * 0.54
                  + lineNoise * NOISE_STRENGTH * 0.17);
    color += vec3(chromaNoiseI, -chromaNoiseI * 0.36, chromaNoiseQ)
           * NOISE_STRENGTH * 0.18;

    // Real capture grade: muted contrast, weak blue response, and green cast.
    color *= mix(vec3(1.0), vec3(0.94, 1.12, 0.72), TINT_STRENGTH * 0.92);
    color = (color - 0.5) * mix(1.0, 0.86, WASHOUT_STRENGTH) + 0.5;
    color = max(color - vec3(BLACK_CRUSH * 0.028), vec3(0.0));
    color = pow(max(color, vec3(0.0)), vec3(1.0 + BLACK_CRUSH * 0.88));

    float highlightBloom = smoothstep(0.68, 0.96, tapeLuma);
    color += vec3(tapeLuma) * highlightBloom * HALATION_STRENGTH * 0.18;

    // Uneven exposure flutter.
    float flickerWave = sin(time * 19.7) * 0.50
                      + sin(time * 7.3 + 2.0) * 0.28
                      + (hash21(vec2(frame, 31.0)) - 0.5) * 0.90;
    color *= 1.0 + flickerWave * FLICKER_STRENGTH;

    // Alternate field parity every frame. This reads as interlaced analog video
    // instead of a stationary digital CRT overlay.
    float tapeLine = floor(frameUv.y * 480.0);
    float fieldParity = mod(frame, 2.0);
    float fieldLine = mod(tapeLine + fieldParity, 2.0);
    float fineScan = 0.5 + 0.5 * sin(frameUv.y * viewHeight / displayScale * PI);
    color *= 1.0 - SCANLINE_STRENGTH
                   * (0.07 + fieldLine * 0.18 + fineScan * 0.05);

    // A rare dropout is a short horizontal loss of signal with a noisy tail.
    // Its probability follows the tracking control, so clean presets stay calm.
    float dropoutTick = floor(time * 8.0);
    float dropoutEvent = step(1.0 - GLITCH_FREQUENCY * 0.18,
                              hash21(vec2(dropoutTick, 73.9)));
    float dropoutY = hash21(vec2(dropoutTick, 22.4));
    float dropoutBand = 1.0 - smoothstep(0.0015, 0.0060,
                                        abs(frameUv.y - dropoutY));
    float dropoutStart = hash21(vec2(dropoutTick, 49.2));
    float dropoutDistance = abs(fract(frameUv.x - dropoutStart + 0.5) - 0.5);
    float dropoutWidth = 0.06 + hash21(vec2(dropoutTick, 18.6)) * 0.22;
    float dropoutSpan = 1.0 - smoothstep(dropoutWidth,
                                        dropoutWidth + 0.025,
                                        dropoutDistance);
    float dropoutNoise = hash21(vec2(floor(frameUv.x * 320.0),
                                     tapeLine + frame * 3.0));
    float dropout = dropoutEvent * dropoutBand * dropoutSpan;
    color = mix(color, vec3(0.52 + dropoutNoise * 0.42), dropout * 0.74);

    // Static appears as brief bursts, not permanent film grain. A line mask
    // gives each burst the clustered bands seen when a VCR momentarily loses RF.
    float staticPhase = time * 2.0;
    float staticTick = floor(staticPhase);
    float staticEvent = step(1.0 - STATIC_FREQUENCY,
                             hash21(vec2(staticTick, 117.3)));
    float staticWindow = 1.0 - step(0.14, fract(staticPhase));
    float staticValue = hash21(floor(frameUv * vec2(360.0, 260.0))
                               + vec2(frame * 2.7, frame * 0.9));
    float staticLine = step(0.80, hash21(vec2(tapeLine,
                                              floor(time * 42.0))));
    float staticMix = staticEvent * staticWindow * (0.28 + staticLine * 0.48);
    color = mix(color, vec3(staticValue), staticMix);

    // Head-switching area mixes in bright/black line noise at the frame bottom.
    float headStatic = hash21(vec2(floor(frameUv.x * 260.0) + frame * 5.0,
                                   floor(frameUv.y * 520.0) + frame * 2.0));
    vec3 headColor = vec3(step(0.42, headStatic) * 0.72);
    color = mix(color, headColor, headZone * HEAD_SWITCHING * 0.58);

    // Soft optical falloff inside the playback image.
    vec2 vignettePos = frameUv * 2.0 - 1.0;
    float vignetteRadius = dot(vignettePos * vec2(0.78, 1.0),
                               vignettePos * vec2(0.78, 1.0));
    float vignette = smoothstep(0.24, 1.25, vignetteRadius);
    color *= 1.0 - vignette * VIGNETTE_STRENGTH * 0.78;

#ifdef ROUNDED_OVERSCAN
    // Signed rounded-rectangle mask in physical 4:3 frame proportions.
    vec2 roundedPosition = (frameUv - 0.5) * vec2(4.0 / 3.0, 1.0);
    vec2 roundedDelta = abs(roundedPosition) - vec2(0.620, 0.455);
    float roundedDistance = length(max(roundedDelta, vec2(0.0)))
                          + min(max(roundedDelta.x, roundedDelta.y), 0.0)
                          - 0.040;
    float overscanMask = 1.0 - smoothstep(-0.008, 0.010, roundedDistance);
    frameMask *= overscanMask;
#endif

    color *= frameMask * lensMask;

#ifdef VHS_OSD
    // VCR-generated OSD sits above the recorded image but remains inside the
    // analog playback frame. A dark echo gives the white glyphs tape-like bloom.
    float osd = 0.0;
    if (frameUv.y > 0.78 || frameUv.y < 0.16) {
        osd = playbackOsd(frameUv, time) * frameMask;
    }
    color *= 1.0 - osd * 0.26;
    color = mix(color, vec3(0.96, 0.98, 0.91), osd * 0.94);
#endif

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
