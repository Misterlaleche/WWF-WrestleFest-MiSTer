# TA-0031 video implementation notes

This document records the bit-accurate decode needed by the FPGA video path.
It is derived from the current MAME `technos/ddragon3_v.cpp` implementation;
timing totals in MAME are explicitly estimates and remain a PCB-validation
item.

## Visible raster

- Total: 448 x 272
- Active: 320 x 240
- VBL starts at scanline 248
- IRQ2: scanlines 0, 16, 32, ... 256
- IRQ3: scanline 248

## Text layer

- Map: 64 x 32 tiles
- Tile: 8 x 8, 4 bpp
- Two byte-smeared RAM entries per tile
- Code: `ram[2*n][7:0] | (ram[2*n+1][3:0] << 8)`
- Palette bank: `ram[2*n+1][7:4]`
- Transparent pen: 0
- Palette base: 0x000

The 0x20000-byte character ROM uses two 2-bpp halves. For each row, the
first half provides planes 2/3 and the second half provides planes 0/1.

## Four-byte scrolling layer (MAME FG)

- Map: 32 x 32 tiles
- Tile: 16 x 16, 4 bpp
- Attribute word followed by code word
- Code: `code_word[12:0]`
- Palette bank: `attribute[3:0]`
- X/Y flip: `attribute[7:6]`
- Transparent pen: 0
- Palette base: 0x1000

## Two-byte scrolling layer (MAME BG)

- Map: 32 x 32 tiles
- Tile: 16 x 16, 4 bpp
- Code: `entry[11:0]` (the generic DD3 tile-base bit is not programmed by
  WrestleFest)
- Palette bank: `entry[15:12]`
- Transparent pen: 0, except when this is the bottom opaque layer
- Palette base: 0x0c00

Priority also swaps which scroll-register pair feeds each physical tilemap:

| priority | four-byte layer scroll | two-byte layer scroll |
|---|---|---|
| 0x78 | FG X/Y | BG X/Y |
| other | BG X/Y | FG X/Y |

## Sprites

- 16 bytes (eight words) per descriptor
- Enable: word 1 bit 0
- Y: `word0[7:0] | word1[1] << 8`
- X: `word5[7:0] | word1[2] << 8`
- Flip Y/X: word 1 bits 3/4
- Vertical chain length minus one: word 1 bits 7:5
- Code: `word2[7:0] | word3[7:0] << 8`
- Palette bank: word 4 bits 3:0
- Transparent pen: 0
- Palette base: 0x400

The eight 1 MiB mask ROMs are grouped by matching halves of the four MAME
bitplane quarters: `[0,2,4,6]` followed by `[1,3,5,7]`. The MRA therefore
downloads this region as a 32-bit interleave rather than eight sequential
byte-wide devices.

Sprite X is signed in a 9-bit 512-pixel space. Sprite Y is transformed with
`((256-y) & 0x1ff)-16`. The base code is aligned to the next power of two
covering the chain, as MAME does with its `bit_width(chain)` mask.

Global flip uses MAME's sprite transforms: vertical origin `240-y`, inverted
descriptor Y flip and horizontal origin `304-x`. The JTFRAME object buffer
therefore uses `FLIP_OFFSET=320`; its reversed 16-pixel write produces the
same `304-x` left edge while also inverting descriptor X flip.

The CPU-visible object RAM must be copied to a private rendering buffer on the
write to 0x140008 so the renderer never observes a partially updated list.

## Mixer orders

Text is always last (topmost). Known game values are:

| priority | bottom -> top |
|---|---|
| 0x7b | four-byte layer, two-byte layer, sprites, text |
| 0x7c | four-byte layer, sprites, two-byte layer, text |
| 0x78 | two-byte layer, four-byte layer, sprites, text |

Unknown priority values should render a deterministic fallback rather than a
blank frame; use the 0x78 order until hardware evidence says otherwise.

## Palette

The CPU sees a 64 KiB palette window, but PCB byte-address lines A5/A6 are not
connected. The physical word-entry address is therefore `{A[15:7], A[4:1]}`
(equivalent to MAME's `(offset&0x000f)|((offset&0x7fc0)>>2)`).
Colour format is 4-bit RGB (`xxxx BBBB GGGG RRRR`) and should expand each
nibble to 8 bits by duplication.
