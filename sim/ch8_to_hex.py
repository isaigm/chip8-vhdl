#!/usr/bin/env python3
"""
ch8_to_hex.py — Convert a CHIP-8 .ch8 ROM into a hex file for VHDL textio loading.

Produces a file with one byte per line, in hex (e.g. "a2"), covering the full
4096-byte address space:
  - addresses 0x000..0x04F: the built-in font sprites (0-F)
  - addresses 0x050..0x1FF: zeros
  - addresses 0x200..     : the ROM bytes
  - remaining addresses   : zeros

The RAM entity reads this file with textio at elaboration, so you never edit
ram.vhd to change ROM — you just regenerate this file.

Usage:
    python3 ch8_to_hex.py roms/maze.ch8 rom.hex
"""

import sys

# Standard CHIP-8 font set: 16 characters (0-F), 5 bytes each, 80 bytes total.
# Lives at 0x050 by convention (your FX29 computes 0x50 + Vx*5).
FONT = [
    0xF0, 0x90, 0x90, 0x90, 0xF0,  # 0
    0x20, 0x60, 0x20, 0x20, 0x70,  # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,  # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,  # 3
    0x90, 0x90, 0xF0, 0x10, 0x10,  # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,  # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,  # 6
    0xF0, 0x10, 0x20, 0x40, 0x40,  # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,  # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,  # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,  # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,  # B
    0xF0, 0x80, 0x80, 0x80, 0xF0,  # C
    0xE0, 0x90, 0x90, 0x90, 0xE0,  # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,  # E
    0xF0, 0x80, 0xF0, 0x80, 0x80,  # F
]

FONT_BASE = 0x050
ROM_BASE = 0x200
MEM_SIZE = 4096


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 ch8_to_hex.py <rom.ch8> <out.hex>", file=sys.stderr)
        sys.exit(1)

    rom_path, out_path = sys.argv[1], sys.argv[2]

    with open(rom_path, "rb") as f:
        rom = f.read()

    if ROM_BASE + len(rom) > MEM_SIZE:
        print(f"Error: ROM ({len(rom)} bytes) overflows memory from 0x200.",
              file=sys.stderr)
        sys.exit(1)

    # Build the full 4096-byte image.
    mem = [0x00] * MEM_SIZE

    # Place the font at 0x050.
    for i, b in enumerate(FONT):
        mem[FONT_BASE + i] = b

    # Place the ROM at 0x200.
    for i, b in enumerate(rom):
        mem[ROM_BASE + i] = b

    # Write one hex byte per line.
    with open(out_path, "w") as f:
        for b in mem:
            f.write(f"{b:02x}\n")

    print(f"Wrote {out_path}: {MEM_SIZE} bytes "
          f"(font at 0x{FONT_BASE:03x}, ROM '{rom_path}' {len(rom)} bytes at 0x{ROM_BASE:03x})")


if __name__ == "__main__":
    main()
