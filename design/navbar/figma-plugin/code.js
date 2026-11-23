/* CEN Navbar Generator — Figma plugin
 * Run: Plugins → Development → Load unpacked plugin → select this folder.
 * Generates Desktop Rail + Mobile Bar frames with logo variants and Smart Animate.
 */

figma.showUI(__html__, { visible: false });

const TOKENS = {
  bg: { r: 7 / 255, g: 10 / 255, b: 8 / 255 },
  bg1: { r: 14 / 255, g: 19 / 255, b: 16 / 255 },
  bg2: { r: 17 / 255, g: 23 / 255, b: 15 / 255 },
  line: { r: 37 / 255, g: 46 / 255, b: 37 / 255 },
  lineStrong: { r: 52 / 255, g: 64 / 255, b: 52 / 255 },
  txt: { r: 242 / 255, g: 244 / 255, b: 238 / 255 },
  sub: { r: 154 / 255, g: 166 / 255, b: 150 / 255 },
  muted: { r: 130 / 255, g: 143 / 255, b: 128 / 255 },
  acid: { r: 201 / 255, g: 217 / 255, b: 143 / 255 },
};

const FONT_REG = { family: "Roboto", style: "Regular" };
const FONT_MED = { family: "Roboto", style: "Medium" };
const FONT_SEMI = { family: "Roboto", style: "SemiBold" };
const FONT_BOLD = { family: "Roboto", style: "Bold" };

async function loadFonts() {
  const fonts = [FONT_REG, FONT_MED, FONT_SEMI, FONT_BOLD];
  for (const f of fonts) {
    try { await figma.loadFontAsync(f); } catch (e) { /* fallback to Inter */ }
  }
}

function solid(c, a = 1) {
  return [{ type: "SOLID", color: c, opacity: a }];
}

function stroke(c, a = 1, w = 1) {
  return { strokes: solid(c, a), strokeWeight: w, strokeAlign: "INSIDE" };
}

function makeRect(name, w, h, fill, corner = 0) {
  const r = figma.createRectangle();
  r.name = name;
  r.resize(w, h);
  r.fills = fill ? solid(fill.c, fill.a ?? 1) : [];
  r.cornerRadius = corner;
  return r;
}

function makeText(name, str, size, font, color, alignH = "CENTER") {
  const t = figma.createText();
  t.name = name;
  t.fontName = font;
  t.fontSize = size;
  t.characters = str;
  t.fills = solid(color);
  t.textAlignHorizontal = alignH;
  return t;
}

function makeEllipse(name, size, fill, s) {
  const e = figma.createEllipse();
  e.name = name;
  e.resize(size, size);
  e.fills = fill ? solid(fill.c, fill.a ?? 1) : [];
  if (s) { e.strokes = solid(s.c, s.a ?? 1); e.strokeWeight = s.w ?? 1; e.strokeAlign = "INSIDE"; }
  return e;
}

function makeFrame(name, w, h, fill, clip = false) {
  const f = figma.createFrame();
  f.name = name;
  f.resize(w, h);
  f.fills = fill ? solid(fill.c, fill.a ?? 1) : [];
  f.clipsContent = clip;
  return f;
}

function iconCircle(parent, x, y, color, filled) {
  const g = figma.createFrame();
  g.name = "icon";
  g.resize(22, 22);
  g.x = x; g.y = y;
  g.fills = [];
  g.clipsContent = false;
  const c = makeEllipse("glyph", 18, filled ? { c: color } : null, filled ? null : { c: color, a: 1, w: 1.8 });
  c.x = 2; c.y = 2;
  g.appendChild(c);
  parent.appendChild(g);
  return g;
}

function buildRailItem(label, active, x, y) {
  const w = 72, h = 56;
  const f = makeFrame(label, w, h, null);
  f.x = x; f.y = y;

  if (active) {
    const pill = makeRect("pill", 44, 28, { c: TOKENS.acid, a: 0.12 }, 14);
    pill.x = 14; pill.y = 4;
    pill.strokes = solid(TOKENS.lineStrong, 0.55);
    pill.strokeWeight = 1; pill.strokeAlign = "INSIDE";
    f.appendChild(pill);
  }

  const ic = iconCircle(f, 25, active ? 7 : 8, active ? TOKENS.acid : TOKENS.sub, active);
  const t = makeText("label", label, 11, active ? FONT_SEMI : FONT_MED, active ? TOKENS.acid : TOKENS.sub);
  t.x = (w - t.width) / 2;
  t.y = 34;
  f.appendChild(t);
  return f;
}

function buildLogo(size, state) {
  const outer = makeFrame("Logo/" + state, 44, 44, null);
  outer.cornerRadius = 22;
  outer.clipsContent = true;

  const ringAlpha = state === "Hover" ? 0.6 : state === "Active" ? 0.45 : 0.18;
  const ring = makeEllipse("ring", 44, null, { c: TOKENS.lineStrong, a: ringAlpha, w: 1 });
  outer.appendChild(ring);

  // Placeholder circle for logo image (user replaces fill with cen_logo_circle.png)
  const img = makeEllipse("logo-image", 36, { c: TOKENS.bg2 }, null);
  img.x = 4; img.y = 4;
  img.fills = solid(TOKENS.bg2);
  // Add a subtle center mark to indicate image slot
  const dot = makeEllipse("center", 6, { c: TOKENS.acid, a: 0.7 });
  dot.x = 19; dot.y = 19;
  outer.appendChild(img);
  outer.appendChild(dot);

  const hint = makeText("hint", "CEN", 8, FONT_BOLD, TOKENS.txt);
  hint.x = (44 - hint.width) / 2; hint.y = 16;
  hint.opacity = 0.0; // hidden, just metadata
  outer.appendChild(hint);

  return outer;
}

async function generate() {
  await loadFonts();

  const page = figma.createPage();
  page.name = "CEN Navbar v2";
  figma.currentPage = page;

  // Desktop Rail
  const rail = makeFrame("Desktop / Rail", 88, 640, { c: TOKENS.bg1 });
  rail.x = 80; rail.y = 80;
  const railBorder = makeRect("rail-border", 1, 640, { c: TOKENS.line });
  railBorder.x = 87; railBorder.y = 0;
  rail.appendChild(railBorder);

  const logo = buildLogo(44, "Active");
  logo.x = 22; logo.y = 16;
  rail.appendChild(logo);

  const cenLabel = makeText("CEN", "CEN", 11, FONT_BOLD, TOKENS.txt);
  cenLabel.x = (88 - cenLabel.width) / 2; cenLabel.y = 64;
  rail.appendChild(cenLabel);

  const items = ["Dompet", "Kirim", "Terima", "Riwayat", "Setelan"];
  const activeIdx = 0;
  items.forEach((lab, i) => {
    const it = buildRailItem(lab, i === activeIdx, 8, 108 + i * 64);
    rail.appendChild(it);
  });
  page.appendChild(rail);

  // Mobile Bar
  const mobile = makeFrame("Mobile / BottomBar", 390, 72, { c: TOKENS.bg1 });
  mobile.x = 240; mobile.y = 80;
  const topLine = makeRect("top-line", 390, 1, { c: TOKENS.line });
  mobile.appendChild(topLine);
  const mLabels = ["Dompet", "Kirim", "Terima", "Riwayat", "Setelan"];
  const mActive = 2;
  const slotW = 390 / 5;
  mLabels.forEach((lab, i) => {
    const active = i === mActive;
    const slot = makeFrame(lab, slotW, 72, null);
    slot.x = i * slotW; slot.y = 0;
    if (active) {
      const pill = makeRect("pill", 48, 32, { c: TOKENS.acid, a: 0.12 }, 14);
      pill.x = (slotW - 48) / 2; pill.y = 8;
      pill.strokes = solid(TOKENS.lineStrong, 0.55); pill.strokeWeight = 1; pill.strokeAlign = "INSIDE";
      slot.appendChild(pill);
    }
    const ic = iconCircle(slot, (slotW - 22) / 2, active ? 13 : 14, active ? TOKENS.acid : TOKENS.sub, active);
    const t = makeText("label", lab, 10, active ? FONT_SEMI : FONT_MED, active ? TOKENS.acid : TOKENS.sub);
    t.x = (slotW - t.width) / 2; t.y = 42;
    slot.appendChild(t);
    mobile.appendChild(slot);
  });
  page.appendChild(mobile);

  // Logo variants
  const compRow = makeFrame("Logo Variants", 200, 60, null);
  compRow.x = 80; compRow.y = 760;
  ["Default", "Hover", "Active"].forEach((s, i) => {
    const v = buildLogo(44, s);
    v.x = i * 60; v.y = 0;
    compRow.appendChild(v);
    const lbl = makeText("lbl-" + s, s, 9, FONT_MED, TOKENS.sub);
    lbl.x = i * 60 + (44 - lbl.width) / 2; lbl.y = 48;
    compRow.appendChild(lbl);
  });
  page.appendChild(compRow);

  // Notes
  const note = makeText(
    "note",
    "CEN Navbar v2 — replace 'logo-image' fills with cen_logo_circle.png (1024x1024). Smart Animate: 220ms cubic-bezier(0.2,0,0.8,1). Logo breathe: 4s loop scale 0.96-1.02.",
    11, FONT_REG, TOKENS.muted, "LEFT"
  );
  note.x = 80; note.y = 840; note.resize(560, 40); note.textAutoResize = "HEIGHT";
  page.appendChild(note);

  figma.viewport.scrollAndZoomIntoView([rail, mobile, compRow, note]);
  figma.closePlugin("CEN Navbar v2 generated. Replace logo-image fills with cen_logo_circle.png.");
}

generate();