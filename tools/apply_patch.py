#!/usr/bin/env python3
"""apply_patch.py - build the hard-reset ROM image from a stock Apple ROM.

usage: apply_patch.py <stock-rom> <output> [<patch>]

<stock-rom> is one of:
  342-0303-A   enhanced IIe EF ROM, 8K   -> image for the EF socket
  342-0349-B   IIe Platinum ROM, 16K     -> image for the single ROM socket

<patch> defaults to patch/reset_patch.bin (115 bytes for $FA62-$FAD4).

The stock image is identified by SHA1 and refused if it is anything else.
The output is checked against the expected SHA1 when the shipped patch is used.
"""

import hashlib
import os
import sys

PATCH_LEN = 0x73            # $FA62-$FAD4

# sha1 of stock image: (name, file offset of $FA62, expected output sha1)
STOCK = {
    "afb09bb96038232dc757d40c0605623cae38088e":
        ("342-0303-A (enhanced IIe EF, 8K)", 0x1A62,
         "8d0d46ead8658ec37eb126d75d435b724fd81bcc"),
    "b8ea90abe135a0031065e01697c4a3a20d51198b":
        ("342-0349-B (IIe Platinum, 16K)", 0x3A62,
         "e6f097b249d051207c5298462fc6fca952d830c8"),
}
SHIPPED_PATCH_SHA1 = "2365c1f68f4c919647ef29111b5f90415024a4d4"


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def main():
    if len(sys.argv) not in (3, 4):
        print(__doc__.strip(), file=sys.stderr)
        return 1
    here = os.path.dirname(os.path.abspath(__file__))
    stock_path, out_path = sys.argv[1], sys.argv[2]
    patch_path = sys.argv[3] if len(sys.argv) == 4 else \
        os.path.join(here, "..", "patch", "reset_patch.bin")

    stock = open(stock_path, "rb").read()
    patch = open(patch_path, "rb").read()

    if len(patch) != PATCH_LEN:
        print(f"{patch_path}: {len(patch)} bytes, expected {PATCH_LEN}", file=sys.stderr)
        return 1
    key = sha1(stock)
    if key not in STOCK:
        print(f"{stock_path}: SHA1 {key} is not 342-0303-A or 342-0349-B", file=sys.stderr)
        return 1
    name, off, want = STOCK[key]

    image = bytearray(stock)
    image[off:off + PATCH_LEN] = patch
    got = sha1(image)
    if sha1(patch) == SHIPPED_PATCH_SHA1 and got != want:
        print(f"output SHA1 {got} != expected {want}", file=sys.stderr)
        return 1

    open(out_path, "wb").write(image)
    print(f"{name} -> {out_path} ({len(image)} bytes, SHA1 {got})")
    return 0


sys.exit(main())
