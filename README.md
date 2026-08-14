<div align="center">

<img src="media/hero.png" alt="Lost Signal VHS shader in Minecraft" width="100%">

# LOST SIGNAL VHS

### Minecraft, recorded on a tape that should have stayed lost.

Lightweight analog-horror post-processing for Minecraft Java Edition.<br>
Scanlines, tape grain, tracking tears, color bleed, temporal ghosting, lens
distortion, sync failures, a proper signal-space YIQ pipeline, and dedicated
Backrooms, Poolrooms, and Liminal Night lighting. Version 1.8 adds depth-based
analog fog that enters the signal before tape encoding, a dedicated fog preset,
and an extended Minecraft 1.18.2–26.2 compatibility target.

<p>
  <a href="https://modrinth.com/shader/lost-signal-vhs">
    <img src="https://img.shields.io/badge/Download-Modrinth-00AF5C?style=for-the-badge&logo=modrinth&logoColor=white" alt="Download on Modrinth">
  </a>
  <a href="https://www.curseforge.com/minecraft/shaders/lost-signal-vhs">
    <img src="https://img.shields.io/badge/Download-CurseForge-F16436?style=for-the-badge&logo=curseforge&logoColor=white" alt="Download on CurseForge">
  </a>
</p>

![Minecraft 1.18.2–26.2](https://img.shields.io/badge/Minecraft-1.18.2%E2%80%9326.2-62B47A?style=flat-square)
![Iris](https://img.shields.io/badge/Iris-1.6.11%2B-5C6BC0?style=flat-square)
![OptiFine compatible](https://img.shields.io/badge/OptiFine-Compatible-EF6C00?style=flat-square)
![MIT License](https://img.shields.io/badge/License-MIT-E7B416?style=flat-square)

</div>

## The signal

Lost Signal VHS leaves Minecraft's normal lighting intact and transforms the
finished frame into unstable found footage. Its three-pass pipeline recreates
the behavior of a cheap camera, worn tape, and a failing VCR instead of simply
placing a noise texture over the screen.

- Real horizontal scanlines, grain, flicker, and static bursts
- Tracking tears, head-switch noise, frame jitter, and curved overscan
- Chroma bleed, RGB separation, phase wobble, and YIQ color processing
- Persistent temporal ghosting using the previous processed frame
- Depth-based motion-aware history that follows stable world geometry
- Consumer notch and two-line comb decoder models
- Dot crawl, cross-color rainbows, and cross-luma carrier leakage
- Persistent oxide defects tied to a continuously moving virtual tape
- Depth-based fog recorded before YIQ/tape degradation, with world-stable variation
- True NTSC/PAL field weaving through the persistent history buffer
- Smooth mechanically correlated time-base error and feathered tracking tears
- Performance, Balanced, and Cinematic render-quality modes
- Selectable NTSC and PAL signal timing
- Delayed automatic exposure, sync failures, and tracking color loss
- Thirteen presets plus individual controls for every major effect
- Overworld, Nether, and End support without dimension-specific shaders
- English and Russian settings menus

## Gallery

<table>
  <tr>
    <td width="50%">
      <img src="media/backrooms.png" alt="Warm Backrooms-style corridor with VHS processing">
    </td>
    <td width="50%">
      <img src="media/interior.png" alt="Bright Minecraft interior distorted by VHS tracking">
    </td>
  </tr>
  <tr>
    <td align="center"><sub>Backrooms preset</sub></td>
    <td align="center"><sub>Tracking distortion and color bleed</sub></td>
  </tr>
</table>

## Backrooms and analog horror

Lost Signal VHS is designed for **Backrooms maps, liminal spaces, horror
modpacks, ARGs, machinima, and found-footage videos**. The dedicated
**Backrooms preset** emphasizes sickly fluorescent color, unstable exposure,
deep tape noise, tracking loss, and damaged-camcorder movement while keeping
the scene playable.

[![Watch the Minecraft Backrooms VHS Shader trailer](https://img.youtube.com/vi/MWtnxr5Iu6Q/maxresdefault.jpg)](https://youtu.be/MWtnxr5Iu6Q)

**[Watch the 53-second Backrooms VHS trailer on YouTube](https://youtu.be/MWtnxr5Iu6Q)**

## Compatibility

| Minecraft | Recommended Iris line | Graphics backend | Status |
|---|---|---|---|
| Java Edition 26.2 | Iris 1.11.2 with Sodium | OpenGL | Supported |
| Java Edition 26.1.2 | Iris 1.11.2 with Sodium | OpenGL | Supported |
| Java Edition 1.21.11 | Iris 1.10.7 with Sodium | OpenGL | Supported |
| Java Edition 1.21.10 | Iris 1.9.7 with Sodium | OpenGL | Extended |
| Java Edition 1.21.8 | Iris 1.9.5 with Sodium | OpenGL | Extended |
| Java Edition 1.21.5 | Iris 1.8.11 with Sodium | OpenGL | Extended |
| Java Edition 1.21.4 | Iris 1.8.8 with Sodium | OpenGL | Supported |
| Java Edition 1.21.1 | Iris 1.8.12 with Sodium | OpenGL | Supported |
| Java Edition 1.20.6 | Iris 1.7.0 with Sodium | OpenGL | Extended |
| Java Edition 1.20.4 | Iris 1.7.2 with Sodium | OpenGL | Extended |
| Java Edition 1.20.1 | Iris 1.7.6 with Sodium | OpenGL | Supported |
| Java Edition 1.19.4 | Iris 1.6.11 with Sodium | OpenGL | Extended |
| Java Edition 1.18.2 | Iris 1.6.11 with Sodium | OpenGL | Extended |

**Supported** rows are the established primary targets. **Extended** rows use
the same GLSL 1.20, depth-buffer, and composite interfaces and are included in
the v1.8 compatibility target; live verification on every loader/driver pair is
still recommended.

> [!IMPORTANT]
> Version 1.6.1 or newer is required on Minecraft 26.2. Iris is not compatible
> with Minecraft 26.2's Vulkan backend. Keep
> **Graphics API** on **Default (OpenGL in 26.2)** or choose
> **Prefer OpenGL**, then restart the game.

## Quick installation

1. Download [`Lost_Signal_VHS_v1.8_Analog_Fog.zip`](Lost_Signal_VHS_v1.8_Analog_Fog.zip).
2. Put the ZIP into Minecraft's `shaderpacks` directory.
3. Start Minecraft with Iris.
4. Open **Options → Video Settings → Shader Packs**.
5. Select **Lost Signal VHS**, apply it, and choose a preset.

Typical shader-pack directories:

- Windows: `%APPDATA%\.minecraft\shaderpacks`
- macOS: `~/Library/Application Support/minecraft/shaderpacks`
- Linux: `~/.minecraft/shaderpacks`

No resource pack, external texture, or compute-shader support is required.

## Presets

| Preset | Look |
|---|---|
| **Reference VHS** | Saturated green chroma, ringing, halation, and crushed shadows |
| **Real VHS** | Heavy consumer-tape look with temporal trails and head-switch noise |
| **Backrooms** | Yellow-green fluorescent hum, depth fog, white-balance drift, and exposure hunting |
| **Poolrooms** | Cyan reflected light, humid depth fog, and restrained tape damage |
| **Liminal Night** | Underexposed blue-green corridors with dense unstable air |
| **Subtle** | Restrained camcorder treatment |
| **Found Footage** | Analog-horror balance without the VCR overlay |
| **Damaged Tape** | Aggressive tears, static, separation, and ghosting |
| **Rental Tape** | Four analog copies, oxide wear, fading, and weak RF ingress |
| **Camcorder 1996** | VHS-C color response with REC, battery, timecode, zoom, and autofocus hunting |
| **Broken Signal** | Severe mistracking, RF herringbone, chewed tape, and repeated frames |
| **Composite Decode** | Consumer composite leakage, crawling edge dots, false color, and persistent oxide defects |
| **Analog Fog** | Neutral depth fog recorded through the complete composite/VHS pipeline |

Every preset is only a starting point. Open **Shader Pack Settings** to tune
the tape, camera, signal, format, and color groups independently.

## Liminal Signal lighting

- **Fluorescent Flicker** combines a rolling mains band, irregular ballast
  flutter, and soft brownouts instead of using one clean brightness sine wave.
- **White-Balance Drift** makes a cheap camcorder hunt between warm and cool
  responses under artificial light.
- **Exposure Hunting** adds slow gain breathing that becomes most visible in
  empty dark spaces.
- **Liminal Haze** adds veiling glare around artificial highlights without
  pretending to add world-space fog.
- **Liminal Color Space** can be set to Off, Backrooms, Poolrooms, or Liminal
  Night independently of the preset.

## Atmospheric fog

- **Fog Palette** selects neutral tape fog, Backrooms yellow, Poolrooms cyan,
  Liminal Night green, or disables the effect.
- **Fog Density**, **Start Distance**, and **Falloff Distance** control the
  depth response in world blocks.
- **Fog Variation** adds slow world-anchored density changes without a texture
  or a screen-space pattern that swims when the camera turns.
- Fog is inserted before YIQ encoding, composite-decoder leakage, temporal
  history, and tape wear, so it inherits color bleed and genuine VHS ghosting.
- The first-person hand and depth-disagreeing translucent geometry use a clear
  compatibility fallback instead of receiving unstable foreground fog.

## Tape generation, camcorder, and broken signal

- **Tape Format** switches between VHS SP, LP, SLP, VHS-C, and a worn rental
  cassette, each with its own effective luma and chroma bandwidth.
- **Copy Generation** compounds chroma loss, cross-color error, quantization,
  fading, and noise through as many as five analog copies.
- **Camera Era** selects 1980s tube, 1990s VHS, early-digital, or neutral color
  response. The optional recorded HUD adds REC, battery, and MM:SS timecode.
- **Digital Zoom** and **Autofocus Hunting** recreate consumer camcorder optics
  before the signal enters the virtual tape deck.
- **Broken Signal** controls manual tracking, RF herringbone, rolling
  interference bands, buckled tape, and history-buffer frame repetition.

## Quality and signal modes

- **Performance** reuses existing luma/chroma taps, reduces auto-exposure
  metering from ten samples to two, and skips the optional spatial echo.
- **Balanced** reuses the outer second-generation taps while preserving the
  intended reference look; it is the default.
- **Cinematic** keeps the complete multi-radius filter path for high-end GPUs.
- **NTSC** uses 480-line, 59.94-field timing and stronger directional hue drift.
- **PAL** uses 576-line, 50-field timing with alternating chroma phase.
- **Interlaced Field Weave** refreshes one raster-line parity per field and
  retains the other parity from history, creating real motion combing.

## Version 1.8 — Analog Fog

- Added true scene-depth fog with five selectable palettes and adjustable
  density, start distance, falloff distance, and world-stable variation.
- Integrated fog before the first tape generation instead of adding a clean
  digital overlay after VHS processing.
- Updated Backrooms, Poolrooms, and Liminal Night and added the **Analog Fog**
  preset.
- Extended the compatibility target to Minecraft 1.18.2, 1.19.4, 1.20.4,
  1.20.6, 1.21.5, 1.21.8, and 1.21.10 alongside the existing primary versions.

## Version 1.7 — Composite Decode

- **Motion-Aware History** reconstructs the current world position from depth,
  projects it through the previous camera, and falls back to screen-space
  history for sky, invalid depth, and off-screen motion.
- **Consumer Notch** deliberately leaks fine luminance into chroma and chroma
  back into luminance, producing dot crawl, false rainbow color, and hanging
  dots instead of a generic RGB glitch.
- **Two-Line Comb** compares adjacent raster lines and suppresses most leakage
  on correlated detail while retaining artifacts around motion and diagonals.
- **Persistent Tape Defects** move through the frame on a virtual longitudinal
  tape coordinate, so damaged helical tracks keep their shape across fields.

## Repository layout

- [`Lost_Signal_VHS/`](Lost_Signal_VHS/) — editable shader-pack source
- [`Lost_Signal_VHS/shaders/lib/settings.glsl`](Lost_Signal_VHS/shaders/lib/settings.glsl) — direct effect controls
- [`Lost_Signal_VHS/README.md`](Lost_Signal_VHS/README.md) — technical notes and testing checklist
- [`Lost_Signal_VHS_v1.8_Analog_Fog.zip`](Lost_Signal_VHS_v1.8_Analog_Fog.zip) — ready-to-install universal release

## License

Lost Signal VHS is released under the [MIT License](Lost_Signal_VHS/LICENSE.txt).

<div align="center">
  <sub>NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.</sub>
</div>
