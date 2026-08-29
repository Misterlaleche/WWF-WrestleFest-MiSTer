# WWF WrestleFest for MiSTer FPGA

Work-in-progress FPGA core for the arcade hardware used by **WWF WrestleFest**
(Technos Japan, 1991), targeting the **MiSTer FPGA** platform.

> [!IMPORTANT]
> **No game ROMs are included or distributed by this project.**
> The source tree, build artifacts and releases do not contain copyrighted game
> data. Users must supply their own legally obtained compatible ROM dump.

## Project status

This core is under active development and should be treated as an experimental
test build. It is not yet considered release-quality or cycle-accurate.

| Area | Current status |
|---|---|
| Main CPU and memory map | Implemented |
| Tilemaps, text and sprites | Implemented; simulation validated |
| Sprite colours and palette path | Corrected; simulation validated |
| Four-player inputs | Implemented |
| DIP switches | Exposed in the MiSTer OSD |
| Service/Test | Exposed in the MiSTer OSD and keyboard controls |
| YM2151 + MSM6295 audio | Implemented; real-hardware listening tests pending |
| HDMI output | Hardware testing pending |
| Analogue 15 kHz output | Hardware testing pending |
| Cheats | Not implemented |
| Save states | Not implemented |

Testing on real MiSTer hardware is particularly welcome. Please report both
regressions and successful tests through the issue tracker.

## Hardware and video target

- MiSTer FPGA / DE10-Nano
- Horizontal 4:3 video
- 320 x 240 active resolution
- Approximately 57.45 Hz vertical refresh
- Native 15 kHz-compatible timing for analogue CRT output
- Up to four players
- Two action buttons: Punch and Kick

## Installing a test build

Download the latest `.rbf` and `.mra` from the repository's **Releases** page.

1. Copy `jtwwfwfest.rbf` to `/media/fat/_Arcade/cores/`.
2. Copy `WWF WrestleFest (World).mra` to `/media/fat/_Arcade/`.
3. Supply a compatible `wwfwfest` ROM set from your own legal dump in a ROM
   path used by MiSTer, such as `/media/fat/games/mame/`.
4. Start the game through the MRA entry in the Arcade menu.

The MRA lists the required chip filenames and CRC values, but contains no ROM
data itself.

## Controls and service functions

| Function | Default control |
|---|---|
| Move | D-pad / digital joystick |
| Punch | Button 1 |
| Kick | Button 2 |
| Start | Start |
| Coin | Select / Coin |
| Service credit | Keyboard `9` |
| Service/Test mode | OSD option / keyboard `F2` |
| Core reset | Keyboard `F3` |

The core also exposes the original arcade DIP switches in the MiSTer OSD.

## Analogue video and VGA-to-SCART

The core is designed to output native arcade-rate video and should be suitable
for MiSTer's analogue output through a correctly wired MiSTer VGA-to-SCART or
RGB cable. Use a cable intended for MiSTer that provides the proper sync and
SCART blanking voltages; a passive PC VGA-to-SCART cable is not necessarily
equivalent.

When testing a 15 kHz CRT, disable forced scandoubling. Please include the
display model, cable or analogue board, and relevant `MiSTer.ini` settings in
video-related reports.

## Building

The synthesizable core lives in `cores/wwfwfest`. It is compiled against the
JTFRAME infrastructure from the upstream `jotego/jtcores` repository.

The included GitHub Actions workflow checks that no ROM images are present,
checks out the required JTFRAME tree, overlays this core and builds the MiSTer
`.rbf`. You can also copy `cores/wwfwfest` into a local JTCORE checkout and run:

```sh
jtcore wwfwfest -mister
```

No ROM is needed for synthesis. ROM data is only required to run the game or
ROM-dependent simulations.

## Testing and bug reports

See [docs/TESTING.md](docs/TESTING.md) before opening a report. Screenshots or
short videos are valuable for graphics and timing issues; audio recordings are
valuable for volume, balance and playback problems.

## JTFRAME and acknowledgements

This core is built with **JTFRAME**, the FPGA development framework created by
**José Tejada (`@topapate`, Jotego)**. JTFRAME provides the MiSTer integration,
common FPGA modules, build tooling and development methodology used here.

- [Jotego's JTCORES repository](https://github.com/jotego/jtcores)
- [JTFRAME documentation](https://github.com/jotego/jtcores/tree/master/modules/jtframe)
- [Support Jotego's FPGA research](https://www.patreon.com/jotego)

Thanks also to the MAME developers for documenting the original arcade
hardware and ROM layout. MAME code and game ROMs are not part of this project.

## Legal notice

WWF WrestleFest, its characters, trademarks and original game content belong
to their respective rights holders. This is an unofficial, non-commercial
hardware preservation and research project. It is not affiliated with or
endorsed by Technos Japan, WWE, Tecmo, MiSTer, Jotego or any rights holder.

No ROM files, game assets or proprietary software are provided. Requests for
ROMs or links to unauthorized copies will not be accepted.

## License

The original source code in this repository is distributed under the
[GNU General Public License v3.0](LICENSE), in accordance with JTFRAME's GPLv3
licensing requirements. Third-party components retain their own notices and
licenses.
