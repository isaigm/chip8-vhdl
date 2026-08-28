# Cocotb + GHDL Makefile for the CHIP-8 core, with automatic ROM loading.
#
# Usage:
#   make run ROM=roms/maze.ch8      # generate hex from ROM, then simulate
#   make run                        # uses the default ROM below
#   make ROM=roms/pong.ch8          # 'make' alone also works (.DEFAULT_GOAL)
#
# The hex file the RAM loads is regenerated from the .ch8 before every run,
# so you never edit ram.vhd to change ROM. Just change ROM= and go.

# ============================================================
#  CHANGE THIS to pick a ROM (or pass ROM=... on the command line)
ROM ?= roms/maze.ch8
# ============================================================

HEX = rom.hex

TOPLEVEL_LANG = vhdl
SIM ?= ghdl

SRC = .

# VHDL sources in dependency order: package first, then leaf components
# (alu, lfsr16, control_unit, priority_encoder, ram), then the top (cpu) last.
# priority_encoder must come before cpu because cpu instantiates it. It is
# recursive (instantiates itself), which GHDL handles fine as long as the
# entity is analyzed before it's used.
VHDL_SOURCES = \
    $(SRC)/chip8_pkg.vhd \
    $(SRC)/alu.vhd \
    $(SRC)/lfsr16.vhd \
    $(SRC)/control_unit.vhd \
    $(SRC)/priority_encoder.vhd \
    $(SRC)/ram.vhd \
    $(SRC)/cpu.vhd

TOPLEVEL = cpu
MODULE = test_chip8

# VHDL-2008 for analysis/elaboration only (GHDL-LLVM rejects --std on the run).
COMPILE_ARGS += --std=08

# Pull in cocotb's rules (this defines the 'sim' target we delegate to).
include $(shell cocotb-config --makefiles)/Makefile.sim

# --- Our entry point: regenerate the hex from the ROM, then run cocotb's sim.
# Calling $(MAKE) sim guarantees the hex is fresh BEFORE elaboration reads it.
.PHONY: run
run:
	python3 ch8_to_hex.py $(ROM) $(HEX)
	$(MAKE) sim

# Make plain 'make' behave like 'make run'.
.DEFAULT_GOAL := run
