"""
Cocotb testbench for the CHIP-8 CPU — with keyboard input and key-hold.

Runs the core, reads the `gfx` framebuffer, renders it to a pygame window, and
maps the PC keyboard to the CHIP-8's 16 keys (dut.keys) so you can play.

Key mapping (standard CHIP-8 layout):
    PC          CHIP-8
    1 2 3 4  ->  1 2 3 C
    Q W E R  ->  4 5 6 D
    A S D F  ->  7 8 9 E
    Z X C V  ->  A 0 B F
"""

import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from viewer import Chip8Viewer


CYCLES_PER_FRAME = int(os.environ.get("CYCLES_PER_FRAME", "500"))
MAX_CYCLES = int(os.environ.get("MAX_CYCLES", "0"))
SCALE = int(os.environ.get("SCALE", "12"))


def read_framebuffer(dut):
    """Read the 32x64 framebuffer into a list of 32 ints (one 64-bit row each)."""
    rows = []
    for row_idx in range(32):
        try:
            rows.append(int(dut.gfx[row_idx].value))
        except Exception:
            return None
    return rows


@cocotb.test()
async def run_chip8(dut):
    """Run the CHIP-8 core, render the framebuffer, and feed keyboard input."""

    # Clock: 20 ns = 50 MHz. cocotb 2.x uses 'unit' (not 'units').
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    # Reset.
    dut.rst.value = 1
    dut.keys.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

    dut._log.info("Reset released. Click the window for focus, then use the keyboard. "
                  "For the quirks test press 1 to select CHIP-8. Esc or close to stop.")

    viewer = Chip8Viewer(scale=SCALE, title="CHIP-8 (click for focus)")

    total_cycles = 0
    try:
        while True:
            for _ in range(CYCLES_PER_FRAME):
                await RisingEdge(dut.clk)
            total_cycles += CYCLES_PER_FRAME

            quit_requested = viewer.pump_events()
            fb = read_framebuffer(dut)
            if fb is not None:
                viewer.draw(fb)

            dut.keys.value = viewer.get_chip8_keys()

            if quit_requested:
                break
            if MAX_CYCLES and total_cycles >= MAX_CYCLES:
                break
    finally:
        viewer.close()

    dut._log.info("Simulation finished.")