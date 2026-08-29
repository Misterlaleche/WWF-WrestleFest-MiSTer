#!/usr/bin/env python3
"""Validate JTFRAME ROM interleave/bit permutations against MAME layouts."""

import sys
import zipfile


def bitrev(v):
    return int(f"{v:08b}"[::-1], 2)


def put_swabbed(stream, sort_kind=None):
    mem = bytearray(len(stream))
    for addr, value in enumerate(stream):
        part = addr
        if sort_kind == "hhvvv":
            low = addr & 0x1f
            part = (addr & ~0x1f) | ((low & 7) << 2) | ((low >> 3) & 3)
        mem[part ^ 1] = value
    return mem


def interleave(files):
    out = bytearray()
    for values in zip(*files):
        out.extend(reversed(values))
    return out


def generic_pixel(word, x):
    bit = 7 - (x & 7)
    return sum(((word >> (plane * 8 + bit)) & 1) << plane for plane in range(4))


def raw_pixel(region, code, charinc, planes, xs, ys, x, y):
    value = 0
    for plane, poff in enumerate(planes):
        bit = code * charinc + poff + xs[x] + ys[y]
        value |= ((region[bit >> 3] >> (bit & 7)) & 1) << plane
    return value


def test_text(zf):
    raw = zf.read("31e12-0.ic33")
    mem = put_swabbed(raw, "hhvvv")
    src = [15,14,7,6,31,30,23,22,13,12,5,4,29,28,21,20,
           11,10,3,2,27,26,19,18,9,8,1,0,25,24,17,16]
    for code in (0, 1, 2, 17, 255, 1023, 2047, 4095):
        for y in range(8):
            data = int.from_bytes(mem[((code << 3) | y) * 4:][:4], "little")
            sorted_data = sum(((data >> s) & 1) << (31-k) for k, s in enumerate(src))
            for x in range(8):
                expected = raw_pixel(raw, code, 256, [0,2,4,6],
                    [1,0,65,64,129,128,193,192], [i*8 for i in range(8)], x, y)
                assert generic_pixel(sorted_data, x) == expected


def test_scroll(zf):
    lo, hi = zf.read("31j1.ic2"), zf.read("31j0.ic1")
    mem = put_swabbed(interleave([lo, hi]))
    region = lo + hi
    for code in (0, 1, 2, 17, 255, 1023, 2047, 4095):
        for y in range(16):
            for x in range(16):
                wa = (code << 5) | ((x >> 3) << 4) | y
                b = mem[wa*4:wa*4+4]
                sorted_data = int.from_bytes(bytes((bitrev(b[2]),bitrev(b[0]),
                                                     bitrev(b[3]),bitrev(b[1]))), "little")
                expected = raw_pixel(region, code, 512,
                    [8,0,0x40000*8+8,0x40000*8],
                    list(range(8))+[256+i for i in range(8)],
                    [i*16 for i in range(8)]+[128+i*16 for i in range(8)], x, y)
                assert generic_pixel(sorted_data, x) == expected


def test_objects(zf):
    names = ["31j3.ic9","31j2.ic8","31j5.ic11","31j4.ic10",
             "31j6.ic12","31j7.ic13","31j9.ic15","31j8.ic14"]
    files = [zf.read(name) for name in names]
    seq = [0,2,4,6,1,3,5,7]
    mem = put_swabbed(interleave([files[i] for i in seq[:4]]) +
                       interleave([files[i] for i in seq[4:]]))
    region = b"".join(files)
    for code in (0, 1, 2, 17, 255, 1023, 4095, 32767, 65535):
        for y in range(16):
            for x in range(16):
                wa = (code << 5) | ((x >> 3) << 4) | y
                b = mem[wa*4:wa*4+4]
                sorted_data = int.from_bytes(bytes((bitrev(b[2]),bitrev(b[3]),
                                                     bitrev(b[0]),bitrev(b[1]))), "little")
                expected = raw_pixel(region, code, 256,
                    [0,0x200000*8,0x400000*8,0x600000*8],
                    list(range(8))+[128+i for i in range(8)],
                    [i*8 for i in range(16)], x, y)
                assert generic_pixel(sorted_data, x) == expected


if __name__ == "__main__":
    rom = sys.argv[1] if len(sys.argv) > 1 else "wwfwfest.zip"
    with zipfile.ZipFile(rom) as archive:
        test_text(archive)
        test_scroll(archive)
        test_objects(archive)
    print("PASS: JTFRAME text/scroll/object pixels match MAME layouts")
