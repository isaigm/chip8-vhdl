"""
Pygame viewer for the CHIP-8 framebuffer, with keyboard input + key hold.

Because simulation runs far slower than real time, a physical keypress may last
too few simulated cycles for the ROM's polling loop to catch. To compensate,
each pressed key is HELD in the reported bitmask for a few extra frames after
you release it, giving the core time to sample it.

Key mapping (standard CHIP-8 layout):
    PC          CHIP-8
    1 2 3 4  ->  1 2 3 C
    Q W E R  ->  4 5 6 D
    A S D F  ->  7 8 9 E
    Z X C V  ->  A 0 B F
"""

import os
import pygame


WIDTH = 64
HEIGHT = 32

BG_COLOR = (18, 18, 18)
FG_COLOR = (230, 230, 230)

# How many frames to keep a key "held" after physical release. Higher = more
# forgiving input (key registers for longer in sim), but less precise control.
KEY_HOLD_FRAMES = int(os.environ.get("KEY_HOLD_FRAMES", "100"))

KEYMAP = {
    pygame.K_1: 0x1, pygame.K_2: 0x2, pygame.K_3: 0x3, pygame.K_4: 0xC,
    pygame.K_q: 0x4, pygame.K_w: 0x5, pygame.K_e: 0x6, pygame.K_r: 0xD,
    pygame.K_a: 0x7, pygame.K_s: 0x8, pygame.K_d: 0x9, pygame.K_f: 0xE,
    pygame.K_z: 0xA, pygame.K_x: 0x0, pygame.K_c: 0xB, pygame.K_v: 0xF,
}


class Chip8Viewer:
    def __init__(self, scale=12, title="CHIP-8"):
        pygame.init()
        pygame.display.set_caption(title)
        self.scale = scale
        self.screen = pygame.display.set_mode((WIDTH * scale, HEIGHT * scale))
        self._pixels = pygame.Surface((WIDTH, HEIGHT))
        self._quit = False
        # Per-CHIP-8-key countdown: >0 means "still held".
        self._hold = [0] * 16

    def draw(self, framebuffer):
        self._pixels.fill(BG_COLOR)
        for y in range(HEIGHT):
            row = framebuffer[y]
            for x in range(WIDTH):
                if (row >> (63 - x)) & 1:
                    self._pixels.set_at((x, y), FG_COLOR)
        scaled = pygame.transform.scale(
            self._pixels, (WIDTH * self.scale, HEIGHT * self.scale)
        )
        self.screen.blit(scaled, (0, 0))
        pygame.display.flip()

    def pump_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self._quit = True
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                self._quit = True
        return self._quit

    def get_chip8_keys(self):
        """16-bit mask with key-hold applied.

        A key currently held down refreshes its hold counter; a released key
        keeps its bit set until the counter runs out.
        """
        pressed = pygame.key.get_pressed()

        # Refresh hold for physically-pressed keys.
        for pg_key, chip8_key in KEYMAP.items():
            if pressed[pg_key]:
                self._hold[chip8_key] = KEY_HOLD_FRAMES

        # Build mask from any key with hold remaining, and decrement.
        mask = 0
        for k in range(16):
            if self._hold[k] > 0:
                mask |= (1 << k)
                self._hold[k] -= 1
        return mask

    def should_quit(self):
        return self._quit

    def close(self):
        pygame.quit()