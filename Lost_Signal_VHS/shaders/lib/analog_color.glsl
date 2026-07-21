#ifndef LOST_SIGNAL_VHS_ANALOG_COLOR_GLSL
#define LOST_SIGNAL_VHS_ANALOG_COLOR_GLSL

// NTSC YIQ separates image brightness (Y) from the two color components
// recorded by the composite/tape signal (I and Q). Processing I/Q separately
// lets VHS color lose horizontal detail and timing lock without blurring luma.
vec3 rgbToYiq(vec3 rgb) {
    return vec3(
        dot(rgb, vec3(0.299,  0.587,  0.114)),
        dot(rgb, vec3(0.596, -0.274, -0.322)),
        dot(rgb, vec3(0.211, -0.523,  0.312))
    );
}

// Decode the damaged tape signal back to display RGB. Values are deliberately
// not clamped here: ringing and phase errors need room to overshoot first.
vec3 yiqToRgb(vec3 yiq) {
    return vec3(
        yiq.x + 0.956 * yiq.y + 0.621 * yiq.z,
        yiq.x - 0.272 * yiq.y - 0.647 * yiq.z,
        yiq.x - 1.106 * yiq.y + 1.703 * yiq.z
    );
}

// A loss of color-subcarrier phase rotates I into Q and Q into I. On real
// playback this appears as slowly crawling hue error rather than an RGB tint.
vec2 rotateChroma(vec2 iq, float angle) {
    float phaseCos = cos(angle);
    float phaseSin = sin(angle);
    return vec2(
        iq.x * phaseCos - iq.y * phaseSin,
        iq.x * phaseSin + iq.y * phaseCos
    );
}

#endif
