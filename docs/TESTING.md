# Testing guide

Thank you for testing the WWF WrestleFest MiSTer FPGA core.

## Before reporting

Please test the latest file published on the Releases page and confirm that the
matching MRA is installed. If possible, reproduce the problem after a cold boot
of MiSTer and with default DIP settings.

## What to include

- Release or build identifier
- MiSTer main version and update date
- SDRAM module size and board revision, if known
- Output path: HDMI, analogue I/O board, Direct Video, VGA-to-SCART, etc.
- Display model and orientation
- Controller or four-player adapter used
- Game mode, wrestlers and approximate point where the issue occurs
- Whether the issue also appears after Core Reset
- Screenshot, short video or audio recording when relevant

Do not upload or link to ROM files. It is sufficient to state that the ROM set
passed the MRA's filename and CRC checks.

## High-priority checks

1. Boot, attract mode and player selection
2. Wrestler entrances and VS screen
3. Active match with referee and multiple wrestlers
4. Sprite colours at both edges of the ring
5. Top and bottom of the image over HDMI and 15 kHz RGB
6. Music, crowd, speech and impact sound balance
7. Two-player and four-player controls
8. DIP switch changes after reset
9. Service/Test mode entry and exit

## Known limitations

- The core remains under development.
- Audio has not yet completed real-hardware listening validation.
- Save states and cheats are not implemented.
- Timing, overscan and analogue compatibility still require wider hardware
  testing.
