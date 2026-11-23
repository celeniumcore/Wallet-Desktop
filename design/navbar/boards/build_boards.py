#!/usr/bin/env python3
"""Generate the CEN navbar v2 design boards.

The logo is embedded as a data URI: rsvg-convert does not resolve a relative
href in this build, and a board without the real mark is not a design.
"""
import base64
import os

OUT = os.path.dirname(os.path.abspath(__file__))
LOGO = base64.b64encode(open(os.path.join(OUT, "logo-128.png"), "rb").read()).decode()

C = {
    "bg": "#070A08", "rail": "#0E1310", "card": "#11170F",
    "line": "#252E25", "lineStrong": "#344034", "txt": "#F2F4EE",
    "sub": "#9AA696", "muted": "#828F80", "acid": "#C9D98F",
}
FONT = "Roboto, Liberation Sans, sans-serif"
LABELS = ["Dompet", "Kirim", "Terima", "Riwayat", "Setelan"]
ICONS = ["wallet", "tray-out", "tray-in", "history", "settings"]


def t(x, y, s, size=12, fill=None, weight=400, anchor="start", spacing=0, opacity=1):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["txt"]}" text-anchor="{anchor}" letter-spacing="{spacing}" '
            f'opacity="{opacity}">{s}</text>')


def icon(name, cx, cy, color, sw=1.6):
    """Minimal 22 px glyphs drawn on the real nav geometry."""
    g = []
    if name == "wallet":
        g.append(f'<rect x="{cx-9}" y="{cy-6}" width="18" height="12.5" rx="3" fill="none" stroke="{color}" stroke-width="{sw}"/>')
        g.append(f'<circle cx="{cx+4.6}" cy="{cy+0.2}" r="1.5" fill="{color}"/>')
    elif name == "send":
        g.append(f'<path d="M {cx-6} {cy+6} L {cx+6} {cy-6} M {cx-0.6} {cy-6} L {cx+6} {cy-6} L {cx+6} {cy+0.6}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "receive":
        g.append(f'<path d="M {cx+6} {cy-6} L {cx-6} {cy+6} M {cx+0.6} {cy+6} L {cx-6} {cy+6} L {cx-6} {cy+0.6}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "tray-out":
        g.append(f'<path d="M {cx-7} {cy+1} v 4 a 2 2 0 0 0 2 2 h 10 a 2 2 0 0 0 2 -2 v -4" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round"/>')
        g.append(f'<path d="M {cx} {cy+2} V {cy-7} M {cx-3.6} {cy-3.4} L {cx} {cy-7.2} L {cx+3.6} {cy-3.4}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "tray-in":
        g.append(f'<path d="M {cx-7} {cy+1} v 4 a 2 2 0 0 0 2 2 h 10 a 2 2 0 0 0 2 -2 v -4" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round"/>')
        g.append(f'<path d="M {cx} {cy-7} V {cy+2} M {cx-3.6} {cy-1.6} L {cx} {cy+2.2} L {cx+3.6} {cy-1.6}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "history":
        g.append(f'<circle cx="{cx}" cy="{cy}" r="7.4" fill="none" stroke="{color}" stroke-width="{sw}"/>')
        g.append(f'<path d="M {cx} {cy-4.4} L {cx} {cy} L {cx+3.4} {cy+2.2}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "settings":
        g.append(f'<circle cx="{cx}" cy="{cy}" r="3.4" fill="none" stroke="{color}" stroke-width="{sw}"/>')
        g.append(f'<circle cx="{cx}" cy="{cy}" r="7.2" fill="none" stroke="{color}" stroke-width="{sw}" stroke-dasharray="2.6 3.4"/>')
    return "".join(g)


def logo(x, y, ring=0.18, scale=1.0, cid="l"):
    s = 44 * scale
    cx, cy = x + 22, y + 22
    img = 36 * scale
    return (
        f'<g><clipPath id="clip{cid}"><circle cx="{cx}" cy="{cy}" r="{s/2}"/></clipPath>'
        f'<circle cx="{cx}" cy="{cy}" r="{s/2}" fill="{C["card"]}"/>'
        f'<image x="{cx-img/2}" y="{cy-img/2}" width="{img}" height="{img}" '
        f'href="data:image/png;base64,{LOGO}" clip-path="url(#clip{cid})" preserveAspectRatio="xMidYMid slice"/>'
        f'<circle cx="{cx}" cy="{cy}" r="{s/2-0.5}" fill="none" stroke="{C["lineStrong"]}" '
        f'stroke-width="1" opacity="{ring}"/></g>'
    )


def rail_board():
    W, H = 1180, 760
    rx, ry, rw, rh = 96, 150, 88, 520
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         f'<rect width="{W}" height="{H}" fill="{C["bg"]}"/>']
    p.append(t(96, 60, "CEN NAVBAR v2", 19, C["txt"], 700, spacing=1.1))
    p.append(t(96, 88, "Desktop rail, 88 px. Logo lockup and active pill as specified in DESIGN.md.", 12, C["muted"]))

    p.append(f'<rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" fill="{C["rail"]}"/>')
    p.append(f'<line x1="{rx+rw}" y1="{ry}" x2="{rx+rw}" y2="{ry+rh}" stroke="{C["line"]}"/>')

    p.append(logo(rx + 22, ry + 16, 0.45, 1.0, "rail"))
    p.append(t(rx + rw / 2, ry + 76, "CEN", 11, C["txt"], 700, "middle", 1.4))

    for i, lab in enumerate(LABELS):
        active = i == 0
        top = ry + 104 + i * 72
        if active:
            p.append(f'<rect x="{rx+22}" y="{top}" width="44" height="28" rx="14" '
                     f'fill="{C["acid"]}" fill-opacity="0.12" stroke="{C["lineStrong"]}" stroke-opacity="0.55"/>')
        col = C["acid"] if active else C["sub"]
        p.append(icon(ICONS[i], rx + 44, top + 14, col))
        p.append(t(rx + rw / 2, top + 44, lab, 11, col, 600 if active else 500, "middle"))

    sx = 300
    p.append(t(sx, 170, "LOGO LOCKUP", 11, C["acid"], 700, spacing=1.0))
    for i, line in enumerate([
        "44 x 44 container, circular clip",
        "bitmap at 36 x 36, centered",
        "ring 1 px #344034 at 18% idle, 55% on hover",
        "asset: assets/cen_logo_circle.png, not redrawn",
    ]):
        p.append(t(sx, 194 + i * 22, line, 12, C["sub"]))

    p.append(t(sx, 320, "ITEM", 11, C["acid"], 700, spacing=1.0))
    for i, line in enumerate([
        "56 px tall, 72 px pitch, icon 22 above 11 px label",
        "idle: icon and label #9AA696, weight 500",
        "active: #C9D98F, weight 600, pill 44 x 28 r14",
        "pill fill acid at 12%, border lineStrong at 55%",
        "target width 88 px, whole row tappable",
    ]):
        p.append(t(sx, 344 + i * 22, line, 12, C["sub"]))

    p.append(t(sx, 486, "MOTION", 11, C["acid"], 700, spacing=1.0))
    for i, line in enumerate([
        "pill travels between slots, 220 ms",
        "cubic-bezier(0.2, 0, 0.8, 1), one indicator, not five",
        "logo activation once per route change, 600 ms",
        "hover 120 ms, pointer devices only",
    ]):
        p.append(t(sx, 510 + i * 22, line, 12, C["sub"]))

    p.append(f'<line x1="{rx-26}" y1="{ry}" x2="{rx-26}" y2="{ry+rh}" stroke="{C["muted"]}" stroke-dasharray="3 3" opacity="0.5"/>')
    p.append(t(rx - 32, ry + rh / 2, "520", 10, C["muted"], 500, "middle"))
    p.append(t(96, ry + rh + 36, "Board 1 of 3. Rendered from design/navbar/boards/build_boards.py.", 11, C["muted"]))
    p.append("</svg>")
    return "\n".join(p)


def mobile_board():
    W, H = 1180, 560
    bx, by, bw, bh = 96, 300, 390, 72
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         f'<rect width="{W}" height="{H}" fill="{C["bg"]}"/>']
    p.append(t(96, 60, "CEN NAVBAR v2", 19, C["txt"], 700, spacing=1.1))
    p.append(t(96, 88, "Mobile bottom bar, 390 px reference width, five slots, one travelling pill.", 12, C["muted"]))

    p.append(f'<rect x="{bx-1}" y="{by-56}" width="{bw+2}" height="{bh+56}" rx="14" fill="{C["card"]}" stroke="{C["line"]}"/>')
    p.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" fill="{C["rail"]}"/>')
    p.append(f'<line x1="{bx}" y1="{by}" x2="{bx+bw}" y2="{by}" stroke="{C["line"]}"/>')
    slot = bw / 5
    for i, lab in enumerate(LABELS):
        active = i == 2
        x0 = bx + i * slot
        if active:
            p.append(f'<rect x="{x0+(slot-48)/2}" y="{by+8}" width="48" height="32" rx="14" '
                     f'fill="{C["acid"]}" fill-opacity="0.12" stroke="{C["lineStrong"]}" stroke-opacity="0.55"/>')
        col = C["acid"] if active else C["sub"]
        p.append(icon(ICONS[i], x0 + slot / 2, by + 18, col))
        p.append(t(x0 + slot / 2, by + 50, lab, 10, col, 600 if active else 500, "middle"))

    p.append(f'<rect x="{bx+slot+(slot-48)/2}" y="{by+8}" width="48" height="32" rx="14" fill="none" '
             f'stroke="{C["acid"]}" stroke-opacity="0.40" stroke-dasharray="4 4"/>')

    sx = 540
    p.append(t(sx, 180, "BAR", 11, C["acid"], 700, spacing=1.0))
    for i, line in enumerate([
        "72 px tall, background #0E1310, hairline top",
        "five equal slots, 78 px each at 390 px width",
        "each slot is a 72 x 72 target, above the 44 px minimum",
        "content above reserves 72 px plus safe-area inset",
    ]):
        p.append(t(sx, 204 + i * 22, line, 12, C["sub"]))

    p.append(t(sx, 336, "ACTIVE STATE", 11, C["acid"], 700, spacing=1.0))
    for i, line in enumerate([
        "pill 48 x 32 r14, acid 12%, border lineStrong 55%",
        "icon and label in acid, weight 600",
        "dashed outline shows where the pill came from",
        "travel 220 ms, same curve as the rail",
    ]):
        p.append(t(sx, 360 + i * 22, line, 12, C["sub"]))

    p.append(t(96, 500, "Board 2 of 3. Labels in Indonesian, matching the current app strings.", 11, C["muted"]))
    p.append("</svg>")
    return "\n".join(p)


def motion_board():
    W, H = 1180, 520
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         f'<rect width="{W}" height="{H}" fill="{C["bg"]}"/>']
    p.append(t(96, 60, "CEN NAVBAR v2", 19, C["txt"], 700, spacing=1.1))
    p.append(t(96, 88, "Logo activation: one 600 ms cycle when the destination changes, then rest.", 12, C["muted"]))
    frames = [("1.00", "0 ms", "rest", 0.18), ("0.96", "150 ms", "compress", 0.34),
              ("1.02", "360 ms", "peak", 0.55), ("1.00", "600 ms", "rest", 0.18)]
    for i, (sl, tm, lab, ring) in enumerate(frames):
        x, y = 110 + i * 250, 150
        p.append(logo(x, y, ring, 1.0, f"m{i}"))
        p.append(f'<circle cx="{x+22}" cy="{y+22}" r="34" fill="none" stroke="{C["acid"]}" stroke-opacity="0.10"/>')
        p.append(t(x + 22, y + 92, f"scale {sl}", 12, C["txt"], 600, "middle"))
        p.append(t(x + 22, y + 112, tm, 11, C["acid"], 600, "middle", 0.8))
        p.append(t(x + 22, y + 132, lab, 10, C["muted"], 400, "middle"))

    cx, cy = 110, 380
    p.append(f'<line x1="{cx}" y1="{cy+30}" x2="{cx+342}" y2="{cy+30}" stroke="{C["line"]}"/>')
    p.append(f'<line x1="{cx}" y1="{cy-26}" x2="{cx}" y2="{cy+30}" stroke="{C["line"]}"/>')
    p.append(f'<path d="M {cx} {cy+30} C {cx+40} {cy+30}, {cx+70} {cy+16}, {cx+108} {cy+16} '
             f'C {cx+150} {cy+16}, {cx+196} {cy-16}, {cx+240} {cy-16} '
             f'C {cx+284} {cy-16}, {cx+312} {cy+30}, {cx+342} {cy+30}" '
             f'fill="none" stroke="{C["acid"]}" stroke-width="2" opacity="0.85"/>')
    p.append(t(cx + 356, cy + 34, "600 ms", 11, C["sub"]))
    p.append(t(cx, cy + 62, "Pointer hover: 120 ms ease-out, scale 1.04, ring 55%. Reduced motion: duration 0.", 11, C["sub"]))
    p.append(t(96, 496, "Board 3 of 3. No idle loop: the balance figure stays the loudest thing on screen.", 11, C["muted"]))
    p.append("</svg>")
    return "\n".join(p)


for name, svg in [("01-rail", rail_board()), ("02-mobile", mobile_board()), ("03-logo-motion", motion_board())]:
    with open(os.path.join(OUT, f"{name}.svg"), "w") as fh:
        fh.write(svg)
    print("wrote", name)
