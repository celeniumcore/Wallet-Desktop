#!/usr/bin/env python3
"""Icon candidates for the Kirim / Terima nav items, drawn at real 22 px size."""
import os

OUT = os.path.dirname(os.path.abspath(__file__))
C = {"bg": "#070A08", "rail": "#0E1310", "card": "#11170F", "line": "#252E25",
     "lineStrong": "#344034", "txt": "#F2F4EE", "sub": "#9AA696", "muted": "#828F80",
     "acid": "#C9D98F"}
FONT = "Roboto, Liberation Sans, sans-serif"


def t(x, y, s, size=12, fill=None, weight=400, anchor="start", spacing=0):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["txt"]}" text-anchor="{anchor}" letter-spacing="{spacing}">{s}</text>')


def icon(name, cx, cy, color, k=1.0, sw=1.6):
    """k = zoom factor. Geometry authored on a 22 px box."""
    s = k
    w = sw / k if k > 1 else sw
    g = []
    if name == "tray-out":
        g.append(f'<path d="M {cx-7*s} {cy+1*s} v {4*s} a {2*s} {2*s} 0 0 0 {2*s} {2*s} h {10*s} a {2*s} {2*s} 0 0 0 {2*s} {-2*s} v {-4*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
        g.append(f'<path d="M {cx} {cy+2*s} V {cy-7*s} M {cx-3.6*s} {cy-3.4*s} L {cx} {cy-7.2*s} L {cx+3.6*s} {cy-3.4*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "tray-in":
        g.append(f'<path d="M {cx-7*s} {cy+1*s} v {4*s} a {2*s} {2*s} 0 0 0 {2*s} {2*s} h {10*s} a {2*s} {2*s} 0 0 0 {2*s} {-2*s} v {-4*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
        g.append(f'<path d="M {cx} {cy-7*s} V {cy+2*s} M {cx-3.6*s} {cy-1.6*s} L {cx} {cy+2.2*s} L {cx+3.6*s} {cy-1.6*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "plane":
        g.append(f'<path d="M {cx-8*s} {cy+0.4*s} L {cx+8.4*s} {cy-7.6*s} L {cx+4.2*s} {cy+7.8*s} L {cx+1.2*s} {cy+2.2*s} Z" fill="none" stroke="{color}" stroke-width="{w}" stroke-linejoin="round"/>')
        g.append(f'<path d="M {cx+1.2*s} {cy+2.2*s} L {cx+8.4*s} {cy-7.6*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
    elif name == "inbox":
        g.append(f'<path d="M {cx-8*s} {cy+3.4*s} v {3.2*s} a {2*s} {2*s} 0 0 0 {2*s} {2*s} h {12*s} a {2*s} {2*s} 0 0 0 {2*s} {-2*s} v {-3.2*s} h {-4.4*s} l {-1.6*s} {2*s} h {-4*s} l {-1.6*s} {-2*s} Z" fill="none" stroke="{color}" stroke-width="{w}" stroke-linejoin="round"/>')
        g.append(f'<path d="M {cx} {cy-8*s} V {cy+1*s} M {cx-3*s} {cy-2*s} L {cx} {cy+1.4*s} L {cx+3*s} {cy-2*s}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "arrow-up":
        g.append(f'<path d="M {cx} {cy+8*s} V {cy-7.4*s} M {cx-5*s} {cy-2.6*s} L {cx} {cy-7.8*s} L {cx+5*s} {cy-2.6*s}" fill="none" stroke="{color}" stroke-width="{w*1.15}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "arrow-down":
        g.append(f'<path d="M {cx} {cy-8*s} V {cy+7.4*s} M {cx-5*s} {cy+2.6*s} L {cx} {cy+7.8*s} L {cx+5*s} {cy+2.6*s}" fill="none" stroke="{color}" stroke-width="{w*1.15}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "coin-minus":
        g.append(f'<circle cx="{cx}" cy="{cy}" r="{8*s}" fill="none" stroke="{color}" stroke-width="{w}"/>')
        g.append(f'<path d="M {cx-3.6*s} {cy} h {7.2*s}" stroke="{color}" stroke-width="{w*1.2}" stroke-linecap="round"/>')
    elif name == "coin-plus":
        g.append(f'<circle cx="{cx}" cy="{cy}" r="{8*s}" fill="none" stroke="{color}" stroke-width="{w}"/>')
        g.append(f'<path d="M {cx-3.6*s} {cy} h {7.2*s} M {cx} {cy-3.6*s} v {7.2*s}" stroke="{color}" stroke-width="{w*1.2}" stroke-linecap="round"/>')
    return "".join(g)


OPTIONS = [
    ("A", "tray-out", "tray-in", "Tray keluar / tray masuk", "Arah aksi jelas dari bentuk wadah, bukan dari diagonal."),
    ("B", "plane", "inbox", "Pesawat kertas / kotak masuk", "Metafora paling literal untuk kirim dan terima pesan nilai."),
    ("C", "arrow-up", "arrow-down", "Panah atas / panah bawah", "Paling cepat dibaca, tidak ada diagonal yang ambigu."),
    ("D", "coin-minus", "coin-plus", "Koin minus / koin plus", "Menempel ke objeknya: saldo berkurang dan bertambah."),
]


def tile(x, y, name, glyph):
    p = [f'<rect x="{x}" y="{y}" width="88" height="72" fill="{C["rail"]}"/>',
         f'<rect x="{x+22}" y="{y+8}" width="44" height="28" rx="14" fill="{C["acid"]}" '
         f'fill-opacity="0.12" stroke="{C["lineStrong"]}" stroke-opacity="0.55"/>',
         icon(glyph, x + 44, y + 22, C["acid"]),
         t(x + 44, y + 52, name, 11, C["acid"], 600, "middle")]
    return "".join(p)


def board():
    W, H = 1180, 780
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         f'<rect width="{W}" height="{H}" fill="{C["bg"]}"/>']
    p.append(t(96, 60, "CEN NAVBAR v2", 19, C["txt"], 700, spacing=1.1))
    p.append(t(96, 88, "Kirim dan Terima: four icon pairs, shown at real 22 px and at 3x. Pick one.", 12, C["muted"]))

    for i, (key, g1, g2, title, note) in enumerate(OPTIONS):
        y = 140 + i * 156
        p.append(t(96, y + 30, key, 13, C["acid"], 700))
        p.append(tile(128, y, "Kirim", g1))
        p.append(tile(228, y, "Terima", g2))

        zx = 372
        p.append(f'<rect x="{zx}" y="{y}" width="72" height="72" rx="10" fill="{C["card"]}" stroke="{C["line"]}"/>')
        p.append(icon(g1, zx + 36, y + 36, C["acid"], 2.0, 1.7))
        p.append(f'<rect x="{zx+80}" y="{y}" width="72" height="72" rx="10" fill="{C["card"]}" stroke="{C["line"]}"/>')
        p.append(icon(g2, zx + 116, y + 36, C["acid"], 2.0, 1.7))

        p.append(t(552, y + 26, title, 13, C["txt"], 600))
        p.append(t(552, y + 48, note, 11, C["sub"]))
        p.append(t(552, y + 68, "22 px grid, stroke 1.6, round caps", 10, C["muted"]))
        p.append(f'<line x1="96" y1="{y+96}" x2="{W-96}" y2="{y+96}" stroke="{C["line"]}" stroke-opacity="0.6"/>')

    p.append(t(96, 752, "Current icons in board 1 are diagonal arrows. Any pair here drops in without touching layout.", 11, C["muted"]))
    p.append("</svg>")
    return "\n".join(p)


with open(os.path.join(OUT, "04-icon-options.svg"), "w") as fh:
    fh.write(board())
print("wrote 04-icon-options.svg")
