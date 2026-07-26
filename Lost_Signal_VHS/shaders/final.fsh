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
#include "/lib/analog_color.glsl"

const float PI = 3.14159265358979323846;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

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

vec2 safeUV(vec2 uv, vec2 pixel) {
    return clamp(uv, pixel * 2.0, vec2(1.0) - pixel * 2.0);
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

float glyphE(vec2 p) {
    float g = boxMask(p, vec2(0.08, 0.05), vec2(0.25, 0.95));
    g = max(g, boxMask(p, vec2(0.15, 0.80), vec2(0.88, 0.95)));
    g = max(g, boxMask(p, vec2(0.15, 0.43), vec2(0.76, 0.58)));
    g = max(g, boxMask(p, vec2(0.15, 0.05), vec2(0.88, 0.20)));
    return g;
}

float digitGlyph(vec2 p, float digit) {
    float top = boxMask(p, vec2(0.18, 0.82), vec2(0.82, 0.95));
    float upperRight = boxMask(p, vec2(0.72, 0.50), vec2(0.87, 0.88));
    float lowerRight = boxMask(p, vec2(0.72, 0.12), vec2(0.87, 0.50));
    float bottom = boxMask(p, vec2(0.18, 0.05), vec2(0.82, 0.18));
    float lowerLeft = boxMask(p, vec2(0.08, 0.12), vec2(0.23, 0.50));
    float upperLeft = boxMask(p, vec2(0.08, 0.50), vec2(0.23, 0.88));
    float middle = boxMask(p, vec2(0.18, 0.43), vec2(0.82, 0.57));

    float a = 0.0;
    float b = 0.0;
    float c = 0.0;
    float d = 0.0;
    float e = 0.0;
    float f = 0.0;
    float g = 0.0;
    if (digit < 0.5) {
        a = 1.0; b = 1.0; c = 1.0; d = 1.0; e = 1.0; f = 1.0;
    } else if (digit < 1.5) {
        b = 1.0; c = 1.0;
    } else if (digit < 2.5) {
        a = 1.0; b = 1.0; d = 1.0; e = 1.0; g = 1.0;
    } else if (digit < 3.5) {
        a = 1.0; b = 1.0; c = 1.0; d = 1.0; g = 1.0;
    } else if (digit < 4.5) {
        b = 1.0; c = 1.0; f = 1.0; g = 1.0;
    } else if (digit < 5.5) {
        a = 1.0; c = 1.0; d = 1.0; f = 1.0; g = 1.0;
    } else if (digit < 6.5) {
        a = 1.0; c = 1.0; d = 1.0; e = 1.0; f = 1.0; g = 1.0;
    } else if (digit < 7.5) {
        a = 1.0; b = 1.0; c = 1.0;
    } else if (digit < 8.5) {
        a = 1.0; b = 1.0; c = 1.0; d = 1.0;
        e = 1.0; f = 1.0; g = 1.0;
    } else {
        a = 1.0; b = 1.0; c = 1.0; d = 1.0; f = 1.0; g = 1.0;
    }
    return max(max(max(top * a, upperRight * b), max(lowerRight * c, bottom * d)),
               max(max(lowerLeft * e, upperLeft * f), middle * g));
}

float camcorderOsd(vec2 uv, float time) {
    float hud = 0.0;
    vec2 letterSize = vec2(0.030, 0.056);

    // REC and a blinking record lamp.
    hud = max(hud, glyphR((uv - vec2(0.075, 0.875)) / letterSize));
    hud = max(hud, glyphE((uv - vec2(0.107, 0.875)) / letterSize));
    hud = max(hud, glyphC((uv - vec2(0.139, 0.875)) / letterSize));
    float recBlink = step(0.38, fract(time * 1.65));
    float recDot = 1.0 - smoothstep(0.008, 0.012,
                                    length(uv - vec2(0.187, 0.902)));
    hud = max(hud, recDot * recBlink);

    // Two-cell battery with a small positive terminal.
    float battery = boxMask(uv, vec2(0.815, 0.884), vec2(0.895, 0.894));
    battery = max(battery, boxMask(uv, vec2(0.815, 0.930), vec2(0.895, 0.940)));
    battery = max(battery, boxMask(uv, vec2(0.815, 0.884), vec2(0.825, 0.940)));
    battery = max(battery, boxMask(uv, vec2(0.885, 0.884), vec2(0.895, 0.940)));
    battery = max(battery, boxMask(uv, vec2(0.897, 0.901), vec2(0.905, 0.923)));
    battery = max(battery, boxMask(uv, vec2(0.831, 0.896), vec2(0.850, 0.928)));
    battery = max(battery, boxMask(uv, vec2(0.856, 0.896), vec2(0.875, 0.928)));
    hud = max(hud, battery);

    // Running MM:SS timecode.
    float elapsed = mod(floor(time), 3600.0);
    float minutes = floor(elapsed / 60.0);
    float seconds = mod(elapsed, 60.0);
    float digit0 = floor(minutes / 10.0);
    float digit1 = mod(minutes, 10.0);
    float digit2 = floor(seconds / 10.0);
    float digit3 = mod(seconds, 10.0);
    vec2 digitSize = vec2(0.024, 0.047);
    hud = max(hud, digitGlyph((uv - vec2(0.770, 0.065)) / digitSize,
                              digit0));
    hud = max(hud, digitGlyph((uv - vec2(0.797, 0.065)) / digitSize,
                              digit1));
    hud = max(hud, digitGlyph((uv - vec2(0.837, 0.065)) / digitSize,
                              digit2));
    hud = max(hud, digitGlyph((uv - vec2(0.864, 0.065)) / digitSize,
                              digit3));
    float colon = boxMask(uv, vec2(0.826, 0.080), vec2(0.831, 0.088));
    colon = max(colon, boxMask(uv, vec2(0.826, 0.099), vec2(0.831, 0.107)));
    hud = max(hud, colon);
    return clamp(hud, 0.0, 1.0);
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
    // Drive tape noise, jitter, and RF events from the analog field clock so
    // their speed is independent of the game's rendering frame rate.
    float frame = floor(time * VHS_FIELD_RATE);
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

    // Consumer digital zoom enlarges the already cropped camera image. Keeping
    // it before tape transport errors makes every later defect remain locked to
    // the recorded signal rather than to the Minecraft camera.
    sourceUv = 0.5 + (sourceUv - 0.5) / max(DIGITAL_ZOOM, 1.0);

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

    // The playback deck adds its own smoothly correlated time-base error on top
    // of the camera/tape generation. Neighboring lines bend together because a
    // real capstan and guide cannot jump in independent rectangular blocks.
    float signalLinePosition = frameUv.y * VHS_SIGNAL_LINES;
    float deckSlowTiming = smoothNoise21(vec2(signalLinePosition * 0.016 + 31.0,
                                              time * 0.67)) * 2.0 - 1.0;
    float deckFastTiming = smoothNoise21(vec2(signalLinePosition * 0.110 + 73.0,
                                              time * 4.20)) * 2.0 - 1.0;
    float lineTiming = deckSlowTiming * 0.72 + deckFastTiming * 0.28;

    // A failed tracking lock creates narrow, feathered tears with a mechanical
    // attack and release. A second weaker band resembles adjacent mistracked
    // helical-scan tracks rather than a collection of digital rectangles.
    float glitchPhase = time * 1.45;
    float glitchTick = floor(glitchPhase);
    float glitchAge = fract(glitchPhase);
    float glitchEvent = step(1.0 - GLITCH_FREQUENCY,
                             hash21(vec2(glitchTick, 19.37)));
    float glitchEnvelope = smoothstep(0.0, 0.045, glitchAge)
                         * (1.0 - smoothstep(0.12, 0.32, glitchAge));
    float tearCenter = hash21(vec2(glitchTick, 61.20));
    float tearWidth = mix(0.005, 0.026,
                          hash21(vec2(glitchTick, 27.90)));
    float primaryDistance = abs(frameUv.y - tearCenter);
    float primaryTear = 1.0 - smoothstep(tearWidth,
                                         tearWidth * 2.5,
                                         primaryDistance);
    float companionCenter = fract(tearCenter - 0.020
                                  - hash21(vec2(glitchTick, 84.40)) * 0.060);
    float companionDistance = abs(frameUv.y - companionCenter);
    float companionTear = (1.0 - smoothstep(tearWidth * 0.42,
                                            tearWidth * 1.35,
                                            companionDistance)) * 0.52;
    float glitchBand = glitchEvent * glitchEnvelope
                     * max(primaryTear, companionTear);
    float glitchDirection = hash21(vec2(glitchTick, 9.10)) * 2.0 - 1.0;
    glitchDirection += lineTiming * 0.20;
    float tearTexture = 0.58 + 0.42 * smoothNoise21(
        vec2(signalLinePosition * 0.060 + 11.0,
             time * 5.6 + glitchTick));
    float glitchPixels = lineTiming * TIMEBASE_ERROR
                       + glitchBand * glitchDirection
                       * GLITCH_STRENGTH * tearTexture;

    float trackingY = fract(time * 0.071 + 0.13 * sin(time * 0.19)
                            + TRACKING_CONTROL * 0.22);
    float trackingDistance = abs(frameUv.y - trackingY);
    trackingDistance = min(trackingDistance, 1.0 - trackingDistance);
    float trackingBand = pow(max(0.0, 1.0 - trackingDistance * 42.0), 3.0);
    glitchPixels += trackingBand
                  * (sin(time * 17.0) * GLITCH_STRENGTH * 0.22
                     + TRACKING_CONTROL * 9.0);
    sourceUv.x += glitchPixels * displayScale * pixel.x;

    // A chewed section of tape briefly buckles several neighboring scan lines.
    // The broad correlated envelope avoids the rectangular digital-glitch look.
    float chewPhase = time * 0.18;
    float chewTick = floor(chewPhase);
    float chewAge = fract(chewPhase);
    float chewEvent = step(1.0 - TAPE_CHEW_STRENGTH * 0.46,
                           hash21(vec2(chewTick, 307.1)));
    float chewWindow = smoothstep(0.0, 0.018, chewAge)
                     * (1.0 - smoothstep(0.055, 0.125, chewAge));
    float chewCenter = mix(0.12, 0.88, hash21(vec2(chewTick, 191.7)));
    float chewWidth = mix(0.018, 0.085, hash21(vec2(chewTick, 159.2)));
    float chewDistance = abs(frameUv.y - chewCenter);
    float chewBand = chewEvent * chewWindow
                   * (1.0 - smoothstep(chewWidth, chewWidth * 2.4,
                                       chewDistance));
    float chewRipple = sin(frameUv.y * 870.0 + time * 41.0)
                      + (smoothNoise21(vec2(frameUv.y * 94.0,
                                            time * 7.0)) * 2.0 - 1.0);
    sourceUv.x += chewBand * chewRipple * TAPE_CHEW_STRENGTH * 0.026;
    sourceUv.y += chewBand * chewRipple * TAPE_CHEW_STRENGTH * 0.0035;

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
    float focusCycle = smoothNoise21(vec2(time * 0.14, 203.8));
    float focusMiss = smoothstep(0.48, 0.88, focusCycle)
                    * FOCUS_HUNT_STRENGTH;
    float softRadius = (TAPE_SOFTNESS + focusMiss * 8.0) * displayScale;
    vec2 blurX = vec2(pixel.x * softRadius, 0.0);

    vec3 center = texture2D(colortex0, sourceUv).rgb;
    vec3 lumaLeft1 = texture2D(colortex0, safeUV(sourceUv - blurX, pixel)).rgb;
    vec3 lumaRight1 = texture2D(colortex0, safeUV(sourceUv + blurX, pixel)).rgb;
#if QUALITY_LEVEL < 2
    // Performance and Balanced reuse the first-radius taps. Cinematic retains
    // the complete outer filter for the most accurate delayed-luma ringing.
    vec3 lumaLeft2 = lumaLeft1;
    vec3 lumaRight2 = lumaRight1;
#else
    vec3 lumaLeft2 = texture2D(colortex0, safeUV(sourceUv - blurX * 2.0, pixel)).rgb;
    vec3 lumaRight2 = texture2D(colortex0, safeUV(sourceUv + blurX * 2.0, pixel)).rgb;
#endif
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

    // Broad asymmetric chroma taps reproduce the much lower color bandwidth of
    // VHS. The YIQ path keeps brightness sharp while I and Q smear differently.
    vec2 bleed = vec2((CHROMA_BLEED + CHROMA_AMOUNT * 0.50)
                      * displayScale * pixel.x, 0.0);
    float chromaLine = floor(frameUv.y * VHS_CHROMA_LINES);
    float chromaPhase = hash21(vec2(chromaLine, floor(time * 8.0))) - 0.5;
    chromaPhase += sin(frameUv.y * 37.0 + time * 1.3) * 0.18;
    vec2 chromaDrift = vec2(chromaPhase * (0.9 + CHROMA_AMOUNT * 0.22)
                            * displayScale * pixel.x, 0.0);
    vec2 chromaUv = safeUV(sourceUv + chromaDrift, pixel);
    vec2 splitOffset = vec2(CHROMA_AMOUNT * displayScale * pixel.x, 0.0);

    vec3 color;
#ifdef YIQ_SIGNAL
    vec3 chromaCenter = rgbToYiq(texture2D(colortex0, chromaUv).rgb);
    vec3 chromaBack1 = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv - bleed, pixel)).rgb);
    vec3 chromaFront1 = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv + bleed, pixel)).rgb);
#if QUALITY_LEVEL < 2
    vec3 chromaBack2 = chromaBack1;
    vec3 chromaFront2 = chromaFront1;
#else
    vec3 chromaBack2 = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv - bleed * 2.0, pixel)).rgb);
    vec3 chromaFront2 = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv + bleed * 2.0, pixel)).rgb);
#endif

    // I retains a little more detail than Q. Both filters trail predominantly
    // to the right because earlier samples remain in the color-under delay line.
    float tapeI = chromaCenter.y * 0.30
                + chromaBack1.y * 0.26
                + chromaFront1.y * 0.18
                + chromaBack2.y * 0.17
                + chromaFront2.y * 0.09;
    float tapeQ = chromaCenter.z * 0.20
                + chromaBack1.z * 0.18
                + chromaFront1.z * 0.13
                + chromaBack2.z * 0.31
                + chromaFront2.z * 0.18;

    // A small I/Q timing split replaces the legacy RGB offset. It produces color
    // fringes while leaving the reconstructed Y channel spatially undisturbed.
#if QUALITY_LEVEL < 2
    vec3 splitPositiveYiq = chromaFront1;
    vec3 splitNegativeYiq = chromaBack1;
#else
    vec3 splitPositiveYiq = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv + splitOffset, pixel)).rgb);
    vec3 splitNegativeYiq = rgbToYiq(texture2D(
        colortex0, safeUV(chromaUv - splitOffset, pixel)).rgb);
#endif
    float splitMix = clamp(CHROMA_AMOUNT / 9.0, 0.0, 1.0) * 0.30;
    vec2 tapeChroma = mix(vec2(tapeI, tapeQ),
                          vec2(splitPositiveYiq.y, splitNegativeYiq.z),
                          splitMix);

    // Line timing, tracking tears, and the rolling tracking band disturb the
    // color-subcarrier phase. Rotating I/Q yields authentic crawling hue error.
    float phaseAngle = CHROMA_PHASE_ERROR
                     * (chromaPhase * 1.35
                        + glitchBand * glitchDirection * 0.90
                        + trackingBand * sin(time * 11.0) * 0.55);
#if SIGNAL_STANDARD == 1
    phaseAngle *= mod(chromaLine, 2.0) * 2.0 - 1.0;
#endif
    tapeChroma = rotateChroma(tapeChroma, phaseAngle);
    color = yiqToRgb(vec3(tapeLuma,
                          tapeChroma * COLOR_SATURATION));
#else
    // Legacy RGB-residual path is available by disabling Signal-Accurate YIQ.
    vec3 chromaCenterRgb = texture2D(colortex0, chromaUv).rgb;
    vec3 chromaBack1Rgb = texture2D(
        colortex0, safeUV(chromaUv - bleed, pixel)).rgb;
    vec3 chromaFront1Rgb = texture2D(
        colortex0, safeUV(chromaUv + bleed, pixel)).rgb;
#if QUALITY_LEVEL < 2
    vec3 chromaBack2Rgb = chromaBack1Rgb;
    vec3 chromaFront2Rgb = chromaFront1Rgb;
#else
    vec3 chromaBack2Rgb = texture2D(
        colortex0, safeUV(chromaUv - bleed * 2.0, pixel)).rgb;
    vec3 chromaFront2Rgb = texture2D(
        colortex0, safeUV(chromaUv + bleed * 2.0, pixel)).rgb;
#endif
    vec3 chromaImage = chromaCenterRgb * 0.34
                     + chromaBack1Rgb * 0.25
                     + chromaFront1Rgb * 0.19
                     + chromaBack2Rgb * 0.13
                     + chromaFront2Rgb * 0.09;
    float chromaLuma = dot(chromaImage, vec3(0.299, 0.587, 0.114));
    color = vec3(tapeLuma)
          + (chromaImage - vec3(chromaLuma)) * COLOR_SATURATION;

    // Direct R/B displacement recreates the pack's original fringing behavior.
#if QUALITY_LEVEL < 2
    vec3 splitRgb = vec3(chromaFront1Rgb.r, center.g, chromaBack1Rgb.b);
#else
    vec3 splitRgb = vec3(
        texture2D(colortex0, safeUV(chromaUv + splitOffset, pixel)).r,
        center.g,
        texture2D(colortex0, safeUV(chromaUv - splitOffset, pixel)).b
    );
#endif
    float splitLuma = dot(splitRgb, vec3(0.299, 0.587, 0.114));
    color += (splitRgb - vec3(splitLuma))
           * clamp(CHROMA_AMOUNT / 9.0, 0.0, 1.0) * 0.42;
#endif

    // Spatial tape echo is independent from temporal history. Performance mode
    // removes this optional tap entirely; Balanced and Cinematic keep it as a
    // separately adjustable high-contrast horizontal echo.
#if QUALITY_LEVEL > 0
#ifdef SPATIAL_ECHO
    vec2 echoOffset = vec2((MOTION_SMEAR + 1.0) * displayScale * pixel.x, 0.0);
    vec3 echoRgb = texture2D(colortex0, safeUV(sourceUv - echoOffset, pixel)).rgb;
    color = mix(color, echoRgb, clamp(SPATIAL_ECHO_STRENGTH, 0.0, 0.25));
#endif
#endif

    // Signal-domain-looking coarse luma and colored chroma noise.
    vec2 noiseCell = floor(frameUv * vec2(VHS_SIGNAL_LINES)
                           / max(1.0, PIXEL_SCALE * 0.70));
    float grain = hash21(noiseCell + vec2(frame * 1.91, frame * 0.43)) - 0.5;
    float lineNoise = hash21(vec2(floor(frameUv.y * VHS_SIGNAL_LINES),
                                  floor(time * 31.0))) - 0.5;
    float chromaNoiseI = hash21(noiseCell * vec2(0.37, 1.0)
                                + vec2(frame * 0.71, 43.1)) - 0.5;
    float chromaNoiseQ = hash21(noiseCell * vec2(0.29, 1.0)
                                + vec2(frame * 0.53, 91.7)) - 0.5;
    float tapeNoiseY = grain * NOISE_STRENGTH * 0.54
                     + lineNoise * NOISE_STRENGTH * 0.17;
#ifdef YIQ_SIGNAL
    // Noise is injected into the same signal components as the recorded image:
    // fine Y grain remains crisp while I/Q noise forms softer colored blotches.
    vec3 tapeNoiseYiq = vec3(tapeNoiseY,
                             chromaNoiseI * NOISE_STRENGTH * 0.12,
                             chromaNoiseQ * NOISE_STRENGTH * 0.16);
    color += yiqToRgb(tapeNoiseYiq);
#else
    color += vec3(tapeNoiseY);
    color += vec3(chromaNoiseI, -chromaNoiseI * 0.36, chromaNoiseQ)
           * NOISE_STRENGTH * 0.18;
#endif

    // Tape format and copy generation. Each format has a different effective
    // chroma bandwidth and luma resolution; every analog copy compounds those
    // losses and adds a little cross-color contamination.
    float formatChroma = 1.0;
    float formatLevels = 512.0;
    float formatNoise = 0.0;
#if TAPE_FORMAT == 1
    formatChroma = 0.91;
    formatLevels = 384.0;
    formatNoise = 0.002;
#elif TAPE_FORMAT == 2
    formatChroma = 0.78;
    formatLevels = 256.0;
    formatNoise = 0.005;
#elif TAPE_FORMAT == 3
    formatChroma = 0.90;
    formatLevels = 420.0;
    formatNoise = 0.003;
#elif TAPE_FORMAT == 4
    formatChroma = 0.66;
    formatLevels = 180.0;
    formatNoise = 0.010;
#endif
    float copyGeneration = float(GENERATION_LOSS);
    vec3 generationYiq = rgbToYiq(color);
    float oldGenerationI = generationYiq.y;
    float oldGenerationQ = generationYiq.z;
    float generationRetention = formatChroma * pow(0.89, copyGeneration);
    generationYiq.y = (oldGenerationI + oldGenerationQ * 0.045
                       * copyGeneration) * generationRetention;
    generationYiq.z = (oldGenerationQ - oldGenerationI * 0.035
                       * copyGeneration) * generationRetention;
    float effectiveLevels = max(72.0, formatLevels
                                / (1.0 + copyGeneration * 0.34));
    generationYiq.x = floor(clamp(generationYiq.x, 0.0, 1.0)
                            * effectiveLevels + 0.5) / effectiveLevels;
    color = yiqToRgb(generationYiq);

    float wearLine = smoothNoise21(vec2(signalLinePosition * 0.075 + 211.0,
                                        time * 0.31));
    float oxideWear = smoothstep(0.58, 0.92, wearLine) * TAPE_WEAR;
    float generationNoise = hash21(noiseCell
                                    + vec2(frame * 0.23, 481.6)) - 0.5;
    color += vec3(generationNoise)
           * (formatNoise + copyGeneration * 0.0026 + TAPE_WEAR * 0.006);
    float generationLuma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(generationLuma),
                clamp(copyGeneration * 0.028 + oxideWear * 0.18, 0.0, 0.42));
    color = mix(color, vec3(0.48 + generationLuma * 0.38),
                oxideWear * 0.12);

    // Camera response is deliberately separate from the tape format: the same
    // cassette can therefore look as if it came from a tube, VHS, or early-DV
    // consumer camera.
#if CAMCORDER_ERA == 1
    color *= vec3(1.08, 1.00, 0.78);
    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))),
                0.08);
    color += vec3(0.020, 0.010, -0.008);
#elif CAMCORDER_ERA == 2
    color *= vec3(0.98, 1.07, 0.82);
    color = (color - 0.5) * 0.92 + 0.5;
#elif CAMCORDER_ERA == 3
    float digitalLuma = dot(color, vec3(0.299, 0.587, 0.114));
    color *= vec3(0.94, 1.00, 1.08);
    color += (color - vec3(digitalLuma)) * 0.10;
    color = floor(clamp(color, 0.0, 1.0) * 235.0 + 0.5) / 235.0;
#endif

    // Real capture grade: muted contrast, weak blue response, and green cast.
    color *= mix(vec3(1.0), vec3(0.94, 1.12, 0.72), TINT_STRENGTH * 0.92);
    color = (color - 0.5) * mix(1.0, 0.86, WASHOUT_STRENGTH) + 0.5;
    color = max(color - vec3(BLACK_CRUSH * 0.028), vec3(0.0));
    color = pow(max(color, vec3(0.0)), vec3(1.0 + BLACK_CRUSH * 0.88));

    float highlightBloom = smoothstep(0.68, 0.96, tapeLuma);
    color += vec3(tapeLuma) * highlightBloom * HALATION_STRENGTH * 0.18;

#if LIMINAL_MODE > 0
    // Liminal Signal lighting models a camcorder under aging fluorescent
    // fixtures. Each space gets a distinct lamp spectrum, while the slow
    // white-balance and gain loops remain common to all three modes.
    vec3 liminalPalette;
    vec3 liminalHazeColor;
    float liminalBaseExposure;
#if LIMINAL_MODE == 1
    // Backrooms: nicotine-yellow tubes with a weak green phosphor response.
    liminalPalette = vec3(1.12, 1.05, 0.72);
    liminalHazeColor = vec3(1.00, 0.91, 0.52);
    liminalBaseExposure = 0.98;
#elif LIMINAL_MODE == 2
    // Poolrooms: cyan tile bounce, humid air, and cleaner highlights.
    liminalPalette = vec3(0.72, 1.06, 1.16);
    liminalHazeColor = vec3(0.50, 0.94, 1.00);
    liminalBaseExposure = 1.04;
#else
    // Liminal Night: underexposed blue-green security-camera response.
    liminalPalette = vec3(0.58, 0.78, 1.12);
    liminalHazeColor = vec3(0.34, 0.55, 0.90);
    liminalBaseExposure = 0.78;
#endif

    color *= liminalPalette * liminalBaseExposure;

    // Consumer auto white balance never quite settles under discontinuous
    // fluorescent spectra. Correlated noise avoids clean cinematic oscillation.
    float balanceCycle = smoothNoise21(vec2(time * 0.12, 37.4));
    vec3 balanceCool = vec3(0.88, 0.98, 1.12);
    vec3 balanceWarm = vec3(1.12, 1.03, 0.82);
    vec3 balanceTint = mix(balanceCool, balanceWarm, balanceCycle);
    color *= mix(vec3(1.0), balanceTint, WHITE_BALANCE_DRIFT);

    // A slow rolling band represents shutter/mains mismatch; higher-frequency
    // ballast flutter and rare soft brownouts keep the light from feeling like
    // a simple sine-wave brightness filter.
#if SIGNAL_STANDARD == 1
    float fluorescentBeat = 0.37;
#else
    float fluorescentBeat = 0.43;
#endif
    float rollingMains = sin(frameUv.y * PI * 3.2
                           - time * PI * 2.0 * fluorescentBeat);
    float ballastFlutter = smoothNoise21(vec2(time * 8.4, 71.2)) * 2.0 - 1.0;
    float brownoutNoise = smoothNoise21(vec2(time * 0.23, 18.6));
    float softBrownout = smoothstep(0.78, 0.97, brownoutNoise);
    float fluorescentGain = rollingMains * 0.38
                           + ballastFlutter * 0.24
                           - softBrownout * 0.62;
    color *= 1.0 + fluorescentGain * FLUORESCENT_FLICKER * 0.18;

    // Empty liminal rooms make cheap camera gain conspicuous. The response is
    // biased upward in shadows and drifts slowly instead of pumping every frame.
    float exposureCycle = smoothNoise21(vec2(time * 0.095, 94.1)) * 2.0 - 1.0;
    float darkGainDemand = 1.0 - smoothstep(0.08, 0.56, tapeLuma);
    float exposureHunt = darkGainDemand * 0.16 + exposureCycle * 0.10;
    color *= 1.0 + exposureHunt * EXPOSURE_HUNT_STRENGTH;

    // Veiling glare lifts the air without pretending to add world-space fog.
    // It is strongest around lamps and in low-contrast shadow detail.
    float hazeAmount = LIMINAL_HAZE
                     * (0.035 + highlightBloom * 0.16
                        + (1.0 - tapeLuma) * 0.035);
    vec3 hazeTarget = liminalHazeColor * (0.34 + tapeLuma * 0.46);
    color = mix(color, hazeTarget, clamp(hazeAmount, 0.0, 0.28));
    color += liminalHazeColor * highlightBloom * LIMINAL_HAZE * 0.07;
#endif

    // Uneven exposure flutter.
    float flickerWave = sin(time * 19.7) * 0.50
                      + sin(time * 7.3 + 2.0) * 0.28
                      + (hash21(vec2(frame, 31.0)) - 0.5) * 0.90;
    color *= 1.0 + flickerWave * FLICKER_STRENGTH;

    // Field parity follows the selected analog standard instead of the game's
    // frame rate: 59.94 fields/s for NTSC or 50 fields/s for PAL.
    float tapeLine = floor(frameUv.y * VHS_SIGNAL_LINES);
    float fieldParity = mod(floor(time * VHS_FIELD_RATE), 2.0);
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

    // RF ingress forms diagonal herringbone carriers plus slowly rolling bright
    // bands. It remains signal-like at every resolution by using display pixels
    // for the carrier and normalized coordinates for the rolling envelope.
    float rfCarrierA = sin(frameUv.x * viewWidth * 0.31
                         + frameUv.y * viewHeight * 0.095
                         + time * 46.0);
    float rfCarrierB = sin(frameUv.x * viewWidth * 0.27
                         - frameUv.y * viewHeight * 0.082
                         - time * 39.0);
    float rfHerringbone = (rfCarrierA * rfCarrierB) * 0.5;
    float rfBandCenter = fract(time * 0.083
                               + smoothNoise21(vec2(time * 0.07, 517.2))
                               * 0.22);
    float rfBandDistance = abs(frameUv.y - rfBandCenter);
    rfBandDistance = min(rfBandDistance, 1.0 - rfBandDistance);
    float rfBand = 1.0 - smoothstep(0.012, 0.085, rfBandDistance);
    color += vec3(rfHerringbone * 0.055 + rfBand * 0.085)
           * RF_INTERFERENCE_STRENGTH;
    color = mix(color, vec3(staticValue),
                chewBand * TAPE_CHEW_STRENGTH * 0.72);

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

#ifdef CAMCORDER_HUD
    // Camera-generated markings are recorded with the image, so their color
    // follows the selected camera era instead of the deck's PLAY overlay.
    float cameraHud = camcorderOsd(frameUv, time) * frameMask;
#if CAMCORDER_ERA == 1
    vec3 cameraHudColor = vec3(1.00, 0.34, 0.18);
#elif CAMCORDER_ERA == 3
    vec3 cameraHudColor = vec3(0.72, 0.94, 1.00);
#else
    vec3 cameraHudColor = vec3(0.96, 0.98, 0.88);
#endif
    color *= 1.0 - cameraHud * 0.30;
    color = mix(color, cameraHudColor, cameraHud * 0.92);
#endif

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
