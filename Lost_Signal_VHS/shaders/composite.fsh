#version 120

// Main VHS post-processing pass.
// colortex0 = Minecraft's current rendered scene.
// colortex4 = last frame's fully processed VHS image.
uniform sampler2D colortex0;
uniform sampler2D colortex4;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int frameCounter;

varying vec2 texcoord;

#include "/lib/settings.glsl"

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
    float frame = float(frameCounter);

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

    // A global event gate makes tears occasional; within an event, only random
    // horizontal blocks are displaced. Stronger tears also exaggerate RGB split.
    float glitchTick = floor(time * 9.0);
    float glitchEvent = step(1.0 - GLITCH_FREQUENCY,
                             hash21(vec2(glitchTick, 19.37)));
    float lineBlock = floor(texcoord.y * 52.0);
    float lineRandom = hash21(vec2(lineBlock, glitchTick));
    float glitchBand = glitchEvent * step(0.58, lineRandom);
    float glitchDirection = hash21(vec2(lineBlock + 9.1, glitchTick)) * 2.0 - 1.0;
    float glitchPixels = glitchBand * glitchDirection * GLITCH_STRENGTH;

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
    // RGB separation and analog horizontal smear.
    // Three main taps split the channels; two low-weight taps stretch highlights
    // sideways like chroma/luma bandwidth loss on consumer VHS.
    // -------------------------------------------------------------------------
    float separationPixels = CHROMA_AMOUNT * (1.0 + glitchBand * 2.8
                                             + trackingBand * 0.45);
    vec2 chromaOffset = vec2(separationPixels * pixel.x, 0.0);

    vec3 centerSample = texture2D(colortex0, uv).rgb;
    vec3 positiveSample = texture2D(colortex0,
                                    clampUV(uv + chromaOffset, pixel)).rgb;
    vec3 negativeSample = texture2D(colortex0,
                                    clampUV(uv - chromaOffset, pixel)).rgb;

    // Red and blue drift in opposite directions while green remains the anchor.
    vec3 color = vec3(positiveSample.r, centerSample.g, negativeSample.b);

    vec2 smearOffset = vec2(MOTION_SMEAR * pixel.x, 0.0);
    vec3 smearBack = texture2D(colortex0,
                               clampUV(uv - smearOffset * 2.0, pixel)).rgb;
    vec3 smearFront = texture2D(colortex0,
                                clampUV(uv + smearOffset, pixel)).rgb;
    color = color * 0.78 + smearBack * 0.15 + smearFront * 0.07;

    // Sparse whole-frame metering imitates a cheap camcorder's automatic gain
    // circuit. The previous processed frame dominates the meter, so transitions
    // into dark or bright rooms settle with a visible delayed pump instead of an
    // instantaneous modern exposure correction.
#ifdef AUTO_EXPOSURE
    if (frameCounter > 2) {
        vec3 meterWeights = vec3(0.299, 0.587, 0.114);
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

        float adaptedMeter = mix(currentMeter, historyMeter, 0.82);
        float exposureTarget = clamp(0.38 / max(adaptedMeter, 0.06),
                                     0.72, 1.55);
        color *= mix(1.0, exposureTarget, EXPOSURE_PUMP_STRENGTH);
    }
#endif
    color = gradeOldTape(color);

    // -------------------------------------------------------------------------
    // Temporal ghosting. colortex4 contains the last *processed* frame. Keeping
    // it in screen space creates convincing trails on moving objects and a faint
    // double image during camera movement, like slow analog phosphor/tape decay.
    // -------------------------------------------------------------------------
    if (frameCounter > 2) {
        vec2 historyOffset = vec2(-0.65 * MOTION_SMEAR * pixel.x, 0.0);
        vec3 history = texture2D(colortex4,
                                 clampUV(texcoord + historyOffset, pixel)).rgb;
        float difference = length(color - history);
        float adaptiveGhost = GHOST_STRENGTH
                            * mix(0.68, 1.22, smoothstep(0.04, 0.55, difference));
        color = mix(color, history, clamp(adaptiveGhost, 0.0, 0.45));

#ifdef CHROMA_PERSISTENCE
        // Preserve current luminance while borrowing only the old frame's color
        // difference. Moving saturated objects therefore leave longer colored
        // trails without turning the whole image into a conventional blur.
        float currentLuma = dot(color, vec3(0.299, 0.587, 0.114));
        float historyLuma = dot(history, vec3(0.299, 0.587, 0.114));
        vec3 currentChroma = color - vec3(currentLuma);
        vec3 historyChroma = history - vec3(historyLuma);
        float chromaTrail = CHROMA_PERSISTENCE_STRENGTH
                          * smoothstep(0.025, 0.45, difference);
        color = vec3(currentLuma)
              + mix(currentChroma, historyChroma, chromaTrail);
#endif

#ifdef VERTICAL_SYNC_GLITCH
        // Recursive history makes the held field remain nearly frozen for the
        // short event window, like a deck waiting to reacquire vertical sync.
        vec3 heldFrame = texture2D(colortex4, clampUV(texcoord, pixel)).rgb;
        float holdOpacity = syncFreeze
                          * mix(0.40, 1.00, SYNC_GLITCH_STRENGTH);
        color = mix(color, heldFrame, holdOpacity);
#endif
    }

#ifdef CHROMA_KILLER
    // Consumer VCRs suppress unstable chroma instead of displaying wild color.
    // Strong displaced bands, the rolling tracking line, and sync loss can all
    // produce a brief monochrome patch while luminance remains readable.
    float signalLoss = max(glitchBand, trackingBand * 0.72);
    signalLoss = max(signalLoss, syncEvent * 0.68);
    float colorKill = clamp(signalLoss * CHROMA_KILLER_STRENGTH, 0.0, 1.0);
    float killedLuma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(killedLuma), colorKill);
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
    float lineNoise = hash21(vec2(floor(texcoord.y * viewHeight * 0.5),
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
    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
}
