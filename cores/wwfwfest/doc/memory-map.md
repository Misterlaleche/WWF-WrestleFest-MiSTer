# TA-0031 memory map

## 68000

| Range | Function |
|---|---|
| 000000-07ffff | program ROM |
| 080000-080fff | BG0 RAM, four bytes per tile |
| 082000-082fff | BG1 RAM, two bytes per tile |
| 0c0000-0c1fff | text RAM, byte-smeared writes |
| 0c2000-0c3fff | sprite RAM |
| 100000-100007 | BG0/BG1 X/Y scroll registers |
| 10000a-10000b | flip screen |
| 140000-140003 | IRQ3/IRQ2 acknowledge |
| 140008-140009 | sprite-buffer trigger |
| 14000c-14000d | sound latch/NMI |
| 140011 | layer priority |
| 140020-140027 | four player/DIP input words |
| 180000-18ffff | palette window; byte-address lines A5/A6 unconnected |
| 1c0000-1c3fff | work RAM |

IRQ2 is asserted at scanline 0 and every sixteen scanlines through 256; IRQ3
is asserted at scanline 248. The real
board's undocumented 140008 and 140016 behaviour must be checked against PCB
tests rather than inferred solely from MAME.

## Z80

| Range | Function |
|---|---|
| 0000-bfff | program ROM |
| c000-c7ff | RAM |
| c800-c801 | YM2151 |
| d800 | MSM6295 |
| e000 | sound latch |
| e800 | MSM6295 ROM bank |
