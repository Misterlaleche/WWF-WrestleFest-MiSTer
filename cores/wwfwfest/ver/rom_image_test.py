#!/usr/bin/env python3
"""Rebuild the complete JTFRAME download image and compare every byte."""

import binascii
import hashlib
import pathlib
import sys
import zipfile


EXPECTED_CRC = {
    "31e13-0.ic19": 0xbd02e3c4, "31e14-0.ic18": 0x933ea1a0,
    "31a11-2.ic42": 0x5ddebfea, "31j10.ic73": 0x6c522edb,
    "31e12-0.ic33": 0x06f22615, "31j1.ic2": 0x82ed7155,
    "31j0.ic1": 0x8a12b450, "31j3.ic9": 0xe395cf1d,
    "31j2.ic8": 0xb5a97465, "31j5.ic11": 0x2ce545e8,
    "31j4.ic10": 0x00edb66a, "31j6.ic12": 0x79956cf8,
    "31j7.ic13": 0x74d774c3, "31j9.ic15": 0xdd387289,
    "31j8.ic14": 0x44abe127,
}


def interleave(*parts):
    out = bytearray()
    for values in zip(*parts):
        # MRA map bits place the listed parts in download-image order.  The
        # later byte-lane swap performed by JTFRAME SDRAM is intentionally not
        # part of this test (rom_layout_test.py checks the post-SDRAM view).
        out.extend(values)
    return out


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: rom_image_test.py ROM_ZIP JTFRAME_ROM")
    with zipfile.ZipFile(sys.argv[1]) as archive:
        chip = {name: archive.read(name) for name in EXPECTED_CRC}
    for name, expected in EXPECTED_CRC.items():
        actual = binascii.crc32(chip[name]) & 0xffffffff
        assert actual == expected, f"{name}: CRC {actual:08x} != {expected:08x}"

    image = bytearray()
    image += interleave(chip["31e13-0.ic19"], chip["31e14-0.ic18"])
    assert len(image) == 0x080000
    image += chip["31a11-2.ic42"]
    assert len(image) == 0x090000
    image += chip["31j10.ic73"]
    assert len(image) == 0x110000
    image += chip["31e12-0.ic33"]
    assert len(image) == 0x130000
    image += interleave(chip["31j1.ic2"], chip["31j0.ic1"])
    image += b"\xff" * 0x50000
    assert len(image) == 0x200000
    image += interleave(chip["31j3.ic9"], chip["31j5.ic11"],
                        chip["31j6.ic12"], chip["31j9.ic15"])
    image += interleave(chip["31j2.ic8"], chip["31j4.ic10"],
                        chip["31j7.ic13"], chip["31j8.ic14"])
    assert len(image) == 0xa00000

    generated = pathlib.Path(sys.argv[2]).read_bytes()
    assert generated == image, "generated JTFRAME ROM differs from MRA assembly"
    digest = hashlib.sha256(image).hexdigest()
    assert digest == "4872e3502f42951b8011600f4868f94fde52f19a66769309d95cec1346ecdb1a"
    print("PASS: 15 CRCs and complete 10 MiB JTFRAME ROM image match")


if __name__ == "__main__":
    main()
