<div align="center">

<img src="media/hero.png" alt="Lost Signal VHS shader in Minecraft" width="100%">

# LOST SIGNAL VHS

### Minecraft, recorded on a tape that should have stayed lost.

Lightweight analog-horror post-processing for Minecraft Java Edition.<br>
Scanlines, tape grain, tracking tears, color bleed, temporal ghosting, lens
distortion, sync failures, and a proper signal-space YIQ pipeline.

<p>
  <a href="https://modrinth.com/shader/lost-signal-vhs">
    <img src="https://img.shields.io/badge/Download-Modrinth-00AF5C?style=for-the-badge&logo=modrinth&logoColor=white" alt="Download on Modrinth">
  </a>
  <a href="https://www.curseforge.com/minecraft/shaders/lost-signal-vhs">
    <img src="https://img.shields.io/badge/Download-CurseForge-F16436?style=for-the-badge&logo=curseforge&logoColor=white" alt="Download on CurseForge">
  </a>
</p>

![Minecraft 26.2](https://img.shields.io/badge/Minecraft-26.2-62B47A?style=flat-square)
![Minecraft 1.21.4](https://img.shields.io/badge/Minecraft-1.21.4-62B47A?style=flat-square)
![Iris 1.11.2](https://img.shields.io/badge/Iris-1.11.2-5C6BC0?style=flat-square)
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
- Delayed automatic exposure, sync failures, and tracking color loss
- Six presets plus individual controls for every major effect
- Overworld, Nether, and End support without dimension-specific shaders

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

## Compatibility

| Minecraft | Shader loader | Graphics backend | Status |
|---|---|---|---|
| Java Edition 26.2 | Iris 1.11.2 with Sodium | OpenGL | Supported |
| Java Edition 1.21.4 | Iris 1.8.8 with Sodium | OpenGL | Supported |
| Compatible versions | OptiFine | OpenGL | Supported |

> [!IMPORTANT]
> Iris is not compatible with Minecraft 26.2's Vulkan backend. Keep
> **Graphics API** on **Default (OpenGL in 26.2)** or choose
> **Prefer OpenGL**, then restart the game.

## Quick installation

1. Download [`Lost_Signal_VHS_v1.1_MC26.2.zip`](Lost_Signal_VHS_v1.1_MC26.2.zip).
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
| **Backrooms** | Soft analog horror with fluorescent halation |
| **Subtle** | Restrained camcorder treatment |
| **Found Footage** | Analog-horror balance without the VCR overlay |
| **Damaged Tape** | Aggressive tears, static, separation, and ghosting |

Every preset is only a starting point. Open **Shader Pack Settings** to tune
the tape, camera, signal, format, and color groups independently.

## Repository layout

- [`Lost_Signal_VHS/`](Lost_Signal_VHS/) — editable shader-pack source
- [`Lost_Signal_VHS/shaders/lib/settings.glsl`](Lost_Signal_VHS/shaders/lib/settings.glsl) — direct effect controls
- [`Lost_Signal_VHS/README.md`](Lost_Signal_VHS/README.md) — technical notes and testing checklist
- [`Lost_Signal_VHS_v1.1_MC26.2.zip`](Lost_Signal_VHS_v1.1_MC26.2.zip) — ready-to-install release

## License

Lost Signal VHS is released under the [MIT License](Lost_Signal_VHS/LICENSE.txt).

<div align="center">
  <sub>NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.</sub>
</div>
