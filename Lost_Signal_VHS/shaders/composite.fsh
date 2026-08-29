#version 120

// Main VHS post-processing pass.
// colortex0 = Minecraft's current rendered scene.
// colortex4 = last frame's fully processed VHS image.
// colortex5 = matching logarithmic depth plus the persistent AGC gain state.
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
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
uniform float frameTime;
uniform int frameCounter;

varying vec2 texcoord;

#include "/lib/settings.glsl"
#include "/lib/analog_color.glsl"

// Keep color history and metadata between frames. composite1 refreshes color at
// the end of every frame; composite refreshes metadata in the paired ping-pong
// target. The frameCounter guards below avoid sampling either at startup.
const bool colortex4Clear = false;
const bool colortex5Clear = false;

/*
const int colortex5Format = RG16F;
*/

/* RENDERTARGETS: 0,5 */

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

// The metadata buffer stores logarithmic view distance. A logarithmic encoding
// keeps sub-block precision near the camera while still representing the far
// plane in a compact RG16F target.
float encodeViewDistance(float viewDistance) {
    return clamp(log2(1.0 + max(viewDistance, 0.0)) / 16.0, 0.0, 1.0);
}

float decodeViewDistance(float encodedDistance) {
    return exp2(clamp(encodedDistance, 0.0, 1.0) * 16.0) - 1.0;
}

float viewDistanceAt(vec2 screenUv) {
    float depth = texture2D(depthtex0, screenUv).r;
    if (depth >= 0.99998) {
        return 65535.0;
    }

    vec4 clipPosition = vec4(screenUv * 2.0 - 1.0,
                             depth * 2.0 - 1.0,
                             1.0);
    vec4 viewPosition = gbufferProjectionInverse * clipPosition;
    if (abs(viewPosition.w) <= 0.00001) {
        return 65535.0;
    }
    return length(viewPosition.xyz / viewPosition.w);
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
vec2 reprojectHistoryUV(vec2 screenUv,
                        vec2 pixel,
                        vec2 resolution,
                        out float confidence,
                        out float validity,
                        out float motionPixels) {
    confidence = 0.0;
    validity = 0.68;
    motionPixels = 0.0;
#ifdef MOTION_AWARE_HISTORY
    float depth = texture2D(depthtex0, screenUv).r;
    if (depth < 0.99998) {
        // depthtex2 excludes translucent geometry and the first-person hand.
        // Their special projection/depth paths are safer in screen space.
        float stableDepth = texture2D(depthtex2, screenUv).r;
        float depthAgreement = 1.0
                             - step(0.0005, abs(depth - stableDepth));
        validity = mix(0.16, 1.0, depthAgreement);
        vec4 clipPosition = vec4(screenUv * 2.0 - 1.0,
                                 depth * 2.0 - 1.0,
                                 1.0);
        vec4 viewPosition = gbufferProjectionInverse * clipPosition;
        if (abs(viewPosition.w) > 0.00001) {
            viewPosition /= viewPosition.w;

            vec4 worldPosition = gbufferModelViewInverse * viewPosition;
            worldPosition.xyz += cameraPosition;
            worldPosition.xyz -= previousCameraPosition;

            vec4 previousView = gbufferPreviousModelView * worldPosition;
            vec4 previousClip = gbufferPreviousProjection * previousView;
            if (previousClip.w > 0.00001) {
                vec2 previousUv = previousClip.xy / previousClip.w
                                * 0.5 + 0.5;
                vec2 lowerInside = step(vec2(0.0), previousUv);
                vec2 upperInside = step(previousUv, vec2(1.0));
                float inside = lowerInside.x * lowerInside.y
                             * upperInside.x * upperInside.y;
                motionPixels = length((previousUv - screenUv) * resolution);

                float expectedDistance = length(previousView.xyz);
                float storedEncoded = texture2D(
                    colortex5, clampUV(previousUv, pixel)).r;
                float storedValid = step(0.0001, storedEncoded);
                float storedDistance = decodeViewDistance(storedEncoded);
                float bestDelta = abs(storedDistance - expectedDistance)
                                + (1.0 - storedValid) * 1000000.0;
#if QUALITY_LEVEL > 0
                // A small cross neighborhood tolerates raster/time-base motion
                // in the processed history without accepting a foreground depth
                // that has disappeared in the new frame.
                float encodedLeft = texture2D(
                    colortex5, clampUV(previousUv - vec2(pixel.x, 0.0), pixel)).r;
                float encodedRight = texture2D(
                    colortex5, clampUV(previousUv + vec2(pixel.x, 0.0), pixel)).r;
                float encodedUp = texture2D(
                    colortex5, clampUV(previousUv + vec2(0.0, pixel.y), pixel)).r;
                float encodedDown = texture2D(
                    colortex5, clampUV(previousUv - vec2(0.0, pixel.y), pixel)).r;
                bestDelta = min(bestDelta,
                    abs(decodeViewDistance(encodedLeft) - expectedDistance)
                    + (1.0 - step(0.0001, encodedLeft)) * 1000000.0);
                bestDelta = min(bestDelta,
                    abs(decodeViewDistance(encodedRight) - expectedDistance)
                    + (1.0 - step(0.0001, encodedRight)) * 1000000.0);
                bestDelta = min(bestDelta,
                    abs(decodeViewDistance(encodedUp) - expectedDistance)
                    + (1.0 - step(0.0001, encodedUp)) * 1000000.0);
                bestDelta = min(bestDelta,
                    abs(decodeViewDistance(encodedDown) - expectedDistance)
                    + (1.0 - step(0.0001, encodedDown)) * 1000000.0);
#endif
                float depthTolerance = max(0.35, expectedDistance * 0.020);
                float metadataValid = 1.0 - step(999999.0, bestDelta);
                float depthValidity = 1.0 - smoothstep(
                    depthTolerance, depthTolerance * 2.5, bestDelta);
                float cameraJump = length(cameraPosition - previousCameraPosition);
                float cameraValidity = 1.0 - smoothstep(16.0, 64.0, cameraJump);

                validity *= inside * metadataValid * depthValidity
                          * cameraValidity;
                confidence = inside * depthAgreement * validity;
                return clampUV(previousUv, pixel);
            }
        }
        validity *= 0.16;
    }
#else
    validity = 1.0;
#endif
    return clampUV(screenUv, pixel);
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
    // Recording transport timing and horizontal tracking glitches. Camera
    // wobble, frame jitter, lens curvature, and framing are applied once in the
    // playback pass so their controls no longer square the same transform.
    // -------------------------------------------------------------------------

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

    vec2 uv = texcoord;
    uv.x += glitchPixels * pixel.x;
    uv.y = mix(uv.y, fract(uv.y + syncRoll), step(0.0001, syncRoll));

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

    // Persistent camcorder AGC. colortex5.g stores the actual gain state instead
    // of estimating it from a processed history pixel. Gain reduction reacts
    // quickly to a bright room; recovery in darkness is deliberately slower.
    float nextAgcGain = 1.0;
    float appliedAgcGain = 1.0;
#ifdef AUTO_EXPOSURE
    vec3 meterWeights = vec3(0.299, 0.587, 0.114);
#if QUALITY_LEVEL == 0
    float logMeter = log2(max(dot(texture2D(
        colortex0, vec2(0.50, 0.50)).rgb, meterWeights), 0.002));
#else
    float logMeter = log2(max(dot(texture2D(
        colortex0, vec2(0.50, 0.50)).rgb, meterWeights), 0.002)) * 0.36;
    logMeter += log2(max(dot(texture2D(
        colortex0, vec2(0.24, 0.28)).rgb, meterWeights), 0.002)) * 0.16;
    logMeter += log2(max(dot(texture2D(
        colortex0, vec2(0.76, 0.28)).rgb, meterWeights), 0.002)) * 0.16;
    logMeter += log2(max(dot(texture2D(
        colortex0, vec2(0.24, 0.72)).rgb, meterWeights), 0.002)) * 0.16;
    logMeter += log2(max(dot(texture2D(
        colortex0, vec2(0.76, 0.72)).rgb, meterWeights), 0.002)) * 0.16;
#endif
    float sceneMeter = exp2(logMeter);
    float targetAgcGain = clamp(0.36 / max(sceneMeter, 0.025), 0.65, 1.80);
    float storedAgcGain = texture2D(colortex5, vec2(0.50, 0.50)).g;
    float storedAgcValid = step(0.45, storedAgcGain)
                         * step(storedAgcGain, 2.20)
                         * step(3.0, float(frameCounter));
    float previousAgcGain = mix(1.0, storedAgcGain, storedAgcValid);
    float responseTau = mix(0.14, 0.85,
                            step(previousAgcGain, targetAgcGain));
    float responseAmount = 1.0 - exp(-clamp(frameTime, 0.0, 0.10)
                                     / responseTau);
    nextAgcGain = mix(previousAgcGain, targetAgcGain, responseAmount);
    appliedAgcGain = mix(1.0, nextAgcGain, EXPOSURE_PUMP_STRENGTH);
#endif
    centerSample *= appliedAgcGain;
    positiveSample *= appliedAgcGain;
    negativeSample *= appliedAgcGain;
    smearBack *= appliedAgcGain;
    smearFront *= appliedAgcGain;

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

    // The recording pass stops at the bandwidth-limited color-under signal.
    // Composite modulation and the user-selected decoder now happen exactly once
    // in final.fsh, avoiding the previous double-strength decorative leakage.
    color = yiqToRgb(vec3(tapeY, tapeChroma));
#else
    // Legacy RGB mode is kept as an option for comparison and older hardware.
    color = vec3(positiveSample.r, centerSample.g, negativeSample.b);
    color = color * 0.78 + smearBack * 0.15 + smearFront * 0.07;
#endif

    // -------------------------------------------------------------------------
    // Temporal ghosting. colortex4 contains the last *processed* frame. Stable
    // world geometry is reprojected through depth and the previous camera while
    // sky/off-screen pixels safely fall back to the original screen-space path.
    // A partial blend preserves genuine analog lag instead of turning the
    // history buffer into modern temporal anti-aliasing.
    // -------------------------------------------------------------------------
    float reprojectionConfidence = 0.0;
    float historyValidity = 1.0;
    float historyMotionPixels = 0.0;
    vec2 reprojectedUv = texcoord;
    if (frameCounter > 2) {
        reprojectedUv = reprojectHistoryUV(uv, pixel, resolution,
                                           reprojectionConfidence,
                                           historyValidity,
                                           historyMotionPixels);
    }

    if (frameCounter > 2) {
        vec2 historyOffset = vec2(-0.65 * MOTION_SMEAR * pixel.x, 0.0);
        vec2 historyUv = mix(texcoord, reprojectedUv,
                             REPROJECTION_STRENGTH * reprojectionConfidence);
        historyUv = clampUV(historyUv + historyOffset, pixel);
        vec3 history = texture2D(colortex4, historyUv).rgb;

        // Reject history colors that are implausibly far from the current
        // processed frame. This limits full-screen double exposure during fast
        // camera turns without removing the smaller differences that form tape
        // trails on moving objects.
        float historyRange = mix(0.80, 0.10, HISTORY_STABILIZATION);
        history = clamp(history,
                        color - vec3(historyRange),
                        color + vec3(historyRange));
        float difference = length(color - history);
        float fastMotionRetention = mix(
            1.0,
            1.0 - smoothstep(160.0, 620.0, historyMotionPixels) * 0.42,
            HISTORY_STABILIZATION);
        float adaptiveGhost = GHOST_STRENGTH
                            * mix(0.68, 1.22, smoothstep(0.04, 0.55, difference))
                            * mix(0.88, 1.0, reprojectionConfidence)
                            * historyValidity
                            * fastMotionRetention;
        color = mix(color, history, clamp(adaptiveGhost, 0.0, 0.45));

#ifdef CHROMA_PERSISTENCE
        // Preserve current luminance while borrowing only the old frame's color
        // difference. Moving saturated objects therefore leave longer colored
        // trails without turning the whole image into a conventional blur.
#ifdef YIQ_SIGNAL
        vec3 currentYiq = rgbToYiq(color);
        vec3 historyYiq = rgbToYiq(history);
        float chromaTrail = CHROMA_PERSISTENCE_STRENGTH
                          * smoothstep(0.025, 0.45, difference)
                          * historyValidity;
        currentYiq.yz = mix(currentYiq.yz, historyYiq.yz, chromaTrail);
        color = yiqToRgb(currentYiq);
#else
        float currentLuma = dot(color, vec3(0.299, 0.587, 0.114));
        float historyLuma = dot(history, vec3(0.299, 0.587, 0.114));
        vec3 currentChroma = color - vec3(currentLuma);
        vec3 historyChroma = history - vec3(historyLuma);
        float chromaTrail = CHROMA_PERSISTENCE_STRENGTH
                          * smoothstep(0.025, 0.45, difference)
                          * historyValidity;
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

    // Visible playback noise, scanlines, static, grade, vignette, and framing are
    // applied once in final.fsh. Keeping the history buffer at the recorded-signal
    // stage prevents recursive grain and makes every public control predictable.
    float outputDepthEncoded = encodeViewDistance(viewDistanceAt(uv));

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
        vec2 previousFieldUv = mix(texcoord, reprojectedUv,
            REPROJECTION_STRENGTH * reprojectionConfidence);
        previousFieldUv = clampUV(
            previousFieldUv + vec2(lineTimebase * pixel.x * 0.18, 0.0),
            pixel);
        vec3 previousField = texture2D(colortex4, previousFieldUv).rgb;
        float previousFieldDepth = texture2D(colortex5, previousFieldUv).r;
        // Held lines use the same depth/disocclusion rejection as temporal
        // ghosting, so a departed foreground object cannot be woven onto newly
        // revealed background or perpetuate its stale depth metadata.
        float previousFieldMix = (1.0 - currentFieldLine)
                               * INTERLACE_STRENGTH
                               * historyValidity;
        color = mix(color, previousField, previousFieldMix);
        outputDepthEncoded = mix(outputDepthEncoded,
                                 previousFieldDepth,
                                 previousFieldMix);
    }
#endif

    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
    gl_FragData[1] = vec4(outputDepthEncoded, nextAgcGain, 0.0, 1.0);
}
