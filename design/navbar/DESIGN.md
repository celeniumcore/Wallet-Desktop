# Navbar Redesign, Cenium Wallet v2

Scope: navbar (desktop rail + mobile bottom bar), logo lockup, motion. The logo bitmap is reused as is: `assets/cen_logo_circle.png` (1024x1024, RGBA). No redraw.

**Design Read:** wallet app chrome for desktop and Android users, dark, instrument-panel language, dial ENERGY 2 / RHYTHM 1 / MOTION 2. Chrome stays quiet so balances and actions dominate; motion is limited to state feedback.

---

## 1. Tokens

| Category | Token | Value | Reason |
|---|---|---|---|
| Color | bg | #070A08 | Page field, unchanged from CenTheme |
| | rail | #0E1310 | One step above page so the rail reads as chrome, not content |
| | line | #252E25 | Hairline between rail and content |
| | lineStrong | #344034 | Logo ring, pill border |
| | txt | #F2F4EE | Primary label |
| | sub | #9AA696 | Idle nav label, passes 4.5:1 on rail |
| | acid | #C9D98F | Single accent, marks the current destination and nothing else |
| Typography | family | Roboto | Same family the wallet already ships, no new dependency |
| | label | 11px / 600 (active), 500 (idle) | Legible at 88px rail width |
| | brand | 11px / 700, tracking 1.4 | Wordmark under the lockup |
| | mobile label | 10px / 600 (active), 500 (idle) | Fits five slots at 390px |
| Spacing | rail width | 88px | 44px logo + 22px side padding |
| | item height | 56px | Icon 22, gap 4, label 11 |
| | logo inset | 22px horizontal, 16px top | Optical centering against the item column |
| Radius | logo | full (circle) | Matches the circular mark |
| | pill | 14px | Soft, not a capsule |
| Motion | pill | 220ms cubic-bezier(0.2, 0, 0.8, 1) | Spatial continuity: the eye follows the indicator |
| | logo activation | 600ms, one shot | Confirms the destination change, then stops |
| | hover | 120ms ease-out | Pointer affordance |

---

## 2. Anatomy

**Logo lockup.** 44x44 container, circular clip, real logo bitmap at 36x36 centered, 1px `lineStrong` ring at 18% idle. Hover: ring 55%, scale 1.04, 120ms. On destination change: scale 1.0 to 0.96 to 1.02 to 1.0 over 600ms, ring to 55% at midpoint, then rest. One cycle only. A loop would compete with the balance figure for attention and never let the screen settle.

**Desktop rail.** 88px wide, background `rail`, hairline on the content edge. Logo lockup at 16px from the top, wordmark "CEN" 11px centered under it. Five items, 56px tall, 8px vertical gap, icon above an 11px label. Active item: 44x28 pill, `acid` at 12% fill with a `lineStrong` 55% border, icon and label in `acid`, label weight 600. Idle: icon and label `sub`, weight 500.

**Mobile bar.** 72px tall, background `rail`, 1px `line` on the top edge. Five equal slots, each 72x72 (well above the 44px target minimum). Active slot: 48x32 pill centered, same fill and border as the rail. Icon 22px, label 10px. Content above reserves 72px + safe-area inset so the last row is never hidden.

**Motion.** Pill travels between slots, 220ms. Because the pill is one widget that changes position rather than five separate highlights, the transition shows where the selection came from. Logo activation runs once per change. Hover only on pointer devices. On Android, `prefers-reduced-motion` equivalent (`MediaQuery.disableAnimations`) shortens both to zero.

---

## 3. Figma handoff

A Figma file cannot be created from this machine: the REST API is read-only for file content and there is no account session or token here. Two things are provided instead, both importable into the user's own Figma file:

1. `boards/01-rail.svg`, `02-mobile.svg`, `03-logo-motion.svg` are real vector boards, importable via File, Place image, or drag and drop. They carry exact geometry, so the Figma build is a transcription, not a re-interpretation.
2. `figma-plugin/` is a local development plugin. Plugins, Development, Import plugin from manifest, then run it: it builds the rail frame, the mobile bar, the three logo states, and a note with the motion values.

Colors and type are listed above for creation as Figma styles, so the plugin output and any hand-built frames stay on the same tokens.

---

## 4. Flutter implementation map

| Design element | Widget |
|---|---|
| Rail shell | `Container` width 88, `Row` + `Expanded` content |
| Logo lockup | `MouseRegion` + `AnimatedScale` + `ClipOval(Image.asset)` + ring `Container` |
| Active pill | `AnimatedAlign`/`AnimatedPositioned` driven by `_index` |
| Item | `InkWell` with `Semantics(selected:, button:)`, focus ring on `lineStrong` |
| Mobile bar | `SafeArea(top: false)` + `SizedBox(height: 72)` in `bottomNavigationBar` |
| Reduced motion | `MediaQuery.disableAnimationsOf(context)` shortens durations to `Duration.zero` |
