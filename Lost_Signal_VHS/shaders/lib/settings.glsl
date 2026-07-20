#ifndef LOST_SIGNAL_VHS_SETTINGS_GLSL
#define LOST_SIGNAL_VHS_SETTINGS_GLSL

// -----------------------------------------------------------------------------
// User options
// Iris discovers these macros and exposes them through shaders.properties.
// The values in square brackets are the allowed positions on each UI slider.
// -----------------------------------------------------------------------------

// Tape damage
#define NOISE_STRENGTH 0.10 // [0.00 0.03 0.06 0.10 0.14 0.20 0.28] Fine monochrome and colored tape grain.
#define SCANLINE_STRENGTH 0.38 // [0.00 0.12 0.22 0.30 0.38 0.48 0.60] Darkness of the three-pixel VHS scanline pattern.
#define GLITCH_FREQUENCY 0.16 // [0.00 0.04 0.08 0.12 0.16 0.24 0.35 0.50] Chance of a horizontal tracking-tear event.
#define GLITCH_STRENGTH 10.0 // [0.0 2.0 4.0 7.0 10.0 16.0 24.0 36.0] Maximum horizontal tracking displacement, in pixels.
#define STATIC_FREQUENCY 0.14 // [0.00 0.04 0.08 0.14 0.22 0.35 0.50] Chance of a short full-screen static burst.

// Camera imperfections
#define CHROMA_AMOUNT 2.5 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0 9.0] Red/blue channel separation, in pixels.
#define LENS_DISTORTION 0.025 // [0.000 0.008 0.015 0.025 0.040 0.060 0.085] Cheap camcorder barrel distortion.
#define FLICKER_STRENGTH 0.035 // [0.000 0.010 0.020 0.035 0.055 0.080 0.120] Rapid and random exposure flutter.
#define FRAME_JITTER 1.2 // [0.0 0.4 0.8 1.2 1.8 2.6 4.0] Random whole-frame displacement, in pixels.
#define WOBBLE_STRENGTH 1.5 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Slow handheld drift, in pixels.
#define MOTION_SMEAR 1.5 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Horizontal analog blur radius, in pixels.
#define GHOST_STRENGTH 0.13 // [0.00 0.04 0.08 0.13 0.18 0.25 0.35] Amount of the previous processed frame retained.
#define PIXEL_SCALE 2.0 // [1.0 1.5 2.0 2.5 3.0 4.0 6.0] Virtual pixel size; output resolution stays unchanged.

// Color and framing
#define WASHOUT_STRENGTH 0.34 // [0.00 0.12 0.22 0.34 0.48 0.62 0.78] Desaturation and reduced contrast.
#define TINT_STRENGTH 0.30 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70] Sickly green/yellow security-camera tint.
#define VIGNETTE_STRENGTH 0.52 // [0.00 0.18 0.32 0.42 0.52 0.65 0.80] Darkness of the cheap-lens corners.

#endif

