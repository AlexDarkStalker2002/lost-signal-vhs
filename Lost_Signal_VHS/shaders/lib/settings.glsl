#ifndef LOST_SIGNAL_VHS_SETTINGS_GLSL
#define LOST_SIGNAL_VHS_SETTINGS_GLSL

// -----------------------------------------------------------------------------
// User options
// Iris discovers these macros and exposes them through shaders.properties.
// The values in square brackets are the allowed positions on each UI slider.
// -----------------------------------------------------------------------------

// Tape damage
#define NOISE_STRENGTH 0.10 // [0.00 0.03 0.06 0.10 0.14 0.20 0.28] Soft monochrome and colored tape grain.
#define SCANLINE_STRENGTH 0.22 // [0.00 0.12 0.22 0.30 0.38 0.48 0.60] Interlaced horizontal line modulation.
#define GLITCH_FREQUENCY 0.08 // [0.00 0.04 0.08 0.12 0.16 0.24 0.35 0.50] Chance of a horizontal tracking-tear event.
#define GLITCH_STRENGTH 7.0 // [0.0 2.0 4.0 7.0 10.0 16.0 24.0 36.0] Maximum horizontal tracking displacement, in pixels.
#define STATIC_FREQUENCY 0.04 // [0.00 0.04 0.08 0.14 0.22 0.35 0.50] Chance of a short full-screen static burst.

// Signal instability. Every new behavior has its own toggle and intensity so
// presets can use it without forcing it on custom configurations.
#define AUTO_EXPOSURE // Slowly pumps gain after large scene-brightness changes.
#define EXPOSURE_PUMP_STRENGTH 0.35 // [0.00 0.15 0.25 0.35 0.50 0.70 1.00] Automatic camcorder gain correction strength.
#define CHROMA_KILLER // Briefly removes color when tracking lock becomes weak.
#define CHROMA_KILLER_STRENGTH 0.65 // [0.00 0.25 0.50 0.65 0.80 1.00] Color loss during tracking and sync errors.
#define VERTICAL_SYNC_GLITCH // Rare vertical rolls or short held-frame events.
#define SYNC_GLITCH_FREQUENCY 0.04 // [0.00 0.02 0.04 0.08 0.14 0.22 0.35] Chance per four-second sync event cell.
#define SYNC_GLITCH_STRENGTH 0.70 // [0.00 0.25 0.50 0.70 0.85 1.00] Roll distance and held-frame opacity.
#define CHROMA_PERSISTENCE // Lets recorded color trail longer than luminance.
#define CHROMA_PERSISTENCE_STRENGTH 0.20 // [0.00 0.05 0.10 0.15 0.20 0.30 0.45] Previous-frame color retained during movement.

// Camera imperfections
#define CHROMA_AMOUNT 4.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0 9.0] Red/blue channel misalignment, in pixels.
#define LENS_DISTORTION 0.040 // [0.000 0.008 0.015 0.025 0.040 0.060 0.085] Consumer CRT/camcorder barrel distortion.
#define FLICKER_STRENGTH 0.020 // [0.000 0.010 0.020 0.035 0.055 0.080 0.120] Uneven analog exposure flutter.
#define FRAME_JITTER 0.8 // [0.0 0.4 0.8 1.2 1.8 2.6 4.0] Random frame displacement, in pixels.
#define WOBBLE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Slow imperfect image drift, in pixels.
#define MOTION_SMEAR 4.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Horizontal luma smear radius, in pixels.
#define GHOST_STRENGTH 0.18 // [0.00 0.04 0.08 0.13 0.18 0.25 0.35] Amount of the previous processed frame retained.
#define PIXEL_SCALE 4.0 // [1.0 1.5 2.0 2.5 3.0 4.0 6.0] Virtual tape sampling cell size.

// Real tape / deck capture characteristics
#define TAPE_SOFTNESS 4.0 // [0.0 1.0 2.0 3.0 4.0 5.0 7.0 10.0] Loss of fine luma detail, in logical pixels.
#define CHROMA_BLEED 12.0 // [0.0 2.0 4.0 6.0 9.0 12.0 16.0 24.0] Broad color bandwidth loss and rightward bleeding.
#define BLACK_CRUSH 0.42 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70] Darkens weak VHS shadow detail.
#define COLOR_SATURATION 1.55 // [0.60 0.80 1.00 1.15 1.35 1.55 1.80] Analog color decoder saturation.
#define HEAD_SWITCHING 0.40 // [0.00 0.15 0.30 0.40 0.55 0.70 0.90] Noisy horizontal tearing at the bottom of the tape.
#define HALATION_STRENGTH 0.50 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Soft glow around overexposed fluorescent lights.
#define LUMA_RINGING 0.55 // [0.00 0.10 0.25 0.35 0.45 0.55 0.70 0.90] Bright/dark edge echoes from VHS luma sharpening.

// Enabled by default for the supplied real-VHS reference look.
#define VHS_4_3 // Crop the camera image into a centered 4:3 playback frame.
#define ROUNDED_OVERSCAN // Add a soft rounded black playback border.
//#define VHS_OSD // Optional PLAY, transport, SLP, and tracking display. Off by default.

// Color and framing
#define WASHOUT_STRENGTH 0.12 // [0.00 0.12 0.22 0.34 0.48 0.62 0.78] Faded highlights and reduced contrast.
#define TINT_STRENGTH 0.20 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70] Green cast from the tape color decoder.
#define VIGNETTE_STRENGTH 0.52 // [0.00 0.18 0.32 0.42 0.52 0.65 0.80] Darkness of the playback-frame corners.

#endif
