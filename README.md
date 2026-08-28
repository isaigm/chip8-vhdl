# CHIP-8 Interpreter in VHDL
<img width="1452" height="692" alt="image" src="https://github.com/user-attachments/assets/83c2a40d-492a-43b2-9a9b-43ad14f76748" />

A cycle-accurate CHIP-8 interpreter written in VHDL, targeting the Digilent
Basys 3 (Xilinx Artix-7 XC7A35T). The core passes the full
[Timendus CHIP-8 test suite](https://github.com/Timendus/chip8-test-suite)
in CHIP-8 mode.

## Status

**Passes the full Timendus test suite (CHIP-8 mode):**

| Test | Result |
|------|--------|
| 1 — CHIP-8 logo | pass |
| 3 — Corax+ (opcodes) | pass |
| 4 — Flags (VF behaviour) | pass |
| 5 — Quirks (memory, shifting, vF reset, clipping) | pass |
| 6 — Keypad (SKP / SKNP / FX0A) | pass |

Runs real ROMs (IBM logo, Maze, Pong, …) in a live cocotb + pygame simulation.

## Architecture

The CPU is a **multi-cycle FSM** (deliberately not pipelined — clarity over
throughput for this design). Each instruction goes through a two-cycle fetch
(`FETCH_HI` / `FETCH_LO`), a `DECODE` stage that centralises `PC += 2` and
dispatches, then per-opcode execution states.

Design highlights:

- **Sprite drawing (DXYN)** uses a 64-bit barrel shifter to position each
  sprite row in one step — no per-pixel loop. Clipping (screen edges) and
  initial-position wrap are handled per the CHIP-8 spec, with correct VF
  collision detection.
- **Memory** is 4 KB, byte-addressable, with combinational read and
  synchronous write. It infers as distributed RAM (LUTRAM), using **zero
  block RAM**.
- **Framebuffer** is 32 rows × 64-bit vectors (MSB = leftmost column).
- **Random (CXKK)** comes from a 16-bit LFSR.
- **Wait-for-key (FX0A)** uses a recursive divide-and-conquer priority encoder
  to find the pressed key.
- **Timers** (delay + sound) decrement at 60 Hz via a clock divider, resolved
  in a single process to avoid multiple drivers.
- **BCD (FX33)** uses the double-dabble algorithm.
- Invalid opcodes fall back safely to fetch instead of hanging the FSM.

## Repository layout

```
rtl/          the CHIP-8 core (all hand-written VHDL)
  cpu.vhd            multi-cycle FSM, register file, dispatch
  alu.vhd           arithmetic/logic + shifts
  control_unit.vhd  opcode -> ALU op / VF-write decode
  ram.vhd           4 KB memory, loads a hex image via textio
  chip8_pkg.vhd     shared types (framebuffer, etc.)
  lfsr16.vhd        16-bit LFSR (random source)
  priority_encoder.vhd  recursive priority encoder (FX0A)
sim/          verification / live simulator (cocotb + pygame)
  test_chip8.py     cocotb testbench: clock, reset, framebuffer, keyboard
  viewer.py         pygame viewer + PC-keyboard -> CHIP-8 keypad mapping
  ch8_to_hex.py     .ch8 ROM -> hex image (font at 0x050, ROM at 0x200)
  Makefile          builds + runs a chosen ROM
roms/         test ROMs
constraints/  Basys 3 .xdc (for synthesis)
```

## Running the simulation

Requires GHDL (LLVM backend), cocotb, and pygame.

```bash
cd sim
make ROM=roms/maze.ch8        # convert the ROM and run it in a pygame window
```

Change `ROM=` to run a different ROM — the hex image the RAM loads is
regenerated automatically, so you never edit `ram.vhd` to swap ROMs.

Keyboard mapping (standard CHIP-8 layout):

```
PC          CHIP-8
1 2 3 4  ->  1 2 3 C
Q W E R  ->  4 5 6 D
A S D F  ->  7 8 9 E
Z X C V  ->  A 0 B F
```

For the static test ROMs, raise the cycles-per-frame so they run quickly:

```bash
CYCLES_PER_FRAME=10000 make ROM=roms/3-corax+.ch8
```

> Test ROMs are not included here — download them from the
> [Timendus test suite](https://github.com/Timendus/chip8-test-suite)
> (`bin/` folder) and drop them in `roms/`.

## Synthesis (Basys 3, XC7A35T @ 50 MHz)

- Timing: positive WNS (Fmax ~68 MHz)
- ~1130 LUTs (~5%), ~2260 FF (~5%)
- 0 block RAM

## Notes on authorship

All CHIP-8 interpreter RTL — the CPU, ALU, control unit, memory, sprite
drawing, timers, and instruction logic — was written by me. The verification
tooling (cocotb testbench, pygame viewer, ROM-to-hex converter, Makefile) was
built with LLM assistance, as were the generic utility building blocks (the
LFSR, the priority-encoder pattern, and the BCD double-dabble function), which
are used like library components. The interpreter logic itself is entirely my
own work, debugged against a reference emulator and the Timendus suite.

## License

MIT
