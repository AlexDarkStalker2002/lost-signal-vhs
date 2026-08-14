#version 120

// Main VHS post-processing pass.
// colortex0 = Minecraft's current rendered scene.
// colortex4 = last frame's fully processed VHS image.
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int frameCounter;

varying vec2 texcoord;

#include "/lib/settings.glsl"
#include "/lib/analog_color.glsl"

// Keep the history texture between frames. composite1 refreshes it at the end
// of every frame. The frameCounter guard below avoids sampling it at startup.
const bool colortex4Clear = false;

/* RENDERTARGETS: 0 */

const float PI = 3.14159265358979323846;

// Small deterministic hashes replace an external noise texture. They are cheap,
// stable on GLSL 1.20 hardware, and change whenever their input seed changes.
float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Bilinearly interpolated value noise. Unlike independent line hashes, this
// stays correlated across neighboring raster lines and evolves continuously in
// time, matching mechanical time-base error instead of digital block glitches.
float smoothNoise21(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    vec2 curve = local * local * (3.0 - 2.0 * local);
    float lower = mix(hash21(cell),
                      hash21(cell + vec2(1.0, 0.0)),
                      curve.x);
    float upper = mix(hash21(cell + vec2(0.0, 1.0)),
                      hash21(cell + vec2(1.0, 1.0)),
                      curve.x);
    return mix(lower, upper, curve.y);
}

vec2 clampUV(vec2 uv, vec2 pixel) {
    return clamp(uv, pixel * 1.5, vec2(1.0) - pixel * 1.5);
}

// Quantize texture coordinates rather than resizing the render target. This
// suggests a low-resolution CCD/tape transfer while retaining the real output
// resolution and a crisp HUD rendered by Minecraft after the shader pipeline.
vec2 virtualPixels(vec2 uv, vec2 resolution) {
    vec2 virtualResolution = max(resolution / PIXEL_SCALE, vec2(1.0));
    return (floor(uv * virtualResolution) + 0.5) / virtualResolution;
}

// Fog palettes approximate air recorded by consumer cameras rather than a
// physically perfect participating medium. The fog is inserted before YIQ
// encoding so its color is degraded by the same tape and decoder path.
vec3 analogFogColor() {
#if FOG_MODE == 2
    return vec3(0.61, 0.58, 0.36);
#elif FOG_MODE == 3
    return vec3(0.37, 0.62, 0.66);
#elif FOG_MODE == 4
    return vec3(0.20, 0.31, 0.27);
#else
    return vec3(0.53, 0.55, 0.52);
#endif
}

// Reconstruct view distance from the depth buffer. Special geometry whose
// depth disagrees with depthtex2 (the hand and many translucent surfaces) is
// left clear to avoid fogging the first-person overlay on older Iris versions.
float analogFogAmount(vec2 screenUv, float time) {
#if FOG_MODE == 0
    return 0.0;
#else
    float depth = texture2D(depthtex0, screenUv).r;
    if (depth >= 0.99998) {
        float horizon = 1.0 - smoothstep(0.48, 0.90, screenUv.y);
        return clamp(FOG_DENSITY * mix(0.24, 0.62, horizon), 0.0, 0.55);
    }

    float stableDepth = texture2D(depthtex2, screenUv).r;
    if (abs(depth - stableDepth) > 0.0005) {
        return 0.0;
    }

    vec4 clipPosition = vec4(screenUv * 2.0 - 1.0,
                             depth * 2.0 - 1.0,
                             1.0);
    vec4 viewPosition = gbufferProjectionInverse * clipPosition;
    if (abs(viewPosition.w) <= 0.00001) {
        return 0.0;
    }
    viewPosition /= viewPosition.w;

    float viewDistance = length(viewPosition.xyz);
    float fogTravel = max(viewDistance - FOG_START, 0.0)
                    / max(FOG_DISTANCE, 1.0);
    float extinction = 1.0 - exp(-fogTravel * FOG_DENSITY * 4.0);

    vec3 worldPosition = (gbufferModelViewInverse * viewPosition).xyz
                       + cameraPosition;
    float broadNoise = smoothNoise21(worldPosition.xz * 0.035
                                   + vec2(time * 0.020, -time * 0.014));
    float verticalNoise = smoothNoise21(vec2(worldPosition.y * 0.065,
                                             dot(worldPosition.xz,
                                                 vec2(0.019, 0.027))
                                           + time * 0.011));
    float densityVariation = mix(1.0,
                                 mix(0.62, 1.38,
                                     broadNoise * 0.68
                                   + verticalNoise * 0.32),
                                 FOG_NOISE);
    return clamp(extinction * densityVariation, 0.0, 0.94);
#endif
}

// Move a current screen pixel into the previous camera frame. Sky pixels and
// invalid/off-screen projections fall back to ordinary screen-space history,
// which keeps the pack safe on dimensions and Iris versions where depth is 1.
vec2 reprojectHistoryUV(vec2 screenUv, vec2 pixel, out float confidence) {
    confidence = 0.0;
#ifdef MOTION_AWARE_HISTORY
    float depth = texture2D(depthtex0, screenUv).r;
    if (depth < 0.99998) {
        // depthtex2 excludes translucent geometry and the first-person hand.
        // Their special projection/depth paths are safer in screen space.
        float stableDepth = texture2D(depthtex2, screenUv).r;
        float depthAgreement = 1.0
                             - step(0.0005, abs(depth - stableDepth));
        vec4 clipPosition = vec4(screenUv * 2.0 - 1.0,
                                 depth * 2.0 - 1.0,
                                 1.0);
        vec4 viewPosition = gbufferProjectionInverse * clipPosition;
        if (abs(viewPosition.w) > 0.00001) {
            viewPosition /= viewPosition.w;

            vec4 worldPosition = gbufferModelViewInverse * viewPosition;
            worldPosition.xyz += cameraPosition;
            worldPosition.xyz -= previousCameraPosition;

            vec4 previousClip = gbufferPreviousProjection
                              * gbufferPreviousModelView
                              * worldPosition;
            if (previousClip.w > 0.00001) {
                vec2 previousUv = previousClip.xy / previousClip.w
                                * 0.5 + 0.5;
                vec2 lowerInside = step(vec2(0.0), previousUv);
                vec2 upperInside = step(previousUv, vec2(1.0));
                confidence = lowerInside.x * lowerInside.y
                           * upperInside.x * upperInside.y
                           * depthAgreement;
                return clampUV(previousUv, pixel);
            }
        }
    }
#endif
    return clampUV(screenUv, pixel);
}

// Washed-out tape stock plus a yellow-green security-camera cast. Luma is kept
// explicit so the washout slider changes saturation and contrast together.
vec3 gradeOldTape(vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(luma), WASHOUT_STRENGTH * 0.72);

    float contrast = mix(1.0, 0.68, WASHOUT_STRENGTH);
    color = (color - 0.5) * contrast + 0.5;

    // Lift crushed blacks and gently cap highlights like a poor analog transfer.
    color = color * mix(1.0, 0.88, WASHOUT_STRENGTH)
          + vec3(0.035 * WASHOUT_STRENGTH);

    vec3 sicklyTint = vec3(1.03, 1.09, 0.78);
    color *= mix(vec3(1.0), sicklyTint, TINT_STRENGTH);
    return color;
}

void main() {
    vec2 resolution = vec2(viewWidth, viewHeight);
    vec2 pixel = 1.0 / resolution;
    float time = frameTimeCounter;
    // Signal noise and jitter advance at the tape field rate, not at an
    // arbitrary monitor/game frame rate. This keeps the look stable at 60,
    // 144, or uncapped FPS.
    float frame = floor(time * VHS_FIELD_RATE);

    // -------------------------------------------------------------------------
    // Handheld motion, random frame jitter, and horizontal tracking glitches.
    // -------------------------------------------------------------------------

    // Wobble is deliberately made from mismatched frequencies so it never feels
    // like a clean cinematic camera animation.
    vec2 wobblePixels = vec2(
        sin(time * 1.13) + 0.43 * sin(time * 2.71 + 1.2),
        0.62 * sin(time * 0.83 + 2.1) + 0.28 * sin(time * 2.03)
    ) * WOBBLE_STRENGTH;

    // Hold jitter for two frames at a time, matching an unstable tape lock more
    // closely than smooth noise would.
    float jitterFrame = floor(frame * 0.5);
    vec2 jitterPixels = vec2(
        hash11(jitterFrame + 17.0) - 0.5,
        hash11(jitterFrame + 53.0) - 0.5
    ) * (2.0 * FRAME_JITTER);

    // Mechanical time-base error drifts continuously across neighboring raster
    // lines. Two differently scaled noise bands represent slow capstan error and
    // faster guide/head timing instability.
    float signalLine = texcoord.y * VHS_SIGNAL_LINES;
    float slowTimebase = smoothNoise21(vec2(signalLine * 0.018,
                                            time * 0.82)) * 2.0 - 1.0;
    float fastTimebase = smoothNoise21(vec2(signalLine * 0.095 + 17.0,
                                            time * 3.70)) * 2.0 - 1.0;
    float lineTimebase = slowTimebase * 0.76 + fastTimebase * 0.24;

    // Rare tracking loss forms one or two soft horizontal tears. Their envelope,
    // displacement, and edges are continuous, avoiding rectangular digital
    // blocks while still allowing violent damaged-tape events.
    float glitchPhase = time * 1.70;
    float glitchTick = floor(glitchPhase);
    float glitchAge = fract(glitchPhase);
    float glitchEvent = step(1.0 - GLITCH_FREQUENCY,
                             hash21(vec2(glitchTick, 19.37)));
    float glitchEnvelope = smoothstep(0.0, 0.035, glitchAge)
                         * (1.0 - smoothstep(0.10, 0.28, glitchAge));
    float tearCenter = hash21(vec2(glitchTick, 43.71));
    float tearWidth = mix(0.006, 0.030,
                          hash21(vec2(glitchTick, 71.13)));
    float tearDistance = abs(texcoord.y - tearCenter);
    float primaryTear = 1.0 - smoothstep(tearWidth,
                                         tearWidth * 2.4,
                                         tearDistance);
    float secondCenter = fract(tearCenter + 0.028
                               + hash21(vec2(glitchTick, 11.70)) * 0.075);
    float secondDistance = abs(texcoord.y - secondCenter);
    float secondaryTear = (1.0 - smoothstep(tearWidth * 0.45,
                                            tearWidth * 1.45,
                                            secondDistance)) * 0.58;
    float tearShape = max(primaryTear, secondaryTear);
    float tearTexture = 0.62 + 0.38 * smoothNoise21(
        vec2(signalLine * 0.055, time * 5.1 + glitchTick));
    float glitchBand = glitchEvent * glitchEnvelope * tearShape;
    float glitchDirection = hash21(vec2(glitchTick, 9.10)) * 2.0 - 1.0;
    glitchDirection += lineTimebase * 0.24;
    float glitchPixels = lineTimebase * TIMEBASE_ERROR
                       + glitchBand * glitchDirection
                       * GLITCH_STRENGTH * tearTexture;

    // A narrow tracking line rolls slowly through the picture even when the tape
    // is otherwise calm. It bends and brightens the image locally.
    float trackingY = fract(time * 0.071 + 0.13 * sin(time * 0.19));
    float trackingDistance = abs(texcoord.y - trackingY);
    trackingDistance = min(trackingDistance, 1.0 - trackingDistance);
    float trackingBand = pow(max(0.0, 1.0 - trackingDistance * 42.0), 3.0);
    glitchPixels += trackingBand * sin(time * 17.0) * GLITCH_STRENGTH * 0.22;

    // A VCR that briefly loses vertical lock either rolls the raster or holds
    // the last stable frame. One four-second event cell is sampled at a time,
    // making low slider values genuinely rare rather than constant wobble.
    float syncEvent = 0.0;
    float syncFreeze = 0.0;
    float syncRoll = 0.0;
#ifdef VERTICAL_SYNC_GLITCH
    float syncPhase = time * 0.25;
    float syncTick = floor(syncPhase);
    float syncWindow = 1.0 - step(0.14, fract(syncPhase));
    syncEvent = step(1.0 - SYNC_GLITCH_FREQUENCY,
                     hash21(vec2(syncTick, 241.7))) * syncWindow;
    float syncChoice = step(0.52, hash21(vec2(syncTick, 92.3)));
    float syncProgress = clamp(fract(syncPhase) / 0.14, 0.0, 1.0);
    syncFreeze = syncEvent * syncChoice;
    syncRoll = syncEvent * (1.0 - syncChoice)
             * (0.10 + syncProgress * 0.90) * SYNC_GLITCH_STRENGTH;
#endif

    vec2 uv = texcoord + (wobblePixels + jitterPixels) * pixel;
    uv.x += glitchPixels * pixel.x;
    uv.y = mix(uv.y, fract(uv.y + syncRoll), step(0.0001, syncRoll));

    // -------------------------------------------------------------------------
    // Cheap-lens barrel distortion.
    // Aspect correction keeps the distortion circular on widescreen displays.
    // -------------------------------------------------------------------------
    vec2 lens = uv * 2.0 - 1.0;
    lens.x *= viewWidth / viewHeight;
    float radius2 = dot(lens, lens);
    lens *= 1.0 + LENS_DISTORTION * radius2;
    lens.x *= viewHeight / viewWidth;
    uv = lens * 0.5 + 0.5;

    // The border is controlled only by ROUNDED_OVERSCAN. Lens distortion remains
    // active when it is disabled, but the output edge becomes truly rectangular.
    float lensBorder = 1.0;
#ifdef ROUNDED_OVERSCAN
    vec2 edge = smoothstep(vec2(0.0), pixel * 5.0, uv)
              * (vec2(1.0) - smoothstep(vec2(1.0) - pixel * 5.0,
                                        vec2(1.0), uv));
    lensBorder = edge.x * edge.y;
#endif

    uv = virtualPixels(clampUV(uv, pixel), resolution);
    uv = clampUV(uv, pixel);

    // -------------------------------------------------------------------------
    // First tape generation: luma/chroma bandwidth and horizontal smear.
    // With YIQ enabled, color is encoded as a real brightness + two-color signal
    // so broad chroma damage cannot accidentally soften luminance detail.
    // -------------------------------------------------------------------------
    float separationPixels = CHROMA_AMOUNT * (1.0 + glitchBand * 2.8
                                             + trackingBand * 0.45);
    vec2 chromaOffset = vec2(separationPixels * pixel.x, 0.0);

    vec3 centerSample = texture2D(colortex0, uv).rgb;
    vec3 positiveSample = texture2D(colortex0,
                                    clampUV(uv + chromaOffset, pixel)).rgb;
    vec3 negativeSample = texture2D(colortex0,
                                    clampUV(uv - chromaOffset, pixel)).rgb;

    vec2 smearOffset = vec2(MOTION_SMEAR * pixel.x, 0.0);
#if QUALITY_LEVEL == 0
    // Performance mode reuses existing taps instead of reading two additional
    // luma-smear samples. The second tape generation still supplies softening.
    vec3 smearBack = negativeSample;
    vec3 smearFront = positiveSample;
#else
    vec3 smearBack = texture2D(colortex0,
                               clampUV(uv - smearOffset * 2.0, pixel)).rgb;
    vec3 smearFront = texture2D(colortex0,
                                clampUV(uv + smearOffset, pixel)).rgb;
#endif

    // Atmospheric depth belongs to the recorded scene, so apply it before the
    // first tape generation instead of placing clean digital haze on top.
#if FOG_MODE > 0
    float fogAmount = analogFogAmount(uv, time);
    vec3 fogColor = analogFogColor();
    centerSample = mix(centerSample, fogColor, fogAmount);
    positiveSample = mix(positiveSample, fogColor, fogAmount);
    negativeSample = mix(negativeSample, fogColor, fogAmount);
    smearBack = mix(smearBack, fogColor, fogAmount);
    smearFront = mix(smearFront, fogColor, fogAmount);
#endif

    vec3 color;
#ifdef YIQ_SIGNAL
    vec3 centerYiq = rgbToYiq(centerSample);
    vec3 positiveYiq = rgbToYiq(positiveSample);
    vec3 negativeYiq = rgbToYiq(negativeSample);
    vec3 smearBackYiq = rgbToYiq(smearBack);
    vec3 smearFrontYiq = rgbToYiq(smearFront);

    // Luma retains much more bandwidth than tape chroma. I and Q use slightly
    // different asymmetric filters, producing the characteristic rightward
    // color tail instead of a clean modern Gaussian blur.
    float tapeY = centerYiq.x * 0.78
                + smearBackYiq.x * 0.15
                + smearFrontYiq.x * 0.07;
    float tapeI = centerYiq.y * 0.38
                + positiveYiq.y * 0.21
                + negativeYiq.y * 0.15
                + smearBackYiq.y * 0.18
                + smearFrontYiq.y * 0.08;
    float tapeQ = centerYiq.z * 0.27
                + positiveYiq.z * 0.17
                + negativeYiq.z * 0.13
                + smearBackYiq.z * 0.29
                + smearFrontYiq.z * 0.14;

    // Per-line phase error gets much stronger when tracking lock is weak. This
    // rotates hue in signal space instead of applying an arbitrary RGB overlay.
    float firstChromaLine = floor(texcoord.y * VHS_CHROMA_LINES);
    float firstPhaseNoise = hash21(vec2(firstChromaLine, floor(time * 8.0))) - 0.5;
    firstPhaseNoise += sin(texcoord.y * 43.0 + time * 1.17) * 0.22;
    float firstPhaseAngle = firstPhaseNoise * CHROMA_PHASE_ERROR * 0.65;
    firstPhaseAngle += glitchBand * glitchDirection * CHROMA_PHASE_ERROR * 0.75;
#if SIGNAL_STANDARD == 1
    // PAL alternates the color-subcarrier phase on neighboring lines, making
    // slow hue drift less directional than the NTSC decoder path.
    firstPhaseAngle *= mod(firstChromaLine, 2.0) * 2.0 - 1.0;
#endif
    vec2 tapeChroma = rotateChroma(vec2(tapeI, tapeQ), firstPhaseAngle);

    // Composite encode/decode leakage. A low-cost consumer notch filter cannot
    // perfectly separate high-frequency luminance from the color subcarrier,
    // so sharp texture detail becomes false rainbow color and saturated edges
    // leave a moving dot pattern in luminance. The two-line comb option compares
    // adjacent scan lines and suppresses leakage where the picture correlates.
#if COMPOSITE_DECODER > 0
    float compositeLine = floor(texcoord.y * VHS_SIGNAL_LINES);
    float carrierSample = uv.x * viewWidth / max(PIXEL_SCALE, 1.0);
    float carrierPhase = carrierSample * PI * 0.50
                       + compositeLine * PI
                       + mod(frame, 4.0) * PI * 0.50;
#if SIGNAL_STANDARD == 1
    carrierPhase += mod(compositeLine, 2.0) * PI * 0.50;
#endif
    vec2 carrier = vec2(cos(carrierPhase), sin(carrierPhase));
    float lumaHigh = centerYiq.x
                   - (positiveYiq.x + negativeYiq.x) * 0.50;
    float decoderLeak = 1.0;

#if COMPOSITE_DECODER == 2
#if QUALITY_LEVEL == 0
    decoderLeak = 0.52;
#else
    vec2 adjacentUv = clampUV(
        uv + vec2(0.0, 1.0 / VHS_SIGNAL_LINES), pixel);
    vec3 adjacentYiq = rgbToYiq(texture2D(colortex0, adjacentUv).rgb);
    float adjacentDifference = abs(centerYiq.x - adjacentYiq.x)
                             + length(centerYiq.yz - adjacentYiq.yz) * 0.35;
    float lineCorrelation = 1.0
                          - smoothstep(0.018, 0.22, adjacentDifference);
    decoderLeak = mix(0.62, 0.18, lineCorrelation);
#endif
#endif

    float edgeMask = clamp(abs(lumaHigh) * 8.0, 0.0, 1.0);
    float dotCarrier = sin(carrierPhase + compositeLine * PI * 0.50);
    float chromaOnCarrier = dot(tapeChroma, carrier);

    tapeY += (chromaOnCarrier * CROSS_LUMA_STRENGTH * 0.24
              + dotCarrier * edgeMask * DOT_CRAWL_STRENGTH * 0.026)
           * decoderLeak;
    tapeChroma += carrier
                * (lumaHigh * CROSS_COLOR_STRENGTH * 0.58
                   + dotCarrier * edgeMask * DOT_CRAWL_STRENGTH * 0.013)
                * decoderLeak;
#endif
    color = yiqToRgb(vec3(tapeY, tapeChroma));
#else
    // Legacy RGB mode is kept as an option for comparison and older hardware.
    color = vec3(positiveSample.r, centerSample.g, negativeSample.b);
    color = color * 0.78 + smearBack * 0.15 + smearFront * 0.07;
#endif

    // Sparse whole-frame metering imitates a cheap camcorder's automatic gain
    // circuit. The previous processed frame dominates the meter, so transitions
    // into dark or bright rooms settle with a visible delayed pump instead of an
    // instantaneous modern exposure correction.
#ifdef AUTO_EXPOSURE
    if (frameCounter > 2) {
        vec3 meterWeights = vec3(0.299, 0.587, 0.114);
#if QUALITY_LEVEL == 0
        // Two taps instead of ten make automatic exposure inexpensive enough
        // for integrated GPUs while preserving its delayed response.
        float currentMeter = dot(texture2D(colortex0, vec2(0.50)).rgb,
                                 meterWeights);
        float historyMeter = dot(texture2D(colortex4, vec2(0.50)).rgb,
                                 meterWeights);
#else
        float currentMeter = dot(texture2D(colortex0, vec2(0.50, 0.50)).rgb,
                                 meterWeights) * 0.36;
        currentMeter += dot(texture2D(colortex0, vec2(0.24, 0.28)).rgb,
                            meterWeights) * 0.16;
        currentMeter += dot(texture2D(colortex0, vec2(0.76, 0.28)).rgb,
                            meterWeights) * 0.16;
        currentMeter += dot(texture2D(colortex0, vec2(0.24, 0.72)).rgb,
                            meterWeights) * 0.16;
        currentMeter += dot(texture2D(colortex0, vec2(0.76, 0.72)).rgb,
                            meterWeights) * 0.16;

        float historyMeter = dot(texture2D(colortex4, vec2(0.50, 0.50)).rgb,
                                 meterWeights) * 0.36;
        historyMeter += dot(texture2D(colortex4, vec2(0.24, 0.28)).rgb,
                            meterWeights) * 0.16;
        historyMeter += dot(texture2D(colortex4, vec2(0.76, 0.28)).rgb,
                            meterWeights) * 0.16;
        historyMeter += dot(texture2D(colortex4, vec2(0.24, 0.72)).rgb,
                            meterWeights) * 0.16;
        historyMeter += dot(texture2D(colortex4, vec2(0.76, 0.72)).rgb,
                            meterWeights) * 0.16;
#endif

        float adaptedMeter = mix(currentMeter, historyMeter, 0.82);
        float exposureTarget = clamp(0.38 / max(adaptedMeter, 0.06),
                                     0.72, 1.55);
        color *= mix(1.0, exposureTarget, EXPOSURE_PUMP_STRENGTH);
    }
#endif
    color = gradeOldTape(color);

    // -------------------------------------------------------------------------
    // Temporal ghosting. colortex4 contains the last *processed* frame. Stable
    // world geometry is reprojected through depth and the previous camera while
    // sky/off-screen pixels safely fall back to the original screen-space path.
    // A partial blend preserves genuine analog lag instead of turning the
    // history buffer into modern temporal anti-aliasing.
    // -------------------------------------------------------------------------
    if (frameCounter > 2) {
        vec2 historyOffset = vec2(-0.65 * MOTION_SMEAR * pixel.x, 0.0);
        float reprojectionConfidence;
        vec2 reprojectedUv = reprojectHistoryUV(texcoord, pixel,
                                                reprojectionConfidence);
        vec2 historyUv = mix(texcoord, reprojectedUv,
                             REPROJECTION_STRENGTH * reprojectionConfidence);
        historyUv = clampUV(historyUv + historyOffset, pixel);
        vec3 history = texture2D(colortex4, historyUv).rgb;

        // Reject history colors that are implausibly far from the current
        // processed frame. This limits full-screen double exposure during fast
        // camera turns without removing the smaller differences that form tape
        // trails on moving objects.
        float historyRange = mix(1.0, 0.12, HISTORY_STABILIZATION);
        history = clamp(history,
                        color - vec3(historyRange),
                        color + vec3(historyRange));
        float difference = length(color - history);
        float adaptiveGhost = GHOST_STRENGTH
                            * mix(0.68, 1.22, smoothstep(0.04, 0.55, difference))
                            * mix(0.92, 1.0, reprojectionConfidence);
        color = mix(color, history, clamp(adaptiveGhost, 0.0, 0.45));

#ifdef CHROMA_PERSISTENCE
        // Preserve current luminance while borrowing only the old frame's color
        // difference. Moving saturated objects therefore leave longer colored
        // trails without turning the whole image into a conventional blur.
#ifdef YIQ_SIGNAL
        vec3 currentYiq = rgbToYiq(color);
        vec3 historyYiq = rgbToYiq(history);
        float chromaTrail = CHROMA_PERSISTENCE_STRENGTH
                          * smoothstep(0.025, 0.45, difference);
        currentYiq.yz = mix(currentYiq.yz, historyYiq.yz, chromaTrail);
        color = yiqToRgb(currentYiq);
#else
        float currentLuma = dot(color, vec3(0.299, 0.587, 0.114));
        float historyLuma = dot(history, vec3(0.299, 0.587, 0.114));
        vec3 currentChroma = color - vec3(currentLuma);
        vec3 historyChroma = history - vec3(historyLuma);
        float chromaTrail = CHROMA_PERSISTENCE_STRENGTH
                          * smoothstep(0.025, 0.45, difference);
        color = vec3(currentLuma)
              + mix(currentChroma, historyChroma, chromaTrail);
#endif
#endif

#ifdef VERTICAL_SYNC_GLITCH
        // Recursive history makes the held field remain nearly frozen for the
        // short event window, like a deck waiting to reacquire vertical sync.
        vec3 heldFrame = texture2D(colortex4, clampUV(texcoord, pixel)).rgb;
        float holdOpacity = syncFreeze
                          * mix(0.40, 1.00, SYNC_GLITCH_STRENGTH);
        color = mix(color, heldFrame, holdOpacity);
#endif

#ifdef FRAME_REPEAT
        // A transport stall repeats the fully processed previous frame. The
        // short attack/release prevents a hard game-like freeze while recursive
        // history sustains the held picture for the duration of the event.
        float repeatPhase = time * 1.25;
        float repeatTick = floor(repeatPhase);
        float repeatAge = fract(repeatPhase);
        float repeatEvent = step(1.0 - FRAME_REPEAT_FREQUENCY,
                                 hash21(vec2(repeatTick, 619.4)));
        float repeatWindow = smoothstep(0.0, 0.025, repeatAge)
                           * (1.0 - smoothstep(0.18, 0.48, repeatAge));
        vec3 repeatedFrame = texture2D(colortex4,
                                       clampUV(texcoord, pixel)).rgb;
        color = mix(color, repeatedFrame,
                    repeatEvent * repeatWindow * FRAME_REPEAT_STRENGTH);
#endif
    }

#ifdef CHROMA_KILLER
    // Consumer VCRs suppress unstable chroma instead of displaying wild color.
    // Strong displaced bands, the rolling tracking line, and sync loss can all
    // produce a brief monochrome patch while luminance remains readable.
    float signalLoss = max(glitchBand, trackingBand * 0.72);
    signalLoss = max(signalLoss, syncEvent * 0.68);
    float colorKill = clamp(signalLoss * CHROMA_KILLER_STRENGTH, 0.0, 1.0);
#ifdef YIQ_SIGNAL
    vec3 killerYiq = rgbToYiq(color);
    killerYiq.yz *= 1.0 - colorKill;
    color = yiqToRgb(killerYiq);
#else
    float killedLuma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(killedLuma), colorKill);
#endif
#endif

    // -------------------------------------------------------------------------
    // Exposure flicker: a fast uneven waveform plus frame-random flutter. The
    // pattern is intentionally imperfect and never resolves to a clean sine.
    // -------------------------------------------------------------------------
    float flickerWave = sin(time * 19.7) * 0.50
                      + sin(time * 7.3 + 2.0) * 0.28
                      + (hash11(frame + 31.0) - 0.5) * 0.90;
    color *= 1.0 + flickerWave * FLICKER_STRENGTH;

    // -------------------------------------------------------------------------
    // Analog grain, dropouts, scanlines, and occasional full-screen static.
    // Noise is evaluated at virtual-pixel scale to look recorded rather than
    // like modern high-resolution film grain.
    // -------------------------------------------------------------------------
    vec2 noiseCell = floor(texcoord * resolution / max(1.0, PIXEL_SCALE));
    float grain = hash21(noiseCell + vec2(frame * 1.73, frame * 0.37)) - 0.5;
    float lineNoise = hash21(vec2(floor(texcoord.y * VHS_SIGNAL_LINES),
                                  floor(time * 29.0))) - 0.5;
    color += vec3(grain * NOISE_STRENGTH);
    color += vec3(lineNoise * NOISE_STRENGTH * 0.34);

    // Low-level colored speckle simulates chroma noise in dark tape regions.
    vec3 chromaNoise = vec3(
        hash21(noiseCell + vec2(frame, 7.0)),
        hash21(noiseCell + vec2(13.0, frame)),
        hash21(noiseCell + vec2(frame + 29.0, 3.0))
    ) - 0.5;
    color += chromaNoise * NOISE_STRENGTH * 0.18;

    // One darker line per three output pixels, plus a weaker traveling ripple.
    float scanRow = mod(floor(texcoord.y * viewHeight), 3.0);
    float hardScanline = step(2.0, scanRow);
    float fineScanline = 0.5 + 0.5 * sin(texcoord.y * viewHeight * PI
                                       + time * 1.7);
    float scanDarkening = SCANLINE_STRENGTH
                        * (0.18 + hardScanline * 0.68 + fineScanline * 0.14);
    color *= 1.0 - scanDarkening;

    // Tracking band gets a bright leading edge and a dirty shadow below it.
    float trackingShadow = pow(max(0.0, 1.0 - abs(trackingDistance - 0.012)
                                             * 95.0), 4.0);
    color += vec3(trackingBand * (0.055 + 0.04 * lineNoise));
    color *= 1.0 - trackingShadow * 0.08;

    // Very short bursts occur at the start of some time cells. During a burst,
    // noisy horizontal bands can nearly overwhelm the picture for a few frames.
    float staticTick = floor(time * 1.75);
    float staticWindow = 1.0 - step(0.095, fract(time * 1.75));
    float staticEvent = step(1.0 - STATIC_FREQUENCY,
                             hash21(vec2(staticTick, 83.1))) * staticWindow;
    float staticNoise = hash21(noiseCell * vec2(1.0, 0.37)
                               + vec2(frame * 7.0, frame * 3.0));
    float staticStripe = step(0.46,
                              hash21(vec2(floor(texcoord.y * 90.0), frame)));
    vec3 interference = vec3(staticNoise * 0.92 + staticStripe * 0.18);
    color = mix(color, interference, staticEvent * 0.72);

    // Sparse white/black dropouts happen even outside major static bursts.
    float dropoutSeed = hash21(noiseCell + vec2(frame * 11.0, 41.0));
    float whiteDropout = step(0.9972 - NOISE_STRENGTH * 0.004, dropoutSeed);
    float blackDropout = step(dropoutSeed, 0.0012 + NOISE_STRENGTH * 0.002);
    color = mix(color, vec3(0.92), whiteDropout * 0.65);
    color = mix(color, vec3(0.02), blackDropout * 0.72);

    // -------------------------------------------------------------------------
    // Cheap-lens vignette and final overscan. The exponent keeps the middle of
    // the frame readable while making corners visibly stale and enclosed.
    // -------------------------------------------------------------------------
    vec2 vignettePos = texcoord * 2.0 - 1.0;
    float vignetteRadius = dot(vignettePos * vec2(0.78, 1.0),
                               vignettePos * vec2(0.78, 1.0));
    float vignette = smoothstep(0.34, 1.28, vignetteRadius);
    color *= 1.0 - vignette * VIGNETTE_STRENGTH;
    color *= lensBorder;

    // A tiny lifted floor avoids pristine digital black except beyond the lens.
    color += vec3(0.006, 0.008, 0.004) * lensBorder;

#ifdef INTERLACED_FIELDS
    // True field weave: only one parity of recorded raster lines is refreshed
    // during each NTSC/PAL field interval. The opposite lines come from the
    // persistent previous field in colortex4, producing real motion combing
    // rather than a stationary scanline overlay.
    if (frameCounter > 2) {
        float fieldParity = mod(floor(time * VHS_FIELD_RATE), 2.0);
        float lineParity = mod(floor(texcoord.y * VHS_SIGNAL_LINES), 2.0);
        float currentFieldLine = 1.0 - step(0.5,
                                            abs(lineParity - fieldParity));
        vec2 previousFieldUv = clampUV(
            texcoord + vec2(lineTimebase * pixel.x * 0.18, 0.0),
            pixel);
        vec3 previousField = texture2D(colortex4, previousFieldUv).rgb;
        float previousFieldMix = (1.0 - currentFieldLine)
                               * INTERLACE_STRENGTH;
        color = mix(color, previousField, previousFieldMix);
    }
#endif

    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
}
