# Lost Signal VHS

An Iris shader pack for Minecraft Java Edition that turns the vanilla scene into
cheap, unstable found footage: scanlines, tape grain, tracking tears, color
bleeding, camcorder lens distortion, flicker, temporal ghosting, frame jitter,
and a yellow-green security-camera grade.

The pack is deliberately a post-processing pack. It keeps Minecraft's normal
lighting and applies the VHS treatment after the world is rendered, so it is
lightweight and works in the Overworld, Nether, and End without dimension-
specific shader files.

## Requirements

- Minecraft Java Edition
- Iris Shaders (normally installed together with Sodium)
- OpenGL 2.1-class shader support or newer

No resource pack, noise texture, or compute-shader support is required.

## Installation

1. Copy the `Lost_Signal_VHS` folder, or its ZIP file, into Minecraft's
   `shaderpacks` directory.
2. Start Minecraft with Iris.
3. Open **Options > Video Settings > Shader Packs**.
4. Select **Lost Signal VHS** and apply it.
5. Open **Shader Pack Settings** to choose a preset or tune individual effects.

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
5. Resize the window or reload the pack. Iris recreates the history buffer, so
   temporal ghosting can take two frames to initialize.

For shader compile diagnostics, open the Iris shader selection screen and press
`Ctrl+D` on Windows/Linux or `Cmd+D` on macOS to toggle Iris debug mode.

## Tuning

The settings menu provides three presets:

- **Subtle**: a restrained consumer-camcorder look.
- **Found Footage**: the intended analog-horror balance.
- **Damaged Tape**: stronger tears, static, color separation, and ghosting.

Every parameter is also defined near the top of
`shaders/lib/settings.glsl`. Edit that file if you prefer direct control. All
amounts documented as pixels are resolution-independent screen-pixel offsets.

## Pass layout

- `composite`: samples the Minecraft scene and the previous processed frame,
  then writes the VHS result to `colortex0`.
- `composite1`: copies that result into persistent `colortex4` for use on the
  next frame.
- `final`: copies `colortex0` to the screen.

This design uses only a handful of full-resolution texture samples per pixel and
one RGBA history buffer. The low-resolution feeling comes from UV quantization;
the actual game and output resolution are never reduced.

