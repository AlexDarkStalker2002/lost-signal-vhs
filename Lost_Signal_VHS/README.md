# Lost Signal VHS

An Iris shader pack for Minecraft Java Edition that turns the vanilla scene into
cheap, unstable found footage: scanlines, tape grain, tracking tears, color
bleeding, camcorder lens distortion, flicker, temporal ghosting, frame jitter,
and a yellow-green security-camera grade. Its optional signal-accurate YIQ path
processes brightness and analog color independently instead of applying a
generic RGB blur.

The pack is deliberately a post-processing pack. It keeps Minecraft's normal
lighting and applies the VHS treatment after the world is rendered, so it is
lightweight and works in the Overworld, Nether, and End without dimension-
specific shader files.

## Requirements

- Minecraft Java Edition 26.2 or 26.1.2 with Iris 1.11.2 and Sodium
- Minecraft Java Edition 1.21.11 with Iris 1.10.7 and Sodium
- Minecraft Java Edition 1.21.4 with Iris 1.8.8 and Sodium
- Minecraft Java Edition 1.21.1 with Iris 1.8.12 and Sodium
- Minecraft Java Edition 1.20.1 with Iris 1.7.6 and Sodium
- The OpenGL graphics backend

No resource pack, noise texture, or compute-shader support is required.

Minecraft 26.2 introduced an experimental Vulkan backend, but Iris is not
compatible with Vulkan. Leave **Graphics API** on **Default** (OpenGL in the
26.2 release) or select **Prefer OpenGL** before starting the game with Iris.

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

- Windows: `%APPDATA%\\.minecraft\\shaderpacks`
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
5. Move between a bright exterior and dark corridor to test delayed automatic
   exposure. Higher Sync Failure Frequency values make rolls and held fields
   easier to verify without waiting for the deliberately rare default event.
6. Resize the window or reload the pack. Iris recreates the history buffer, so
   temporal ghosting can take two frames to initialize.
7. For an A/B check, use Iris's shader toggle while looking at a textured wall.
   The VHS version should remain readable; only color should bleed broadly.
8. In **Signal Instability**, compare **Signal-Accurate YIQ** on and off while
   looking at a sharp red or blue edge. YIQ mode should keep the brightness edge
   legible while its color trails horizontally and wobbles slightly between lines.

For shader compile diagnostics, open the Iris shader selection screen and press
`Ctrl+D` on Windows/Linux or `Cmd+D` on macOS to toggle Iris debug mode.

## Tuning

The settings menu provides six presets:

- **Reference VHS**: matches the supplied real-tape screenshots: saturated green
  chroma, edge ringing, crushed shadows, bright halation, and no text overlay.
- **Real VHS**: the default heavy 4:3 deck look with color bleed, crushed blacks,
  temporal trails, and head-switch noise.
- **Backrooms**: soft 4:3 analog-horror footage with fluorescent halation,
  muted color, restrained tracking noise, and no playback OSD.
- **Subtle**: a restrained consumer-camcorder look.
- **Found Footage**: the analog-horror balance without the deck OSD.
- **Damaged Tape**: stronger tears, static, color separation, and ghosting.

The VCR OSD is disabled by default but remains available as an option. **Rounded
Overscan** now controls only the curved black mask; disabling it keeps lens
distortion and 4:3 cropping while producing a genuinely rectangular picture.
**Luma Edge Ringing** controls the bright/dark horizontal outlines created by a
cheap deck's sharpening circuit.

The **Signal Instability** page contains five fully independent effects. Each
has an on/off switch and/or its own intensity or frequency control:

- **Signal-Accurate YIQ** converts RGB into separate Y brightness and I/Q color
  components in both tape generations. I keeps slightly more detail than Q;
  both smear asymmetrically, receive signal-space noise, and accumulate genuine
  color-phase error. **Chroma Phase Wobble** controls that hue instability.

- **Automatic Exposure Pump** meters five broad areas of the scene and reacts
  through the previous processed frame, producing delayed gain changes in dark
  and bright rooms.
- **Tracking Color Killer** temporarily removes chroma during strong tracking
  displacement or sync loss, like a VCR protecting an unstable color signal.
- **Vertical Sync Failure** generates rare full-frame rolls or short held-field
  events. The frequency defaults are intentionally low.
- **Separate Chroma Persistence** keeps only the previous frame's color trail,
  so saturation lingers longer than luminance on moving objects.

The Subtle preset disables all five switches. Other presets enable them at
different strengths, and every switch can be changed independently afterward.

Every parameter is also defined near the top of
`shaders/lib/settings.glsl`. Edit that file if you prefer direct control. All
amounts documented as pixels are resolution-independent screen-pixel offsets.
Pixel-scale effects automatically compensate for Retina/high-DPI framebuffers,
so scanlines, grain, RGB separation, and virtual pixels remain visible on macOS.

## Pass layout

- `composite`: applies the first tape encode, camera drift, optional YIQ
  bandwidth loss and phase error, tracking damage, automatic gain pumping,
  sync failure, chroma loss, and separate luma/chroma temporal persistence.
- `composite1`: copies the encoded image into persistent `colortex4` for the
  following frame's genuine moving-image ghost trail.
- `final`: adds the second-generation VCR/CRT treatment, 4:3 overscan, explicit
  low-bandwidth I/Q reconstruction, RF static, dropouts, head-switch tearing,
  alternating scan fields, grain, and the optional VCR OSD.

This is intentionally the original multi-pass look. Version 1.2 uses the stable
GLSL 1.20 and composite-buffer interfaces shared by supported Iris releases from
Minecraft 1.20.1 through 26.2. It uses one persistent RGBA history buffer plus a
second playback-generation pass. The actual game and output resolution are
never reduced.

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
- Kept the stable GLSL 1.20 composite pipeline for Iris and OptiFine shader-pack
  compatibility.
- Retained Minecraft 1.21.4 support and all existing presets.

## Design references

- [Libretro slang-shaders: VHS](https://github.com/libretro/slang-shaders/tree/master/vhs)
  for practical open-source YIQ, luma, chroma, tape-noise, and feedback models.
- [vhs-decode documentation](https://github.com/oyvindln/vhs-decode/wiki)
  for real tape signal behavior: time-base correction, luminance/chrominance
  separation, interlaced capture, dropouts, and the bottom head-switching area.
- [Iris shader-pack documentation](https://shaders.properties/current/)
  for composite render targets, buffer flipping, and persistent history data.
