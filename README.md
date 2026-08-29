# WWF WrestleFest for MiSTer FPGA

Work-in-progress FPGA core for the arcade hardware used by **WWF WrestleFest**
(Technos Japan, 1991), targeting **MiSTer FPGA**.
## Download current test build

**[⬇️ Download GFXFIX7-SYNC-A-B](https://github.com/Misterlaleche/WWF-WrestleFest-MiSTer/releases/tag/GFXFIX7-SYNC-A-B)**

This is the current public pre-release for hardware testing. The download includes
the compiled MiSTer core and matching MRA, but no game ROMs.
> [!IMPORTANT]
> **No game ROMs are included or distributed by this project.** The source,
> build artifacts and releases contain no copyrighted game data. Users must
> supply their own legally obtained compatible ROM dump.

## Reference build

The current public reference is **GFXFIX7-SYNC-A-B**. It keeps the stable
GFXFIX6 graphics path and does **not** include the experimental GFXFIX5 sprite
pipeline.

This diagnostic build adds one OSD option:

| `CRT Sync` mode | Behaviour |
|---|---|
| `JTFRAME` | Normal MiSTer route through `jtframe_resync`; CRT H/V offset controls remain active. |
| `RAW Core` | Bypasses `jtframe_resync` and forwards the core's HS/VS timing; CRT H/V offsets deliberately do not act. |

Switching modes does not change the core resolution, pixel clock, blanking,
CPU clocks, IRQ timing or game speed. Its purpose is to compare the physical
north-to-south image height on a CRT without changing display controls.

## Development status

This is an experimental test core, not a finished or cycle-accurate release.

| Area | Current status |
|---|---|
| Main CPU, memory map and interrupts | Implemented |
| Tilemaps, text, sprites and palette | Implemented; simulation validated |
| Four-player digital controls | Implemented |
| Original arcade DIP switches | Defined in the MRA |
| YM2151 + MSM6295 audio | Implemented; real-hardware listening tests pending |
| HDMI output | Hardware testing in progress |
| Analogue 15 kHz output | GFXFIX7 A/B hardware test required |
| Cheats / save states | Not implemented |

## Video target

- MiSTer FPGA / DE10-Nano
- Horizontal 4:3 picture
- 320 × 240 active resolution
- 448 × 272 complete raster
- Approximately 57.45 Hz vertical refresh
- Native 15 kHz-class analogue output
- Up to four players, two action buttons: Punch and Kick

## Installing a test build

Download the matching `.rbf` and `.mra` from **Releases** or from a successful
GitHub Actions artifact.

1. Copy `jtwwfwfest.rbf` to `/media/fat/_Arcade/cores/`.
2. Copy `WWF WrestleFest (World).mra` to `/media/fat/_Arcade/`.
3. Supply a compatible `wwfwfest` ROM set from your own legal dump in a ROM
   path used by MiSTer, such as `/media/fat/games/mame/`.
4. Launch the MRA from MiSTer's Arcade menu.

The MRA contains filenames, layout and CRC metadata only. It contains no ROM
bytes.

## Controls

| Function | Default control |
|---|---|
| Move | D-pad / digital joystick |
| Punch | Button 1 |
| Kick | Button 2 |
| Start | Start |
| Coin | Select / Coin |
| Core reset | MiSTer OSD |

## GFXFIX7 CRT test

Use a correctly wired MiSTer analogue RGB/VGA-to-SCART cable and disable forced
scandoubling for a 15 kHz CRT.

1. Set `CRT Sync` to `JTFRAME` and observe the physical image height.
2. Without touching geometry, overscan or service controls on the CRT, change
   only `CRT Sync` to `RAW Core`.
3. Report whether the north-to-south height changes, along with the display,
   cable/analogue board and relevant `MiSTer.ini` settings.

In `RAW Core`, the MiSTer CRT H/V offset options no longer affect the picture by
design. If both modes have identical height, `jtframe_resync` is unlikely to be
the cause and investigation can focus on the 448 × 272 / 57.45 Hz raster.

## Building

The synthesizable core is in `cores/wwfwfest`. The GitHub Actions workflow:

1. rejects ROM/archive files;
2. checks out a pinned official JTCORES/JTFRAME revision;
3. overlays this core and applies the documented GFXFIX7 sync patch;
4. builds the MiSTer `.rbf` and packages it with the matching MRA.

No ROM is needed for synthesis. ROM data is required only to run the game or
ROM-dependent simulations.

## Testing and reports

See [docs/TESTING.md](docs/TESTING.md). Do not upload, attach or link to ROMs.
Screenshots, short videos and audio recordings are welcome where relevant.

## JTFRAME and acknowledgements

This core uses **JTFRAME**, created by **José Tejada (`@topapate`, Jotego)**.
JTFRAME supplies MiSTer integration, shared FPGA modules and build tooling.

- [Jotego's JTCORES repository](https://github.com/jotego/jtcores)
- [JTFRAME source and documentation](https://github.com/jotego/jtcores/tree/master/modules/jtframe)
- [Support Jotego's FPGA research](https://www.patreon.com/jotego)

Thanks also to the MAME developers for documenting the original hardware and
ROM layout. MAME code and game ROMs are not part of this repository.

## Legal and licence

WWF WrestleFest, its characters, trademarks and original content belong to
their respective rights holders. This unofficial, non-commercial preservation
project is not affiliated with or endorsed by Technos Japan, WWE, Tecmo,
MiSTer, Jotego or any rights holder.

Original source in this repository is distributed under the
[GNU General Public License v3.0](LICENSE), consistently with JTFRAME's GPLv3
licensing. Third-party components retain their own notices and licences.
