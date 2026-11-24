#!/usr/bin/env python3
"""Bangun app_icon.ico dari satu master rounded: assets/cen_logo_rounded10.png.

Semua frame memakai logo yang sama, hanya di-resize. Tidak ada glyph terpisah,
jadi ikon taskbar/titlebar selalu identik dengan logo di aplikasi.
Jalankan: python3 tool/make_app_icon.py
"""
from PIL import Image
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets' / 'cen_logo_rounded10.png'
OUT = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
PREVIEW = ROOT / 'build' / 'app_icon_preview'
SIZES = (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)


def write_ico(frames, path):
    """Tulis ICO dengan frame PNG (didukung Windows Vista+)."""
    blobs = []
    for size, image in frames:
        tmp = PREVIEW / f'frame-{size}.png'
        tmp.parent.mkdir(parents=True, exist_ok=True)
        image.save(tmp, 'PNG')
        blobs.append((size, tmp.read_bytes()))

    offset = 6 + 16 * len(blobs)
    header = struct.pack('<HHH', 0, 1, len(blobs))
    entries = b''
    data = b''
    for size, blob in blobs:
        entries += struct.pack('<BBBBHHII', size % 256, size % 256, 0, 0, 1, 32, len(blob), offset)
        data += blob
        offset += len(blob)
    path.write_bytes(header + entries + data)


def main():
    master = Image.open(SRC).convert('RGBA')
    frames = [(size, master.resize((size, size), Image.LANCZOS)) for size in SIZES]

    PREVIEW.mkdir(parents=True, exist_ok=True)
    write_ico(frames, OUT)

    # Contact sheet 24/32/40/48 pada latar terang dan gelap, diperbesar 6x.
    scale = 6
    cell = 64 * scale
    gap = 12
    sheet = Image.new('RGB', (4 * cell + 5 * gap, 2 * cell + 3 * gap), (255, 255, 255))
    for row, bg in enumerate(((255, 255, 255), (32, 32, 32))):
        for col, size in enumerate((24, 32, 40, 48)):
            art = master.resize((size, size), Image.LANCZOS).resize((cell, cell), Image.NEAREST)
            patch = Image.new('RGB', (cell, cell), bg)
            patch.paste(art, (0, 0), art)
            sheet.paste(patch, (gap + col * (cell + gap), gap + row * (cell + gap)))
    sheet.save(PREVIEW / 'sizes.png')

    print(f'{OUT} -> {OUT.stat().st_size} bytes, {len(frames)} frame')


if __name__ == '__main__':
    main()
