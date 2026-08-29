# Testing guide

Thank you for testing the WWF WrestleFest MiSTer FPGA core.

## Before reporting

Use the latest **GFXFIX7-SYNC-A-B** `.rbf` together with its matching MRA. If
possible, reproduce the issue after a MiSTer cold boot and with default DIP
settings.

Never upload or link to ROM files. It is enough to state that your legally
obtained set passed the MRA filename and CRC checks.

## Primary GFXFIX7-SYNC-A-B test

This is the most important analogue CRT comparison:

1. Do not alter CRT geometry, overscan or service-menu settings during the test.
2. Select `CRT Sync: JTFRAME` and note the physical north-to-south image height.
3. Change only the OSD selector to `CRT Sync: RAW Core`.
4. Report whether the height is identical, taller or shorter.

`JTFRAME` uses the normal `jtframe_resync` path. `RAW Core` bypasses it, so the
MiSTer CRT H/V offsets intentionally stop acting in RAW mode. Resolution, pixel
clock, blanking, CPU, IRQ and game speed remain unchanged.

## Include in a report

- Exact build identifier
- MiSTer main version and update date
- SDRAM module size and board revision, if known
- HDMI, analogue I/O board, Direct Video or VGA-to-SCART path
- Display model and orientation
- Cable or analogue board and relevant `MiSTer.ini` settings
- `CRT Sync` mode and whether CRT H/V offsets were changed
- Controller or four-player adapter
- Game mode, wrestlers and approximate point where the issue occurs
- Screenshot, short video or audio recording when relevant

## Other high-priority checks

1. Boot, attract mode and player selection
2. Wrestler entrances and VS screen
3. Active match with referee and multiple wrestlers
4. Sprite colours at both edges of the ring
5. Top/bottom visibility over HDMI and 15 kHz RGB
6. Music, crowd, speech and impact-sound balance
7. Two-player and four-player controls
8. DIP switch behaviour after reset

## Known limitations

- The core remains under development.
- Audio still needs wider real-hardware listening validation.
- Save states and cheats are not implemented.
- Timing, overscan and analogue compatibility need more hardware reports.
