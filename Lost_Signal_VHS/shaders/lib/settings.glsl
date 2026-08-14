#ifndef LOST_SIGNAL_VHS_SETTINGS_GLSL
#define LOST_SIGNAL_VHS_SETTINGS_GLSL

// -----------------------------------------------------------------------------
// User options
// Iris discovers these macros and exposes them through shaders.properties.
// The values in square brackets are the allowed positions on each UI slider.
// -----------------------------------------------------------------------------

// Compatibility and performance
#define QUALITY_LEVEL 1 // [0 1 2] 0 = Performance, 1 = Balanced, 2 = Cinematic.
#define SIGNAL_STANDARD 0 // [0 1] 0 = NTSC 480-line/59.94-field signal, 1 = PAL 576-line/50-field signal.

// Tape damage
#define NOISE_STRENGTH 0.10 // [0.00 0.03 0.06 0.10 0.14 0.20 0.28] Soft monochrome and colored tape grain.
#define SCANLINE_STRENGTH 0.22 // [0.00 0.12 0.22 0.30 0.38 0.48 0.60] Interlaced horizontal line modulation.
#define GLITCH_FREQUENCY 0.08 // [0.00 0.04 0.08 0.12 0.16 0.24 0.35 0.50] Chance of a horizontal tracking-tear event.
#define GLITCH_STRENGTH 7.0 // [0.0 2.0 4.0 7.0 10.0 16.0 24.0 36.0] Maximum horizontal tracking displacement, in pixels.
#define TIMEBASE_ERROR 1.2 // [0.0 0.4 0.8 1.2 1.8 2.6 4.0 6.0] Continuous analog horizontal timing error, in pixels.
#define STATIC_FREQUENCY 0.04 // [0.00 0.04 0.08 0.14 0.22 0.35 0.50] Chance of a short full-screen static burst.

// Tape format and generation loss
#define TAPE_FORMAT 0 // [0 1 2 3 4] VHS SP, VHS LP, VHS SLP, VHS-C, or worn rental tape.
#define GENERATION_LOSS 0 // [0 1 2 3 4 5] Number of analog copy generations.
#define TAPE_WEAR 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Oxide wear, fading, and low-level line damage.

// Signal instability. Every new behavior has its own toggle and intensity so
// presets can use it without forcing it on custom configurations.
#define YIQ_SIGNAL // Process color as a bandwidth-limited analog YIQ signal.
#define CHROMA_PHASE_ERROR 0.35 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Line-dependent hue wobble from unstable color phase.
#define AUTO_EXPOSURE // Slowly pumps gain after large scene-brightness changes.
#define EXPOSURE_PUMP_STRENGTH 0.35 // [0.00 0.15 0.25 0.35 0.50 0.70 1.00] Automatic camcorder gain correction strength.
#define CHROMA_KILLER // Briefly removes color when tracking lock becomes weak.
#define CHROMA_KILLER_STRENGTH 0.65 // [0.00 0.25 0.50 0.65 0.80 1.00] Color loss during tracking and sync errors.
#define VERTICAL_SYNC_GLITCH // Rare vertical rolls or short held-frame events.
#define SYNC_GLITCH_FREQUENCY 0.04 // [0.00 0.02 0.04 0.08 0.14 0.22 0.35] Chance per four-second sync event cell.
#define SYNC_GLITCH_STRENGTH 0.70 // [0.00 0.25 0.50 0.70 0.85 1.00] Roll distance and held-frame opacity.
#define CHROMA_PERSISTENCE // Lets recorded color trail longer than luminance.
#define CHROMA_PERSISTENCE_STRENGTH 0.20 // [0.00 0.05 0.10 0.15 0.20 0.30 0.45] Previous-frame color retained during movement.

// Composite decoder. The consumer notch path deliberately leaks high-frequency
// luma into color and color back into luma; the two-line comb path suppresses
// most of that leakage on vertically correlated picture detail.
#define COMPOSITE_DECODER 1 // [0 1 2] Bypass, consumer notch filter, or two-line comb filter.
#define DOT_CRAWL_STRENGTH 0.25 // [0.00 0.10 0.20 0.25 0.35 0.50 0.70 1.00] Moving subcarrier dots along sharp color and brightness edges.
#define CROSS_COLOR_STRENGTH 0.20 // [0.00 0.08 0.15 0.20 0.30 0.45 0.65 1.00] False rainbow color decoded from fine luminance detail.
#define CROSS_LUMA_STRENGTH 0.15 // [0.00 0.08 0.15 0.20 0.30 0.45 0.65 1.00] Chroma carrier leaking into the reconstructed luminance channel.

// Camera imperfections
#define CHROMA_AMOUNT 4.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0 9.0] Red/blue channel misalignment, in pixels.
#define LENS_DISTORTION 0.040 // [0.000 0.008 0.015 0.025 0.040 0.060 0.085] Consumer CRT/camcorder barrel distortion.
#define FLICKER_STRENGTH 0.020 // [0.000 0.010 0.020 0.035 0.055 0.080 0.120] Uneven analog exposure flutter.
#define FRAME_JITTER 0.8 // [0.0 0.4 0.8 1.2 1.8 2.6 4.0] Random frame displacement, in pixels.
#define WOBBLE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Slow imperfect image drift, in pixels.
#define MOTION_SMEAR 4.0 // [0.0 0.5 1.0 1.5 2.5 4.0 6.0] Horizontal luma smear radius, in pixels.
#define GHOST_STRENGTH 0.18 // [0.00 0.04 0.08 0.13 0.18 0.25 0.35] Amount of the previous processed frame retained.
#define HISTORY_STABILIZATION 0.55 // [0.00 0.25 0.40 0.55 0.70 0.85 1.00] Rejects implausible history colors during fast camera motion.
#define MOTION_AWARE_HISTORY // Reprojects the previous processed frame through camera depth and matrices.
#define REPROJECTION_STRENGTH 0.85 // [0.00 0.25 0.40 0.55 0.70 0.85 1.00] Moves temporal trails with stable world geometry while retaining some analog lag.
#define SPATIAL_ECHO // Adds a separate single-frame horizontal tape echo.
#define SPATIAL_ECHO_STRENGTH 0.08 // [0.00 0.03 0.05 0.08 0.12 0.18 0.25] Strength of the non-temporal horizontal echo.
#define PIXEL_SCALE 4.0 // [1.0 1.5 2.0 2.5 3.0 4.0 6.0] Virtual tape sampling cell size.

// Camcorder generation and optics
#define CAMCORDER_ERA 0 // [0 1 2 3] Neutral, 1980s tube camera, 1990s VHS camcorder, or early-2000s digital camcorder.
//#define CAMCORDER_HUD // REC, battery, and running timecode generated by the camera.
#define DIGITAL_ZOOM 1.0 // [1.0 1.1 1.2 1.35 1.5 2.0] Centered consumer digital zoom.
#define FOCUS_HUNT_STRENGTH 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Slow autofocus misses and recovery.

// Real tape / deck capture characteristics
#define TAPE_SOFTNESS 4.0 // [0.0 1.0 2.0 3.0 4.0 5.0 7.0 10.0] Loss of fine luma detail, in logical pixels.
#define CHROMA_BLEED 12.0 // [0.0 2.0 4.0 6.0 9.0 12.0 16.0 24.0] Broad color bandwidth loss and rightward bleeding.
#define BLACK_CRUSH 0.42 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70] Darkens weak VHS shadow detail.
#define COLOR_SATURATION 1.55 // [0.60 0.80 1.00 1.15 1.35 1.55 1.80] Analog color decoder saturation.
#define HEAD_SWITCHING 0.40 // [0.00 0.15 0.30 0.40 0.55 0.70 0.90] Noisy horizontal tearing at the bottom of the tape.
#define HALATION_STRENGTH 0.50 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Soft glow around overexposed fluorescent lights.
#define LUMA_RINGING 0.55 // [0.00 0.10 0.25 0.35 0.45 0.55 0.70 0.90] Bright/dark edge echoes from VHS luma sharpening.

// Liminal-space lighting. Mode 0 leaves the normal VHS grade untouched.
// The other modes share the same light physics while using distinct palettes.
#define LIMINAL_MODE 0 // [0 1 2 3] Off, Backrooms, Poolrooms, or Liminal Night.
#define FLUORESCENT_FLICKER 0.00 // [0.00 0.08 0.15 0.25 0.35 0.50 0.70 1.00] Rolling mains hum and unstable fluorescent ballast.
#define WHITE_BALANCE_DRIFT 0.00 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70 1.00] Slow warm/cool camcorder white-balance hunting.
#define EXPOSURE_HUNT_STRENGTH 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Slow gain breathing in empty bright and dark spaces.
#define LIMINAL_HAZE 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Veiling glare and lifted air around artificial lights.

// Camera-space atmospheric fog. Unlike LIMINAL_HAZE, this uses scene depth and
// is applied before the signal enters the virtual tape deck, so distant air
// receives the same chroma loss, ghosting, and composite artifacts as geometry.
#define FOG_MODE 0 // [0 1 2 3 4] Off, neutral gray, Backrooms yellow, Poolrooms cyan, or Liminal Night green.
#define FOG_DENSITY 0.25 // [0.00 0.10 0.18 0.25 0.35 0.50 0.70 1.00] Optical density of the depth-based fog.
#define FOG_START 12.0 // [0.0 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0] Clear distance from the camera, in blocks.
#define FOG_DISTANCE 96.0 // [24.0 32.0 48.0 64.0 80.0 96.0 128.0 192.0 256.0] Distance over which fog approaches full density, in blocks.
#define FOG_NOISE 0.25 // [0.00 0.10 0.20 0.25 0.35 0.50 0.70 1.00] Slow world-anchored variation in fog density.

// Broken-signal controls
#define TRACKING_CONTROL 0.0 // [-1.0 -0.7 -0.4 0.0 0.4 0.7 1.0] Manual tracking bias and rolling-band position.
#define RF_INTERFERENCE_STRENGTH 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Radio-frequency herringbone noise and bright interference bands.
#define TAPE_CHEW_STRENGTH 0.00 // [0.00 0.10 0.20 0.35 0.50 0.70 1.00] Rare buckled-tape displacement and noise.
#define TAPE_DEFECT_MEMORY // Keeps oxide dropouts attached to a continuously moving virtual tape coordinate.
#define DEFECT_DENSITY 0.15 // [0.00 0.05 0.10 0.15 0.20 0.35 0.50 0.70] Frequency of persistent oxide holes and damaged helical tracks.
#define DEFECT_STRENGTH 0.25 // [0.00 0.10 0.20 0.25 0.35 0.50 0.70 1.00] Visibility, desaturation, and RF noise of persistent tape defects.
//#define FRAME_REPEAT // Lets the deck repeat the previous processed frame.
#define FRAME_REPEAT_FREQUENCY 0.00 // [0.00 0.02 0.04 0.08 0.14 0.22 0.35] Chance of a repeated-frame event.
#define FRAME_REPEAT_STRENGTH 0.00 // [0.00 0.25 0.50 0.70 0.85 1.00] Previous-frame opacity during a repeat.

// Enabled by default for the supplied real-VHS reference look.
#define VHS_4_3 // Crop the camera image into a centered 4:3 playback frame.
#define ROUNDED_OVERSCAN // Add a soft rounded black playback border.
#define INTERLACED_FIELDS // Store alternate raster fields in the history buffer.
#define INTERLACE_STRENGTH 0.92 // [0.00 0.25 0.50 0.70 0.85 0.92 1.00] Previous-field contribution on lines not refreshed by the current field.
//#define VHS_OSD // Optional PLAY, transport, SLP, and tracking display. Off by default.

// Color and framing
#define WASHOUT_STRENGTH 0.12 // [0.00 0.12 0.22 0.34 0.48 0.62 0.78] Faded highlights and reduced contrast.
#define TINT_STRENGTH 0.20 // [0.00 0.10 0.20 0.30 0.42 0.55 0.70] Green cast from the tape color decoder.
#define VIGNETTE_STRENGTH 0.52 // [0.00 0.18 0.32 0.42 0.52 0.65 0.80] Darkness of the playback-frame corners.

// Compile-time constants shared by both tape generations. Keeping the standard
// selection in one place prevents version-specific shader forks.
#if SIGNAL_STANDARD == 1
    #define VHS_SIGNAL_LINES 576.0
    #define VHS_CHROMA_LINES 288.0
    #define VHS_FIELD_RATE 50.0
#else
    #define VHS_SIGNAL_LINES 480.0
    #define VHS_CHROMA_LINES 240.0
    #define VHS_FIELD_RATE 59.94
#endif

#endif
