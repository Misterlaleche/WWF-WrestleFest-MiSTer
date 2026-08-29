# JTWWFWFEST FPGA core for WWF WrestleFest

Work-in-progress JTFRAME implementation of the Technos TA-0031 board used by
WWF WrestleFest (1991).

## Hardware target

- Motorola 68000 at 12 MHz
- Z80 at 3.579545 MHz
- YM2151 at 3.579545 MHz
- OKI MSM6295 at 1.056 MHz, pin 7 high
- 320x240 active video, approximately 57.45 Hz
- 8x8 text, two 16x16 scrolling tilemaps and buffered 16x16 sprites

The ROMs are not part of this repository. The supported parent set is
`wwfwfest` from MAME's `technos/ddragon3.cpp` driver.

## Status

- [x] Parent ROM set audited
- [x] ROM-region layout defined
- [x] Main and sound memory maps documented
- [x] 68000 bus integration and HDL elaboration
- [x] Z80/YM2151/MSM6295 integration and HDL elaboration
- [x] Exact 7 MHz fractional pixel enable and 448x272 raster simulation
- [x] Tile/sprite bitfield and mixer-order specification
- [x] ROM interleave and pixel-plane verification against MAME
- [x] Text tilemap integration and lint
- [x] BG0/BG1 tilemap integration and lint
- [x] Buffered chained sprite integration and lint
- [x] Priority mixer and palette integration and lint
- [x] JTFRAME memory generation, SDRAM wrapper and game-level elaboration
- [x] Parent MRA and 10 MiB ROM image generated from the audited set
- [x] All 15 chip CRCs and the complete generated ROM verified byte for byte
- [x] 68000 address/input decode and video priority mixer simulations
- [x] Four-player controls and distributed DIP bit mapping audited against MAME
- [x] Z80 sound decode, OKI banking and command-NMI simulation
- [x] Full 4096-word synchronous sprite snapshot simulation
- [x] Sprite chain decoding and 320x240 global-flip simulation
- [x] Raster/VBL interrupt timing and acknowledge simulation
- [x] 68000 write strobes, text byte-smear and control-register simulation
- [x] MiSTer synthesis
- [ ] MiSTer real-hardware validation
