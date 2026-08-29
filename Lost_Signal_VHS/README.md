# Lost Signal VHS

An Iris shader pack for Minecraft Java Edition that turns the vanilla scene into
cheap, unstable found footage: scanlines, tape grain, tracking tears, color
bleeding, camcorder lens distortion, flicker, temporal ghosting, frame jitter,
and a yellow-green security-camera grade. Version 1.9 retains the depth-based
analog fog, world-stable density variation, and Minecraft 1.18.2–26.2
compatibility target while adding persistent depth-aware history and automatic
gain state, consolidating composite separation into one physical playback
decoder, locking head-switch artifacts to one field event, and reorganizing the
complete settings set into a simpler three-level menu. Its
optional signal-accurate YIQ path
processes brightness and analog color independently instead of applying a
generic RGB blur.

The pack keeps Minecraft's normal lighting and applies the VHS treatment after
the world is rendered. Lightweight geometry fallback programs preserve the
vanilla-lit scene across the project's primary Iris targets, so the same pack
can render the Overworld, Nether, and End without dimension-specific files.

## Compatibility

**Established primary targets:**

- Minecraft Java Edition 26.2 or 26.1.2 with Iris 1.11.2 and Sodium
- Minecraft Java Edition 1.21.11 with Iris 1.10.7 and Sodium
- Minecraft Java Edition 1.21.4 with Iris 1.8.8 and Sodium
- Minecraft Java Edition 1.21.1 with Iris 1.8.12 and Sodium
- Minecraft Java Edition 1.20.1 with Iris 1.7.6 and Sodium

**Extended compatibility targets:**

- Minecraft Java Edition 1.21.10 with Iris 1.9.7 and Sodium
- Minecraft Java Edition 1.21.8 with Iris 1.9.5 and Sodium
- Minecraft Java Edition 1.21.5 with Iris 1.8.11 and Sodium
- Minecraft Java Edition 1.20.6 with Iris 1.7.0 and Sodium
- Minecraft Java Edition 1.20.4 with Iris 1.7.2 and Sodium
- Minecraft Java Edition 1.19.4 with Iris 1.6.11 and Sodium
- Minecraft Java Edition 1.18.2 with Iris 1.6.11 and Sodium

Extended entries use the same conservative GLSL 1.20, depth-buffer, and
composite interfaces, but have not all been live-tested across every loader,
GPU, and driver combination. Include your Minecraft version, Iris version, GPU,
and driver when reporting an issue.

All targets require the OpenGL graphics backend. The pack follows the standard
OptiFine shader-pack layout and targets Iris's conservative GLSL 1.20 composite
interfaces. The listed combinations have not all been live-tested with v1.9.

No resource pack, noise texture, or compute-shader support is required.

Minecraft 26.2 introduced an experimental Vulkan backend, but Iris is not
compatible with Vulkan. Leave **Graphics API** on **Default** (OpenGL in the
26.2 release) or select **Prefer OpenGL** before starting the game with Iris.

If the pointer disappears in Minecraft's **Exclusive** fullscreen menus, press
`F11` to enter windowed mode, or `Alt+Tab` away and back. GLSL shader code
cannot capture the Windows cursor. If the issue remains with shaders disabled,
report it as a Minecraft/Iris window-focus problem rather than a pack effect.

## Installation

1. Copy the `Lost_Signal_VHS` folder, or its ZIP file, into Minecraft's
   `shaderpacks` directory.
2. On Minecraft 26.2, open **Video Settings > Graphics API** and choose
   **Default** or **Prefer OpenGL**. Restart the game if the setting changes.
3. Start Minecraft with the compatible Iris release listed above.
4. Open **Options > Video Settings > Shader Packs**.
5. Select **Lost Signal VHS** and apply it.
6. Open **Shader Pack Settings** to choose a preset or tune individual effects.

Typical shader-pack directories:

- Windows: `%APPDATA%\.minecraft\shaderpacks`
- macOS: `~/Library/Application Support/minecraft/shaderpacks`
- Linux: `~/.minecraft/shaderpacks`

Do not place the pack in `resourcepacks`; this is an Iris shader pack.

## Testing checklist

1. Test in a fluorescent interior or a long, empty corridor. Pale concrete,
   end stone, sandstone, and yellow lighting show the grade especially well.
2. Walk sideways past pillars or door frames. Their old positions should remain
   as a faint trail; this verifies the persistent history buffer.
3. Turn quickly. You should see temporal ghosting, a small handheld wobble, and
   occasional horizontal displacement.
4. Stand still for 10-20 seconds. You should see brightness flutter, rolling
   tracking bands, grain, and brief static bursts.
5. Move quickly from a dark corridor into a bright exterior, then back again.
   Persistent automatic gain should reduce overload quickly and recover more
   slowly in darkness. Higher Sync Failure Frequency values make rolls and held
   fields easier to verify without waiting for the deliberately rare default
   event.
6. Resize the window or reload the pack. Iris recreates the history buffer, so
   temporal ghosting can take two frames to initialize.
7. For an A/B check, use Iris's shader toggle while looking at a textured wall.
   The VHS version should remain readable; only color should bleed broadly.
8. In **Advanced Settings > Signal & Decoder**, compare **Signal-Accurate YIQ**
   on and off while looking at a sharp red or blue edge. YIQ mode should keep
   the brightness edge legible while its color trails horizontally and wobbles
   slightly between lines.
9. At Balanced or Cinematic quality, look at a fine black-and-white texture
   with **Consumer Notch** selected. The five-tap decoder should develop moving
   false color and edge dots. With NTSC timing, Cinematic **Two-Line Comb**
   should suppress them on vertically correlated detail while retaining errors
   around motion and diagonals. PAL deliberately uses the safe notch path.
10. Strafe and turn around a nearby pillar with **Motion-Aware History** enabled.
    The faint tape trail should follow the pillar instead of sticking to the
    original screen coordinate. Newly revealed background must not inherit the
    pillar's trail; this verifies persistent depth metadata and disocclusion
    rejection.
11. Raise **Defect Density** temporarily and watch one damaged track cross
    several fields without changing its horizontal shape every rendered frame.
12. Select **Analog Fog**, look down a long corridor, and compare nearby blocks
    with distant geometry. The hand should remain clear while distant air gains
    tape color bleed and stable slow density variation.
13. Switch from **Analog Fog** to **Reference VHS**. Neutral fog and the
    Analog-Fog decoder/defect overrides must clear immediately; render quality
    and NTSC/PAL remain global choices.
14. Increase **Head Switching** and watch the lower tape area. Horizontal tear,
    chroma loss, and RF noise should occur together and remain locked to analog
    field timing rather than appearing as three unrelated random glitches.

For shader compile diagnostics, open the Iris shader selection screen and press
`Ctrl+D` on Windows/Linux or `Cmd+D` on macOS to toggle Iris debug mode.

## Tuning

The settings menu provides thirteen presets:

- **Reference VHS**: matches the supplied real-tape screenshots: saturated green
  chroma, edge ringing, crushed shadows, bright halation, and no text overlay.
- **Real VHS**: a heavy 4:3 deck look with color bleed, crushed blacks,
  temporal trails, and head-switch noise.
- **Backrooms**: yellow-green 4:3 analog-horror footage with rolling
  fluorescent hum, depth fog, drifting white balance, and no OSD.
- **Poolrooms**: cyan reflected light, humid depth fog, restrained tape damage,
  and clean aquatic highlights.
- **Liminal Night**: underexposed blue-green corridors with dense unstable air,
  stronger gain hunting, and deep vignette.
- **Subtle**: a restrained consumer-camcorder look.
- **Found Footage**: the analog-horror balance without the deck OSD.
- **Damaged Tape**: stronger tears, static, color separation, and ghosting.
- **Rental Tape**: a fourth-generation worn cassette with faded oxide,
  restricted chroma bandwidth, and weak radio interference.
- **Camcorder 1996**: VHS-C response with a recorded REC/battery/timecode HUD,
  mild digital zoom, and slow autofocus hunting.
- **Broken Signal**: severe mistracking, RF herringbone, buckled tape, and
  genuine previous-frame repetition.
- **Composite Decode**: consumer notch-filter leakage, crawling edge dots,
  false rainbow color, motion-aware trails, and persistent oxide defects.
- **Analog Fog**: neutral scene-depth fog recorded through the complete
  composite decoder, temporal history, and worn-tape pipeline.

Version 1.9 preserves all thirteen intended preset looks, and each preset now
resets every preset-owned option. Switching away from **Analog Fog** therefore
clears its fog and restores the destination preset's decoder and tape-defect
values instead of leaving a hybrid custom state. The menu presents three clear
routes after the preset and quality selectors:

- **Core VHS Look** contains the controls most people adjust while matching a
  tape: format, generation loss, wear, scanlines, noise, chroma bleed,
  instability, motion trail, lens shape, aspect, and vignette.
- **Atmosphere** contains the liminal palette and the primary scene-depth fog
  controls.
- **Advanced Settings** opens focused Signal & Decoder, Tape Transport &
  Damage, Camera & Exposure, Image Fine Tuning, Temporal Processing, Advanced
  Atmosphere, and Overlays groups.

Every existing option still appears exactly once. Several overlapping controls
also have narrower meanings: **Chroma Amount** no longer raises **Chroma
Bleed**, **Motion Smear** no longer changes spatial echo distance, **Glitch
Frequency** no longer controls tape-dropout probability, and tape wear no
longer changes the virtual transport speed. Effects that previously appeared in
both recording and playback are now applied once at the appropriate stage.

The VCR OSD is disabled by default but remains available as an option. **Rounded
Overscan** now controls only the curved black mask; disabling it keeps lens
distortion and 4:3 cropping while producing a genuinely rectangular picture.
**Luma Edge Ringing** controls the bright/dark horizontal outlines created by a
cheap deck's sharpening circuit.

The **Atmosphere** and **Advanced Settings > Advanced Atmosphere** groups contain
five controls shared by the three space-specific looks:

- **Liminal Color Space** chooses Off, Backrooms, Poolrooms, or Liminal Night.
- **Fluorescent Flicker** combines a rolling mains band, irregular ballast
  flutter, and occasional soft brownouts.
- **White-Balance Drift** makes the camcorder slowly hunt between warm and cool
  responses under artificial light.
- **Exposure Hunting** adds slow gain breathing in empty bright and dark rooms.
- **Liminal Haze** adds veiling glare around artificial highlights without
  pretending to inject world-space fog.

The same atmosphere groups add actual scene-depth fog independently of the
highlight haze:

- **Fog Palette** selects Off, Neutral Tape Fog, Backrooms Yellow, Poolrooms
  Cyan, or Liminal Night Green.
- **Fog Density**, **Fog Start Distance**, and **Fog Falloff Distance** control
  the extinction curve in world blocks.
- **Fog Variation** adds slow world-anchored density changes that do not swim
  with the screen when the camera turns.
- The fog is applied before YIQ conversion and the first tape generation, so
  composite leakage, chroma loss, interlacing, and ghosting affect it naturally.
- Depth-disagreeing foreground geometry uses a clear fallback for compatibility
  with first-person hands, translucent surfaces, and older Iris releases.

The **Signal & Decoder**, **Tape Transport & Damage**, **Camera & Exposure**,
and **Temporal Processing** groups separate signal, mechanical, optical, and
history behavior. Each effect has an on/off switch and/or its own intensity or
frequency control:

- **Signal-Accurate YIQ** converts RGB into separate Y brightness and I/Q color
  components in the recorded signal. I keeps slightly more detail than Q; both
  smear asymmetrically, receive signal-space noise, and accumulate genuine
  color-phase error. **Chroma Phase Wobble** controls that hue instability.

- **Automatic Exposure Pump** stores a persistent gain value. It attacks bright
  overloads quickly and recovers more slowly after the camera enters darkness,
  instead of deriving exposure indirectly from the previous image color.
- **Tracking Color Killer** temporarily removes chroma during strong tracking
  displacement or sync loss, like a VCR protecting an unstable color signal.
- **Vertical Sync Failure** generates rare full-frame rolls or short held-field
  events. The frequency defaults are intentionally low.
- **Separate Chroma Persistence** keeps only the previous frame's color trail,
  so saturation lingers longer than luminance on moving objects.
- **Motion-Aware History** reconstructs the current position from depth and
  previous camera matrices, then compares it with persistent view-depth
  metadata. Off-screen motion, camera jumps, depth mismatches, and newly
  revealed surfaces reject stale history; sky keeps a conservative fallback.

The Subtle preset disables the aggressive signal switches. Other presets enable
them at different strengths, and every switch can be changed independently.

The **Signal & Decoder** group models one physical separation of brightness and
color in the playback composite-video circuit:

- **Consumer Notch** uses a five-tap horizontal filter at Balanced and
  Cinematic quality. Synchronous chroma demodulation produces visible dot crawl,
  cross-color rainbows from fine luminance texture, and cross-luma carrier
  leakage on saturated edges. Performance uses a lighter two-channel
  approximation.
- **Two-Line Comb** uses the full ten samples in Cinematic NTSC quality to
  compare adjacent raster lines, suppressing leakage on correlated detail while
  preserving errors around motion and diagonals. PAL falls back to the notch
  circuit because its alternating chroma phase is not a simple line inverse.
- **Bypass** removes these decoder-specific artifacts without disabling the
  broader YIQ tape-bandwidth model.

**Core VHS Look** separates cassette format from copy history, while **Tape
Transport & Damage** contains the physical wear and failure controls.
VHS SP, LP, SLP, VHS-C, and Worn Rental modes have distinct luma resolution,
chroma retention, and noise floors. Up to five analog copy generations compound
color loss, cross-color contamination, luma stepping, and fading. Persistent
tape defects use a longitudinal virtual tape coordinate, so the same damaged
helical track keeps its shape while it travels through several fields.

**Camera & Exposure** selects neutral, 1980s tube, 1990s VHS, or early-digital
camera response. The optional recorded HUD in **Overlays** draws a blinking REC
lamp, battery, and running MM:SS timecode. Digital zoom enlarges the image before
playback displacement, while autofocus hunting broadens the later luma/chroma
sampling radius.

**Tape Transport & Damage** also adds a manual tracking bias, diagonal RF
herringbone, rolling interference bands, rare broad tape-chew warping, and
recursive previous-frame repetition. Head-switch displacement, chroma loss,
and RF noise now share one field-locked event instead of drifting independently.
These controls default to off or zero outside their dedicated presets.

Every parameter is also defined near the top of
`shaders/lib/settings.glsl`. Edit that file if you prefer direct control. All
amounts documented as pixels are resolution-independent screen-pixel offsets.
Pixel-scale effects automatically compensate for Retina/high-DPI framebuffers,
so scanlines, grain, RGB separation, and virtual pixels remain visible on macOS.

## Pass layout

- `composite`: applies recording-side time-base/tracking errors, scene-depth
  fog, persistent automatic gain, first-stage YIQ bandwidth/phase loss,
  depth-reprojected temporal history, sync/chroma recovery, and interlaced field
  hold. It writes the recorded-signal image plus persistent view-depth and gain
  metadata.
- `composite1`: copies the encoded image into persistent `colortex4` for the
  following frame's genuine moving-image ghost trail.
- `final`: handles framing, zoom, wobble, playback transport, lens/focus
  sampling, the single physical composite decoder, tape format/generation wear,
  camera/liminal response, persistent oxide defects, RF noise, field-locked head
  switching, scan fields, grain, and optional overlays.

Version 1.9 keeps the stable GLSL 1.20 and composite-buffer interfaces shared by
the targeted Iris releases from Minecraft 1.18.2 through 26.2. It uses one
persistent RGBA image-history buffer plus a compact persistent RG16F metadata
buffer for view depth and automatic gain. The actual game and output resolution
are never reduced. Primary and extended targets share this path, but not every
loader, GPU, and driver combination has been live-tested.

## Version 1.9 — Signal Physics

- Added persistent view-depth metadata and disocclusion rejection to
  camera-matrix motion history. Depth mismatches, off-screen reprojection, large
  camera jumps, and newly revealed surfaces no longer inherit unrelated trails.
- Added persistent automatic gain with fast attack against bright overloads and
  slower recovery in darkness.
- Consolidated brightness/color separation into one playback decoder.
  Performance uses a lightweight approximation; Balanced and Cinematic
  Consumer Notch use five horizontal taps; the Cinematic NTSC Two-Line Comb path
  uses ten samples across two signal lines, while PAL uses a safe notch fallback.
- Unified head-switch displacement, chroma attenuation, and RF noise behind one
  field-locked event.
- Removed effects that were being applied once while recording and again during
  playback, and clarified the remaining overlapping controls.
- Reorganized all existing options into **Core VHS Look**, **Atmosphere**, and
  **Advanced Settings**, with focused subgroups under Advanced.
- Made all thirteen profiles reset every preset-controlled option, fixing stale
  fog and stronger decoder/defect values carrying into the next preset after
  leaving **Analog Fog**.
- Extended the release builder to require all 77 public options exactly once in
  the menu and all 75 preset-owned options in every resolved profile. Render
  quality and NTSC/PAL intentionally remain global.
- Retained the Minecraft 1.18.2–26.2 compatibility target without claiming live
  verification for every listed loader/GPU/driver combination.

## Version 1.8 — Analog Fog

- Added scene-depth atmospheric fog before the first tape encode.
- Added neutral, Backrooms, Poolrooms, and Liminal Night fog palettes plus
  density, start-distance, falloff-distance, and world-stable variation controls.
- Protected first-person and depth-disagreeing translucent geometry with a
  conservative clear fallback.
- Added the **Analog Fog** preset and tuned depth fog into the three liminal
  presets.
- Extended the compatibility target with Minecraft 1.18.2, 1.19.4, 1.20.4,
  1.20.6, 1.21.5, 1.21.8, and 1.21.10.

## Version 1.7 — Composite Decode

- Added depth- and camera-matrix-based reprojection for the processed history
  buffer, with conservative sky, invalid-depth, and off-screen fallbacks.
- Added selectable bypass, consumer notch, and two-line comb decoder circuits.
- Added signal-domain dot crawl, false cross-color rainbows, and cross-luma
  carrier leakage in both the recording and playback generations.
- Added persistent oxide holes and damaged helical tracks tied to a continuously
  moving virtual tape coordinate.
- Added the **Composite Decode** preset and complete English/Russian controls.
- Kept GLSL 1.20, OpenGL, and the Minecraft 1.20.1 through 26.2 compatibility
  target established by v1.6.1.

## Version 1.6.1 — Minecraft 26.2 Framebuffer Fix

- Added explicit lightweight `gbuffers_basic`, `gbuffers_textured`, and
  `gbuffers_textured_lit` programs so Iris 1.11.2 always captures the real world
  into `colortex0` before VHS post-processing.
- Fixed the blue/white corrupted frame seen when the old composite-only pack was
  enabled on Minecraft 26.2.
- Made all temporal buffer flips explicit to prevent Iris-version-dependent
  read/write swaps.
- Preserved the complete v1.6 VHS pipeline, presets, and support for Minecraft
  1.20.1 through 26.2.

## Version 1.6 — Broken Signal

- Added manual VCR tracking control with positional and displacement bias.
- Added resolution-stable RF herringbone and rolling bright interference bands.
- Added rare correlated tape-chew events that buckle groups of scan lines and
  concentrate static inside the damaged region.
- Added real repeated-frame stalls using the persistent processed-frame buffer.
- Added the severe **Broken Signal** preset.

## Version 1.5 — Camcorder

- Added neutral, 1980s tube, 1990s VHS, and early-digital camera responses.
- Added a generated recorded HUD with blinking REC, battery, and MM:SS timecode.
- Added centered consumer digital zoom and slow correlated autofocus hunting.
- Added the **Camcorder 1996** preset.

## Version 1.4 — Tape Generation

- Added VHS SP, VHS LP, VHS SLP, VHS-C, and Worn Rental cassette models.
- Added zero through five copy generations with compounding chroma loss,
  cross-color contamination, luma stepping, fading, and noise.
- Added adjustable oxide wear and the **Rental Tape** preset.

## Version 1.3 — Liminal Signal

- Added a dedicated Liminal Lighting settings page.
- Rebuilt Backrooms around yellow-green fluorescent spectra, irregular ballast
  flutter, slow white-balance drift, and exposure hunting.
- Added the cyan, humid **Poolrooms** preset.
- Added the underexposed blue-green **Liminal Night** preset.
- Added adjustable fluorescent flicker, white-balance drift, gain hunting, and
  veiling glare.
- Kept all liminal processing in the universal post-processing pipeline, so no
  map-specific or dimension-specific shader files are required.

## Version 1.2

- Added Performance, Balanced, and Cinematic render-quality modes.
- Performance mode removes optional texture taps and uses inexpensive
  two-sample exposure metering.
- Separated temporal ghosting from the optional spatial tape echo.
- Added history stabilization for cleaner fast camera turns.
- Added selectable NTSC and PAL line, field-rate, and chroma-phase behavior.
- Added true interlaced field weaving through the persistent history buffer.
- Replaced block-shaped glitches with correlated mechanical time-base error and
  soft multi-track tracking tears.
- Locked tape noise and jitter to the selected analog field rate instead of the
  game's rendering frame rate.
- Added a complete Russian settings translation.
- Added universal compatibility targets for Minecraft 26.2, 26.1.2, 1.21.11,
  1.21.4, 1.21.1, and 1.20.1.

## Version 1.1

- Added Minecraft Java Edition 26.2 and Iris 1.11.2 compatibility metadata.
- Documented the required OpenGL graphics backend for Minecraft 26.2.
- Kept the stable GLSL 1.20 pipeline in the traditional OptiFine shader-pack
  layout. Current live verification is Iris-only.
- Retained Minecraft 1.21.4 support and all existing presets.

## Design references

- [Libretro slang-shaders: VHS](https://github.com/libretro/slang-shaders/tree/master/vhs)
  for practical open-source YIQ, luma, chroma, tape-noise, and feedback models.
- [vhs-decode documentation](https://github.com/oyvindln/vhs-decode/wiki)
  for real tape signal behavior: time-base correction, luminance/chrominance
  separation, interlaced capture, dropouts, and the bottom head-switching area.
- [Iris shader-pack documentation](https://shaders.properties/current/)
  for composite render targets, buffer flipping, and persistent history data.
