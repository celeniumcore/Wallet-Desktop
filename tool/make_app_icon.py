#!/usr/bin/env python3
"""Bangun app_icon.ico dari aset logo asli.

Ukuran kecil (<=48 px) memakai glyph lima kelopak yang digambar khusus di grid
piksel: logo detail kalau diperkecil jadi blob abu-abu di titlebar/taskbar.
Ukuran >=64 px memakai logo asli (lubang kelopak masih terbaca).
Jalankan: python3 tool/make_app_icon.py
"""
from PIL import Image, ImageChops, ImageDraw
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets' / 'cen_logo.png'
OUT = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
PREVIEW = ROOT / 'build' / 'app_icon_preview'

BG = (245, 241, 232)
NAVY = (29, 34, 53)
GOLD = (168, 128, 43)
TILE_FILL = 0.82
TILE_RADIUS = 0.22
SMALL_SIZES = (16, 20, 24, 32, 40, 48)
LARGE_SIZES = (64, 96, 128, 256)


def tile_mask(size):
    s = size * 8
    mask = Image.new('L', (s, s), 0)
    inset = int(round((1 - TILE_FILL) / 2 * s))
    ImageDraw.Draw(mask).rounded_rectangle(
        [inset, inset, s - inset - 1, s - inset - 1],
        radius=int(round(TILE_RADIUS * s)),
        fill=255,
    )
    return mask.resize((size, size), Image.LANCZOS)


def rounded_tile(size):
    tile = Image.new('RGBA', (size, size), BG + (255,))
    tile.putalpha(tile_mask(size))
    return tile


def paste_masked(base, art, offset):
    """Tempel art ke base, lalu potong mengikuti alpha base (sudut membulat)."""
    mask = base.getchannel('A')
    base.alpha_composite(art.convert('RGBA'), offset)
    base.putalpha(ImageChops.multiply(base.getchannel('A'), mask))


def small_glyph(size):
    """Lima kelopak solid + pusat emas; tanpa lubang agar tidak jadi noise."""
    s = size * 8
    art = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(art)
    c = s / 2
    radius = s * TILE_FILL / 2
    petal_distance = radius * 0.62
    semi_radial = radius * 0.42
    semi_tangent = radius * 0.30
    for k in range(5):
        theta = -math.pi / 2 + k * 2 * math.pi / 5
        points = []
        for i in range(181):
            t = 2 * math.pi * i / 180
            u = semi_radial * math.cos(t)
            v = semi_tangent * math.sin(t)
            points.append((
                c + petal_distance * math.cos(theta) + u * math.cos(theta) - v * math.sin(theta),
                c + petal_distance * math.sin(theta) + u * math.sin(theta) + v * math.cos(theta),
            ))
        d.polygon(points, fill=NAVY + (255,))
    center = radius * 0.20
    d.ellipse([c - center, c - center, c + center, c + center], fill=GOLD + (255,))
    # Garis bintang di pusat hanya bermakna >=32 px; di bawah itu jadi noise.
    if size >= 32:
        width = max(1, int(round(s * 0.010)))
        for k in range(5):
            theta = -math.pi / 2 + k * 2 * math.pi / 5
            d.line([c, c, c + center * 0.92 * math.cos(theta), c + center * 0.92 * math.sin(theta)],
                   fill=NAVY + (255,), width=width)

    icon = rounded_tile(size)
    paste_masked(icon, art.resize((size, size), Image.LANCZOS), (0, 0))
    return icon


def large_logo(size, master, mark_box):
    """Logo asli, dipotong ke bbox bunga, dengan margin tetap di dalam tile."""
    flower = master.crop(mark_box)
    box = int(round(size * TILE_FILL * 0.86))
    flower.thumbnail((box, box), Image.LANCZOS)
    icon = rounded_tile(size)
    paste_masked(icon, flower, ((size - flower.width) // 2, (size - flower.height) // 2))
    return icon


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
    master = Image.open(SRC).convert('RGB')
    diff = ImageChops.difference(master, Image.new('RGB', master.size, BG))
    mark_box = diff.convert('L').point(lambda v: 255 if v > 18 else 0).getbbox()
    if mark_box is None:
        raise SystemExit('logo: tidak ada mark yang terdeteksi')

    frames = [(size, small_glyph(size)) for size in SMALL_SIZES]
    frames += [(size, large_logo(size, master, mark_box)) for size in LARGE_SIZES]

    PREVIEW.mkdir(parents=True, exist_ok=True)
    write_ico(frames, OUT)

    # Contact sheet 24/32/40/48 pada latar terang dan gelap, diperbesar 6x.
    scale = 6
    light = Image.new('RGB', (4 * 64 * scale + 5 * 12, 2 * 64 * scale + 3 * 12), (255, 255, 255))
    dark = Image.new('RGB', light.size, (32, 32, 32))
    for row, canvas in enumerate((light, dark)):
        bg = (32, 32, 32) if row else (255, 255, 255)
        for col, size in enumerate((24, 32, 40, 48)):
            image = small_glyph(size).resize((64 * scale, 64 * scale), Image.NEAREST)
            x = 12 + col * (64 * scale + 12)
            y = 12 + row * (64 * scale + 12)
            patch = Image.new('RGB', image.size, bg)
            patch.paste(image, (0, 0), image)
            canvas.paste(patch, (x, y))
    light.save(PREVIEW / 'small-sheet-light.png')
    dark.save(PREVIEW / 'small-sheet-dark.png')

    print(f'{OUT} -> {OUT.stat().st_size} bytes, {len(frames)} frame')


if __name__ == '__main__':
    main()