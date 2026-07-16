# Nebula Stats — Design Implementation Spec

Source: `design/nebula-stats.dc.html` (claude.ai Design export, design-canvas document).

## Scope of this spec

The design canvas has two turns. **Turn 1** offered three Dashboard takes (1a, 1b, 1c); **option 1a was committed** ("2-col glass grid, CPU orb hero card"). **Turn 2** builds the final committed system on top of 1a and is the source of truth for everything here. Options **1b** ("instrument cluster", cyan-biased) and **1c** ("console dense", telemetry rows) were **NOT committed and are ignored** in this spec.

The final design contains:

| ID | Content |
|----|---------|
| 1a | Dashboard (iPhone, committed) |
| 2a | UI kit — color tokens, type scale, spacing/radii, GaugeOrb states, StatCard/RingChart/LineChart/BarRow, buttons, pills, list rows, permission-denied card |
| 2b | Onboarding screen |
| 2c | Performance tab |
| 2d | Network tab — Wi-Fi hidden state, plus revealed-Wi-Fi card and location-denied card variants |
| 2e | Speed test — running screen + results screen |
| 2f | Display & Device tab |
| 2g | Settings bottom sheet |
| 2h | iPad split view (Dashboard + Performance, sidebar navigation, 1024×1366) |
| 2i | App icon (180/120/60 pt renditions) |

Target frame in the mockups: iPhone 390×844 pt (mock hint-size 410×880), dark appearance only. The app is dark-theme-only — do not implement a light mode.

---

## 1. Color tokens

### 1.1 Background

The app background ("gradient.nebula") is a layered stack painted on `surface.base`, identical on every screen (bottom layer listed last):

1. Starfield dots (see §3.4) — topmost background layer
2. Radial gradient A (violet): `radial-gradient(120% 90% at 85% -10%, #2A1B54 0%, rgba(42,27,84,0) 55%)` — violet bloom from top-right, off-screen above
3. Radial gradient B (deep blue): `radial-gradient(110% 80% at -15% 35%, #122B4A 0%, rgba(18,43,74,0) 60%)` — blue bloom from left edge at ~35% height
4. Radial gradient C (indigo): `radial-gradient(140% 100% at 50% 115%, #1B1440 0%, rgba(27,20,64,0) 55%)` — indigo bloom from bottom-center, off-screen below
5. Solid fill: `#0B0B1E`

**Speed-test screens (2e) use a different bloom pair** over the same base:
- `radial-gradient(130% 90% at 50% -20%, #12315A 0%, rgba(18,49,90,0) 60%)` (blue, top-center)
- `radial-gradient(120% 90% at 100% 100%, #241650 0%, rgba(36,22,80,0) 55%)` (violet, bottom-right)

**Settings sheet (2g)** dims the background behind the sheet with a scrim: `linear-gradient(rgba(4,4,12,.55), rgba(4,4,12,.75))` on top of the nebula gradient.

| Token | Value |
|---|---|
| `surface.base` | `#0B0B1E` |
| `nebula.violet` | `#2A1B54` |
| `nebula.blue` | `#122B4A` |
| `nebula.indigo` | `#1B1440` |
| `nebula.speedBlue` | `#12315A` |
| `nebula.speedViolet` | `#241650` |

### 1.2 Surfaces

| Token | Value | Use |
|---|---|---|
| `surface.card` | `rgba(255,255,255,0.04)` | standard card fill (some kit samples use 0.035/0.03; use 0.04) |
| `surface.cardHero` | `rgba(140,120,255,0.06)` | hero/emphasis cards (CPU hero, Speed-test CTA row, Live-frame-rate card) |
| `surface.cardFaint` | `rgba(255,255,255,0.03)` | de-emphasized cards (about box, denied state) |
| `surface.tabBar` | `rgba(255,255,255,0.05)` + `backdrop blur 20` | floating tab bar |
| `surface.sheet` | `rgba(18,18,38,0.92)` + `backdrop blur 24` | settings bottom sheet |
| `surface.sidebar` (iPad) | `rgba(10,10,26,0.5)` | iPad sidebar column |
| `surface.segment` | `rgba(255,255,255,0.06)` | segmented-control track |
| `surface.trackBar` | `rgba(255,255,255,0.06)`–`0.08` | progress/bar chart track (0.06 thin bars, 0.07–0.08 memory bars) |
| `surface.ringTrack` | `rgba(255,255,255,0.08)` | gauge/ring background track (large gauge in 1b uses .06/.07; use 0.08) |

### 1.3 Borders / strokes

Card borders are always **1px**. Border color is themed to the card's accent:

| Token | Value |
|---|---|
| `border.neutral` | `rgba(255,255,255,0.10)` |
| `border.neutralFaint` | `rgba(255,255,255,0.08)` |
| `border.violet` | `rgba(167,139,250,0.20)` — emphasized: `0.24`; hero: `0.28`; iPad selected nav: `0.30` |
| `border.cyan` | `rgba(125,211,252,0.20)` (cards) / `rgba(56,189,248,0.24–0.35)` (Wi-Fi card, cyan buttons) |
| `border.green` | `rgba(74,222,128,0.20)` — result card: `0.24`; pill: `0.30` |
| `border.warning` | `rgba(251,191,36,0.30)` |
| `border.critical` | `rgba(251,113,133,0.35)` (button) / `0.30` (pill) |
| `border.buttonSecondary` | `rgba(255,255,255,0.18)` |
| `divider` (list rows, card footers) | `rgba(255,255,255,0.06)` — footer separators sometimes `0.07` |
| `border.sidebarSeparator` (iPad) | `rgba(255,255,255,0.07)` |

### 1.4 Text

| Token | Value | Use |
|---|---|---|
| `text.primary` | `#F2F2FA` | values, titles, row values |
| `text.primaryHero` | `#F4FAFF` | huge hero numerals (speed test 412.6, FPS 120) |
| `text.body` | `#C9CBE4` | body labels, list-row left labels, secondary button label |
| `text.appBody` | `#EAEAF5` | default screen foreground (inherited) |
| `text.secondary` | `#8F8FB8` | units, sub-copy, secondary values |
| `text.micro` | `#9FA6D8` | micro-labels / section eyebrows |
| `text.muted` | `#7C86B8` | footnotes, chart footers, mono metadata |
| `text.disabled` | `#5E648F` | inactive values ("--"), core labels, axis labels, dot separators |
| `text.tabInactive` | `#6B7099` | inactive tab icon + label |
| `text.tabActiveViolet` | `#C4B5FD` | active tab label (violet tabs) |
| `text.tabActiveCyan` | `#7DD3FC` | active Network tab label |
| `text.iPadNavActive` | `#EDE9FE` | iPad selected sidebar label |
| `text.iPadNavInactive` | `#A8ABCB` | iPad sidebar labels |

### 1.5 Accents & states

| Token | Value | Use |
|---|---|---|
| `accent.violet` | `#A78BFA` | CPU / performance, P-core bars, storage ring |
| `accent.violetBright` | `#C4B5FD` | glow dots, active tab tint, legend "Apps" |
| `accent.cyan` | `#38BDF8` | network, memory bar, downlink sparkline |
| `accent.cyanBright` | `#7DD3FC` | E-core bars, upload line, cyan-button label, links ("Done", "Privacy policy") |
| `accent.cyanDeep` | `#22D3EE` | gradient start stop |
| `accent.cyanIce` | `#BAE6FD` | speed-gauge tip dot |
| `accent.aurora` (green) | `#4ADE80` | success, LIVE indicator, download plot, battery, charging |
| `accent.magenta` | `#F472B6` | warning-gradient end stop |
| `state.warning` | `#FBBF24` | warning text/pill/gauge |
| `state.critical` | `#FB7185` | critical text/pill/gauge/destructive button |

### 1.6 Gradients

| Token | Definition |
|---|---|
| `gradient.gauge` | linear 135° (SVG: bottom-left→top-right), `#38BDF8 → #A78BFA` (3-stop version for logo/kit swatch: `#22D3EE → #38BDF8 (50%) → #A78BFA`) |
| `gradient.gaugeWarning` | `#FBBF24 → #F472B6` (bottom-left→top-right) |
| `gradient.button` | `linear-gradient(135deg, #8B5CF6, #D946EF)` — primary CTA |
| `gradient.segmentSelected` | `linear-gradient(135deg, #7DD3FC, #A78BFA)`, label color `#0B0B1E` |
| `gradient.memoryFill` | `linear-gradient(90deg, #38BDF8, #7DD3FC)` |
| `gradient.memoryWarning` | `linear-gradient(90deg, #FBBF24, #F472B6)` |
| `gradient.speedGauge` | left→right `#22D3EE → #38BDF8 (60%) → #A78BFA` |
| `gradient.chartFillViolet` | vertical `rgba(167,139,250,.35) → rgba(167,139,250,0)` |
| `gradient.chartFillGreen` | vertical `rgba(74,222,128,.30) → rgba(74,222,128,0)` |

Tinted fills for pills/buttons (fill / border / text):
- Green pill: `rgba(74,222,128,.12)` / `rgba(74,222,128,.30)` / `#4ADE80`
- Amber pill: `rgba(251,191,36,.12)` / `rgba(251,191,36,.30)` / `#FBBF24`
- Rose pill: `rgba(251,113,133,.12)` / `rgba(251,113,133,.30)` / `#FB7185`
- Neutral pill: `rgba(255,255,255,.06)` / `rgba(255,255,255,.15)` / `#8F8FB8`
- Cyan button: `rgba(56,189,248,.08)` / `rgba(56,189,248,.35)` / `#7DD3FC`
- Rose (destructive) button: `rgba(251,113,133,.08)` / `rgba(251,113,133,.35)` / `#FB7185`

---

## 2. Typography

Two families: **SF Pro** (system default) for UI text and **SF Mono** (`ui-monospace`) for every numeric readout, value, address, and metadata line. Rule of thumb: if it's a number, an address, or telemetry metadata → SF Mono.

| Role | Family | Size | Weight | Tracking / case | Color | Used for |
|---|---|---|---|---|---|---|
| `type.hero` | SF Mono | 56 (speed test uses 58; FPS card 50) | semibold (600) | normal | `#F4FAFF` w/ glow | hero readouts (412.6, 120 FPS) |
| `type.heroOrb` | SF Mono | 28–30 (iPad 30) | 600 | normal | `#F2F2FA` | number inside GaugeOrb |
| `type.value` | SF Mono | 26 (compact cards 22–24; iPad 32) | 600 | normal | `#F2F2FA` | card values (3.1, 86.1, 78) |
| `type.valueUnit` | SF Pro | 11 (10–13 by context) | 400 | normal | `#8F8FB8` | unit suffix ("/ 8 GB", "Mbps", "%", "FPS") |
| `type.title` | SF Pro | 20 (iPad 26) | 700 | +0.5 on wordmark | `#F2F2FA`/inherit | nav titles ("Performance", "Network") |
| `type.titleSheet` | SF Pro | 18 | 700 | normal | inherit | "Settings" sheet title |
| `type.onboardTitle` | SF Pro | 30 | 700 | +0.5 | inherit | "Nebula Stats" |
| `type.onboardTagline` | SF Pro | 11 | 600 | +3, UPPERCASE | `#9FA6D8` | "MISSION CONTROL FOR YOUR DEVICE" |
| `type.body` | SF Pro | 13 | 400 | normal | `#C9CBE4` | body labels; 12 in list rows on phone |
| `type.bodyStrong` | SF Pro | 13–14 | 600 | normal | `#F2F2FA` | feature titles, "Speed test", "Location is off" |
| `type.caption` | SF Pro | 11–12 | 400 | normal | `#8F8FB8` | sub-copy, feature descriptions (line-height 1.5) |
| `type.footnote` | SF Pro | 10 | 400 | normal | `#7C86B8` | "Requires location access · used once, never stored" |
| `type.micro` | SF Pro | 10 (in-card 9; iPad 10–11) | 600 | +2.5 (in-card +2.2), UPPERCASE | `#9FA6D8` | card eyebrows: "CPU LOAD", "MEMORY" |
| `type.microKit` | SF Pro | 10 | 700 | +3, UPPERCASE | `#9FA6D8` | kit section headers |
| `type.pill` | SF Pro | 9 (iPad 10) | 700 | +1.5, UPPERCASE | state color | status pills |
| `type.buttonLarge` | SF Pro | 14–15 | 600 | normal | per style | CTAs |
| `type.buttonSmall` | SF Pro | 12–13 | 600 | normal | per style | "Run test", "Open Settings", segments |
| `type.tab` | SF Pro | 8.5 | 600 active / 500 inactive | +1, UPPERCASE | see §6 | tab labels |
| `type.monoMeta` | SF Mono | 10 (9–11 by context) | 400–600 | +1 where noted, UPPERCASE for telemetry | `#7C86B8` | footers ("A17 PRO", "SESSION ▼ 4.2 GB"), "● LIVE · 1s" (green), timestamps |
| `type.monoValueRow` | SF Mono | 12 | 400 | normal | `#F2F2FA` | list-row right values (IP, model, uptime) |
| `type.monoLegend` | SF Mono | 9 (iPad 10–12) | 400 | normal | series color | ring/bar legends ("■ APPS 115 GB") |
| `type.coreLabel` | SF Mono | 8 (iPad 10) | 400 | normal | `#5E648F` label / `#9FA6D8` value | per-core rows ("P1", "64") |
| `type.axisLabel` | SF Mono | 9 | 400 | normal | `#5E648F` | speed-gauge scale (0 / 500 / 1000) |
| `type.gaugeUnit` | SF Pro | 9–10 | 600 | +2 | `#8F8FB8` (state color when warning/critical) | "%" under orb number |
| `type.gaugeCaption` | SF Pro | 8 | 600 | +2 | `#9FA6D8` (state color in warning/critical) | "CPU LOAD" under orb |

SwiftUI mapping: use `.system(size:weight:design:)` with `design: .monospaced` for the SF Mono roles and `.default` otherwise; apply `.kerning()` for tracked labels and `.textCase(.uppercase)`.

---

## 3. Shape & effects

### 3.1 Spacing scale & radii (from UI kit)

- `space.xs 4`, `space.s 8`, `space.m 12`, `space.l 16`, `space.xl 20`
- `radius.card 20` (iPad cards 22; small stat tiles in speed test 16; settings-sheet inner groups 16)
- `radius.button 14` (small buttons 12; segments: track 12, selected 9)
- `radius.pill 99` (capsule)
- Sheet top corners: 28; tab bar: 24; iPad nav row: 12; bar tracks: height/2 (2–4)

### 3.2 Standard card recipe

- Fill `surface.card`, radius 20, border 1px in themed color (§1.3), internal padding 16 (iPad 20–22, hero 18–26).
- Dashboard cards additionally have `backdrop blur 14` (glassy; `.ultraThinMaterial`-like at very low white overlay).
- Hero/emphasis cards add an outer glow shadow:
  - CPU hero (dashboard): `0 0 28px rgba(139,92,246,.18)` + inner top highlight `inset 0 1px 0 rgba(255,255,255,.08)`
  - Performance CPU card: `0 0 24px rgba(139,92,246,.12)`
  - Wi-Fi card: `0 0 24px rgba(56,189,248,.10)`
  - Speed-test CTA row / Live-frame-rate card: `0 0 20–24px rgba(139,92,246,.14)`
  - Speed result card: `0 0 26px rgba(74,222,128,.10)`
  - Warning card: `0 0 18px rgba(251,191,36,.10)`
- Settings sheet: `box-shadow 0 -8px 40px rgba(0,0,0,.5)`, border violet .20 (no bottom border).

### 3.3 Glow effects (drop shadows on strokes/dots)

| Element | Glow |
|---|---|
| GaugeOrb progress stroke | `drop-shadow(0 0 6px rgba(139,92,246,.7))`; warning `rgba(251,191,36,.7)`; critical `0 0 8px rgba(251,113,133,.8)` |
| Orb tip dot | `drop-shadow(0 0 5px #A78BFA)` |
| Sparkline strokes | `0 0 3px` accent at .6–.7 alpha (violet chart line `0 0 4px rgba(167,139,250,.7)`) |
| Sparkline end dot | `0 0 4–5px` accent |
| Bar fills (per-core, memory) | `0 0 5px` accent .6 (memory `0 0 8px rgba(56,189,248,.6)`; warning bar `0 0 8px rgba(251,191,36,.6)`) |
| Active tab icon | `0 0 5px` accent .8 |
| Primary CTA button | `0 0 18px rgba(139,92,246,.5)` (onboarding 22px, small Run-test 14px) |
| Hero numeral text | `text-shadow 0 0 18px rgba(56,189,248,.4)` (speed) / `0 0 16px rgba(167,139,250,.4)` (FPS) |
| Speed gauge arc | `0 0 9px rgba(56,189,248,.7)`; tip dot `0 0 8px #38BDF8` |
| Onboarding logo arc | `0 0 12px rgba(139,92,246,.7)`; core `0 0 10px rgba(56,189,248,.8)`; satellite `0 0 6px #A78BFA` |
| Feature icons (onboarding) | `0 0 5px` their accent .7 |
| Result checkmark circle | `0 0 8px rgba(74,222,128,.6)` |

### 3.4 Starfield

Tiny dots scattered over the background (implement as ~6–8 fixed-position circles per screen, or a light procedural generator):

- Sizes: 1×1 px (most) and 1.5×1.5 px (1–2 per screen)
- Colors: white at opacity .30–.60, plus pale blue `rgba(190,210,255, .30–.55)` for 2–3 dots
- Density: ~6 dots per phone screen, ~8 on onboarding/iPad; scattered positions (e.g. 20%/15%, 75%/10%, 60%/40%, 15%/62%, 85%/78%, 40%/88%)
- Static (no twinkle animation specified)

---

## 4. Components

### 4.1 GaugeOrb (circular gauge)

Structure (SVG viewBox 120, rendered 110–118 pt on phone, 150 iPad):
- Track: full circle r=48/60 (i.e. 80% of half-size), stroke `rgba(255,255,255,.08)`, width 8, no cap decoration
- Progress: same circle, `stroke-linecap: round`, width 8, starts at 12 o'clock (rotate −90°), sweeps clockwise; trim = value/100 of circumference
- Tip dot: 4.5 r circle riding the progress end, fill `#C4B5FD`, glow (normal state only)
- Center: value in `type.heroOrb` (SF Mono 28–30/600), "%" 9pt/600/+2 tracking 18pt below center
- Caption 8pt/600/+2 tracking under the orb ("CPU LOAD")

States:
| State | Progress stroke | Value color | "%" color | Caption |
|---|---|---|---|---|
| Normal (42%) | `gradient.gauge` (#38BDF8→#A78BFA) + violet glow | `#F2F2FA` | `#8F8FB8` | `#9FA6D8` "CPU LOAD" |
| Warning (78%) | `gradient.gaugeWarning` (#FBBF24→#F472B6) + amber glow, no tip dot | `#F2F2FA` | `#FBBF24` | `#FBBF24` "⚠ HIGH LOAD" |
| Critical (95%) | solid `#FB7185` + rose glow 8px, no tip dot | `#FB7185` | `#FB7185` | `#FB7185` "✕ CRITICAL" |
| Inactive | track only, no progress | `#5E648F` "--" | — | `#5E648F` "NO DATA" |

Warning threshold ≈ ≥70%, critical ≈ ≥90% (inferred from samples 78/95).

### 4.2 StatCard

Card recipe (§3.2), vertical stack, gap 8–10:
1. Eyebrow micro-label (9pt/600/+2.2/uppercase, `#9FA6D8`)
2. Value row: SF Mono 26/600 `#F2F2FA` + unit 11pt `#8F8FB8`, baseline-aligned, gap 4
3. Optional visualization: sparkline (h 24–30), progress bar (h 6), or ring
4. Optional footer: status pill or SF Mono footnote (10pt `#7C86B8`)

Warning variant: border/eyebrow switch to `#FBBF24` (eyebrow prefixed "⚠ "), card glow `0 0 18px rgba(251,191,36,.1)`, bar uses `gradient.memoryWarning`.

### 4.3 RingChart (storage donut)

- SVG r=28 (phone kit 66pt) / r=32 (Performance, 76pt; iPad 84pt), stroke width 8–9, flat caps for segments
- Track: full ring `rgba(255,255,255,.08)`
- Segment 1 (Apps & data): `#A78BFA` with violet glow 4–5px, from 12 o'clock
- Segment 2 (System): `#38BDF8`, continues after segment 1 (dash offset)
- Remainder = Free (track shows through)
- Center text (larger variant): SF Mono 15/600 `#F2F2FA` — used-percent ("46%")
- Legend rows: swatch square "■" + label + right-aligned mono value; colors `#C4B5FD` Apps / `#7DD3FC` System / `#5E648F` Free

### 4.4 Sparkline / line chart

- Polyline, stroke width 1.5 (large CPU chart 1.8; secondary upload line 1.2), round joins fine, glow 3–4px accent
- End-point dot r 2.5–3, brighter accent (`#7DD3FC`, `#C4B5FD`, `#4ADE80`), glowed
- Large charts add a vertical fade area-fill under the line (`gradient.chartFillViolet` / `Green`)
- Large charts add 3 horizontal gridlines `rgba(255,255,255,.05)`, 1px, at 25/50/75% height
- Data window: 60 s at 1 s cadence; new points enter from the right
- Series colors: CPU `#A78BFA`; download `#4ADE80`; upload `#7DD3FC`; downlink tile `#38BDF8`

### 4.5 Per-core bars (BarRow)

Row = label + track + value, gap 8 (iPad 10):
- Label: SF Mono 8pt `#5E648F`, fixed width 16 ("P1","P2","E1"…)
- Track: height 4 (kit 5; iPad 6), radius = height/2, fill `rgba(255,255,255,.06)`
- Fill: width = load %, P-cores `#A78BFA`, E-cores `#7DD3FC`, glow 5px at .6
- Value: SF Mono 8pt `#9FA6D8`, right-aligned, width 18
- Rows stack with 6pt gap; card footer below a `divider` line: SF Mono 10pt `#7C86B8`, space-between: "A17 PRO" · "2P + 4E CORES" · "3.78 GHZ"

### 4.6 Segmented memory bar

- Track h 8, radius 4, `rgba(255,255,255,.07)`, clipped
- Segments left→right: App `#38BDF8` (26%), Wired `#7DD3FC` (13%), Cached `rgba(125,211,252,.35)` (8%)
- Legend: SF Mono 9pt — `■ APP 2.1 GB` (#7DD3FC), `■ WIRED 1.0 GB` (#9FA6D8), `■ CACHED 0.6 GB` (#7C86B8)

### 4.7 Speed-test gauge

- 300×185 semicircular arc (180°), radius 125, ends at the horizontal diameter
- Track: stroke `rgba(255,255,255,.07)`, width 13, round caps
- Progress: `gradient.speedGauge` left→right, width 13, round cap, glow `0 0 9px rgba(56,189,248,.7)`; tip dot r 7 `#BAE6FD` glowed
- Needle: 2px `#F2F2FA` line at .85 opacity from center pivot to just short of the tip; pivot dot r 6 `#F2F2FA`
- Scale labels: SF Mono 9 `#5E648F` — "0" (left end), "500" (top), "1000" (right end); scale is non-linear (412.6 Mbps renders ≈ 66% sweep)
- Below gauge: hero numeral SF Mono 58/600 `#F4FAFF` + cyan text glow; caption "MBPS · DOWNLOAD" 10pt/600/+2.5 `#7DD3FC`

### 4.8 Phase indicator (speed test)

Row of tracked 9pt/600/+2 uppercase words separated by "·": `LATENCY · DOWNLOAD · UPLOAD`. Inactive `#5E648F`; active phase `#7DD3FC` with `text-shadow 0 0 8px rgba(125,211,252,.7)`.

### 4.9 Key-value list group

- Container: radius 20 (sheet variant 16), `surface.card`, `border.neutral`, clipped
- Optional group header inside top: eyebrow micro-label, padding 10/16/6
- Rows: padding 12×16 (device lists 11×16), 1px bottom divider `rgba(255,255,255,.06)` except last
- Left label: SF Pro 12 (sheet 13) `#C9CBE4`; right value: SF Mono 12 `#F2F2FA`
- Copyable rows append "⧉" copy glyph (SF Symbol `doc.on.doc`); pickers show cyan value + "▾"/"›"

### 4.10 Buttons

All: radius 14, padding 13–15 vertical, centered, SF Pro 14–15/600 (small: radius 12, padding 8–9 × 16–18, 12pt).

| Style | Fill | Border | Label | Shadow |
|---|---|---|---|---|
| Primary | `gradient.button` #8B5CF6→#D946EF 135° | none | `#FFFFFF` | `0 0 18px rgba(139,92,246,.5)` |
| Secondary | `rgba(255,255,255,.05)` | 1px `rgba(255,255,255,.18)` | `#C9CBE4` | none |
| Destructive | `rgba(251,113,133,.08)` | 1px `rgba(251,113,133,.35)` | `#FB7185` | none |
| Tinted (cyan) | `rgba(56,189,248,.08)` | 1px `rgba(56,189,248,.35)` | `#7DD3FC` | none |

Kit copy samples: "Enter the dashboard" (primary), "Run speed test" (secondary), "Stop stress test" (destructive), "Reveal network name" (cyan, with footnote below: "Requires location access · used once, never stored").

### 4.11 Status pills

Capsule, padding 3×8 (iPad 4×10), 9pt/700/+1.5 uppercase, tinted fill + 1px border (§1.6): `CHARGING` (green), `LOW POWER` (amber), `THERMAL` (rose), `OFFLINE` (neutral), `STABLE` (green).

### 4.12 Toggle

46×27 capsule, 2px inner padding, 21pt circular knob.
- Off: track `rgba(255,255,255,.10)` + 1px border `rgba(255,255,255,.15)`, knob `#8F8FB8`, left
- On: track `rgba(74,222,128,.5)`, knob `#FFFFFF`, right

### 4.13 Segmented control

Track: radius 12, `rgba(255,255,255,.06)`, 3px inner padding, 4px gap. Segments equal-width, padding 8, 12pt centered. Selected: radius 9, `gradient.segmentSelected` (#7DD3FC→#A78BFA), 600 weight, label `#0B0B1E`. Unselected: transparent, `#8F8FB8`.

### 4.14 Permission-denied card (location)

Centered column card (`surface.cardFaint`, `border.neutral`+, radius 20, padding 18–22, gap 8–10, text centered):
1. Location-pin outline icon 24–30pt, stroke `#8F8FB8` 1.5 (SF Symbol `mappin.and.ellipse` or `location.slash`)
2. Title "Location is off" — 12–13pt/600 `#F2F2FA`
3. Body — 10.5–11pt `#8F8FB8`, line-height 1.5: "iOS needs location access to share your network's name. Everything else works without it." (kit variant says "…your Wi-Fi network's name…")
4. Small tinted-cyan button "Open Settings"

### 4.15 App logo

Orbit mark: broken ring (r 44 in 120 viewBox, stroke 7–11, round caps, ~75% arc starting at rotate 120°) stroked with the 3-stop gauge gradient + glow; filled core circle r 14–18 (same gradient, cyan glow); satellite dot r 5–6.5 `#C4B5FD` at upper-right with violet glow.

### 4.16 App icon (2i)

- Squircle (radius 40/180), background radial `#2A1B54 (at 80%/10%) → #151132 45% → #0B0B1E`
- 5 star dots (1–1.5 r, white/blue-white at .3–.6)
- Orbit arc: r 52, stroke 11 (14 at 60pt size), gauge gradient, ~75% sweep from 120°, glow `0 0 14px rgba(56,189,248,.6)`
- Core: r 18 (20 at small size) gradient fill, glow; satellite dot r 6.5 `#C4B5FD` at (139,63) — dropped at 60 pt

---

## 5. Screens

Shared iPhone chrome: content under the status bar; page header padding `62 top, 20 horizontal, 6 bottom`; content column padding `8 top, 16 horizontal, 12 bottom` with 12pt gap between cards; floating tab bar at bottom (§6).

### 5.1 Dashboard (committed 1a)

Background: standard nebula + 8-dot starfield (densest starfield of the phone screens).

Header row (space-between, baseline):
- Wordmark: "Nebula" 20pt/700/+0.5 + "STATS" 10pt/600/+2.5 uppercase `#8F8FB8`, baseline gap 8
- Right: settings gear icon 22pt, stroke `#9FA6D8` 1.5, subtle glow `0 0 4px rgba(159,166,216,.5)` (SF Symbol `gearshape`; drawn as sun-style gear)

Content: 2-column grid, 12pt gaps, top-aligned. All cards `backdrop blur 14`.

1. **CPU hero card** (spans both columns) — `surface.cardHero`, border violet .28, glow `0 0 28px rgba(139,92,246,.18)` + inset top highlight; horizontal layout, gap 20, padding 18×20:
   - GaugeOrb 118pt, normal state, value 42, no caption below (label sits to the right)
   - Right column (gap 8): eyebrow "CPU LOAD" (10pt/600/+2.5); SF Mono 12 rows — "PERF **58%**" (`#7C86B8` label / `#C4B5FD` value), "EFF **31%**" (/`#7DD3FC`), "A17 PRO **6 CORES**" (/`#8F8FB8`)
2. **MEMORY** (col 1) — border cyan; value "3.1 / 8 GB"; memory progress bar (h 6, 39%, `gradient.memoryFill` + glow); footer mono "4.9 GB FREE"
3. **STORAGE** (col 2) — border violet; ring r 24/stroke 7 (58pt), `#A78BFA` 45% w/ glow, round cap; beside it "118" SF Mono 20/600 over "of 256 GB" 10pt `#8F8FB8`
4. **BATTERY** (col 1) — border green; value "78 %"; pill `CHARGING`; footer mono "THERMAL · NOMINAL"
5. **NETWORK** (col 2) — border cyan; SF Mono 13 row "▼ 86.1" `#4ADE80` + "▲ 2.4" `#7DD3FC`; green sparkline h 30 with area fill + end dot; footer mono "Mbps · WI-FI 6"
6. **DISPLAY** (col 1) — border violet; value "120 FPS"; footer mono "PROMOTION · 460 PPI"

Active tab: DASHBOARD.

### 5.2 Onboarding (2b)

Full-bleed nebula + starfield; column, centered, padding 110 top / 32 h / 40 bottom.

1. App logo mark 120pt (§4.15), 22 below
2. "Nebula Stats" 30pt/700/+0.5
3. "MISSION CONTROL FOR YOUR DEVICE" 11pt/600/+3 `#9FA6D8`, 6 above
4. 48pt below — feature list, full width, 20pt row gap; each row: 26pt glowing outline icon (stroke 1.6) + text column (gap 2; title 14/600 `#F2F2FA`, description 12 `#8F8FB8`):
   - Line-chart icon, violet (`chart.xyaxis.line`) — "Live telemetry" / "CPU, memory, battery and display — refreshed every second."
   - Wi-Fi icon, cyan (`wifi`) — "Network insight" / "Throughput, addresses and a built-in speed test."
   - Shield icon, green (`shield`) — "Private by design" / "Everything is measured on-device. Nothing leaves it."
5. Spacer
6. Primary CTA, full-width, padding 15, 15pt: "Enter the dashboard" (glow 22px)

No tab bar.

### 5.3 Performance tab (2c)

Header: "Performance" 20pt/700 (left) · "● LIVE · 1s" SF Mono 10 `#4ADE80` (right, baseline).

1. **CPU card** — border violet .24, glow 24px/.12, gap 10:
   - Header row: eyebrow "CPU · 60 S" · value "42%" SF Mono 22/600 (unit 11 `#8F8FB8`)
   - Line chart h 64: 3 gridlines, violet stroke 1.8 + area fill + end dot `#C4B5FD`
   - Per-core BarRows: P1 64, P2 52, E1 38, E2 33, E3 29, E4 24 (h 4 tracks)
   - Footer (divider above, 8 padding): "A17 PRO" · "2P + 4E CORES" · "3.78 GHZ"
2. **MEMORY card** — border cyan, gap 10:
   - Eyebrow "MEMORY" · value "3.1 / 8 GB" SF Mono 22
   - Segmented bar h 8 (§4.6) + legend "■ APP 2.1 GB / ■ WIRED 1.0 GB / ■ CACHED 0.6 GB"
   - Footer row (divider): "Nebula Stats footprint" 12pt `#C9CBE4` · "38 MB" SF Mono 12 `#F2F2FA`
3. **STORAGE card** — border violet; horizontal: RingChart 76pt (r 32/stroke 9, center "46%") + column: eyebrow "STORAGE"; legend rows 11pt with mono right values — "■ Apps & data 115 GB" (#C4B5FD), "■ System 21 GB" (#7DD3FC), "■ Free 120 GB" (#5E648F)

Active tab: PERFORMANCE.

### 5.4 Network tab (2d)

Header (icon + title stack, gap 12): Wi-Fi icon 24pt cyan stroke 1.7 + glow; column — "Network" 20pt/700 over "WI-FI 6 · CONNECTED" SF Mono 9 `#4ADE80` +1 tracking.

1. **WI-FI card** — border `rgba(56,189,248,.24)`, glow cyan 24px/.10:
   - *Hidden state (default):* header row eyebrow "WI-FI" · masked SSID "••••••••" SF Mono 13 `#5E648F`; full-width tinted-cyan button "Reveal network name" (radius 12, padding 12, 13pt); footnote centered "Requires location access · used once, never stored"
   - *Revealed state:* eyebrow "WI-FI"; row — SSID "Starbase-5G" SF Mono 17/600 `#F2F2FA` · "RSSI -52" SF Mono 10 `#7DD3FC`; row SF Mono 10 `#7C86B8` — "CHANNEL 149 · 5 GHZ" · "WPA3"
   - *Location denied:* swap card for permission-denied card (§4.14)
2. **Address list group** — rows: "IPv4 address / 192.168.1.42 ⧉", "IPv6 / fe80::1c2a…9f", "Gateway / 192.168.1.1", "DNS / 1.1.1.1"
3. **THROUGHPUT card** — border green:
   - Header: eyebrow "THROUGHPUT" · SF Mono 12 "▼ 86.1" green + "▲ 2.4" cyan + "Mbps" 9 `#7C86B8`
   - Dual-line chart h 40: gridlines ×3; download green 1.5 w/ area fill + end dot; upload cyan-bright 1.2
   - Footer SF Mono 9 `#7C86B8`: "SESSION ▼ 4.2 GB · ▲ 310 MB" · "60 S"
4. **Speed test CTA row** — `surface.cardHero`, border violet .28, glow 20px/.14, horizontal space-between: column ("Speed test" 13/600; "Last run · 2 h ago · 412 Mbps down" 10 `#8F8FB8`) · small primary button "Run test" (radius 12, 9×16, 12pt, glow 14px)

Active tab: NETWORK (cyan tint — the one tab whose active color is cyan, matching its section accent).

### 5.5 Speed test — running (2e-1)

Full-screen modal (no tab bar), speed-test background variant, column centered, padding 70 top / 24 h / 32 bottom.

1. Top bar (space-between): "✕ Cancel" 13pt `#8F8FB8` (SF Symbol `xmark`) · "FRA-1 · SPEEDNET" SF Mono 10 `#7C86B8`
2. 34 below: phase indicator (§4.8), DOWNLOAD active
3. 26 below: speed gauge (§4.7), needle at 412.6
4. Hero readout: "412.6" SF Mono 58 + "MBPS · DOWNLOAD" caption
5. Spacer
6. Bottom row of 3 equal mini stat tiles (radius 16, `surface.card`, `border.neutral`, padding 12, centered, gap 12): "PING 11 ms", "JITTER 2.1 ms", "UPLOAD --" (pending value `#5E648F`). Tile format: 8pt/600/+2 eyebrow `#9FA6D8`; value SF Mono 17/600; unit 9 `#7C86B8`.

### 5.6 Speed test — results (2e-2)

Same background/padding.

1. Top bar: "‹ Network" 13pt `#8F8FB8` (chevron.left) · "TODAY · 14:32" SF Mono 10 `#7C86B8`
2. 36 below, centered: success mark — 52pt circle stroke `#4ADE80` 3px + checkmark, green glow; "Test complete" 15/600 (6 above); "Your connection can stream 4K on 8 devices" 11 `#8F8FB8`
3. 30 below: **Result card** — radius 20, border green .24, glow 26px/.10, padding 22, gap 18:
   - Row (space-between): "▼ DOWNLOAD" eyebrow (9/600/+2 `#9FA6D8`) over "412.6" SF Mono 34/600 `#4ADE80` · right-aligned "▲ UPLOAD" over "48.2" SF Mono 34/600 `#7DD3FC`
   - Divider row (top border `rgba(255,255,255,.07)`, 14 padding), SF Mono 11 `#9FA6D8` with `#F2F2FA` values: "PING 11 ms" · "JITTER 2.1 ms" · "LOSS 0%"
   - Footer SF Mono 10 `#7C86B8`: "SERVER FRA-1" · "WI-FI 6 · STARBASE-5G"
4. Spacer
5. Primary button "Test again" (padding 14, glow 18px); 10 below secondary button "Share result"

### 5.7 Display & Device tab (2f)

Header: "Display & Device" 20pt/700.

1. **LIVE FRAME RATE card** — `surface.cardHero`, border violet .28, glow 24px/.14, padding 18, horizontal space-between:
   - Left: eyebrow "LIVE FRAME RATE"; "120" SF Mono 50/600 `#F4FAFF` + violet text glow, unit "FPS" 13 `#8F8FB8`
   - Right: mini column — "STRESS" 8pt/600/+1.5 `#9FA6D8` over toggle (off state) — GPU stress-test toggle; when on, button style "Stop stress test" exists in kit
2. **DISPLAY list group** (header eyebrow "DISPLAY"): "Resolution / 2556 × 1179", "Refresh rate / 1–120 Hz", "Brightness / 64%", "Pixel density / 460 PPI"
3. **DEVICE list group** (header "DEVICE"): "Model / iPhone 15 Pro", "Chip / A17 Pro", "iOS / 17.5.1", "Uptime / 3d 14h 22m"
4. **BATTERY card** — border green, gap 9: header row eyebrow "BATTERY" · pill `CHARGING`; SF Mono 11 row `#9FA6D8` labels / `#F2F2FA` values: "LEVEL 78%" · "HEALTH 96%" · "TEMP 31.2°C" (temp value `#4ADE80` when nominal)

Active tab: DISPLAY.

### 5.8 Settings sheet (2g)

Bottom sheet over dimmed dashboard (scrim §1.1). Sheet: top radius 28, `surface.sheet` (blur 24), violet border .20 (no bottom edge), shadow `0 -8px 40px rgba(0,0,0,.5)`, padding 12/18/24, 14pt section gap.

1. Grabber: 36×5, radius 3, `rgba(255,255,255,.25)`, centered
2. Header row: "Settings" 18/700 · "Done" 13/600 `#7DD3FC`
3. Section "REFRESH RATE" (eyebrow) + segmented control: **1 s** (selected) / 2 s / 5 s
4. List group (radius 16): "Throughput units / Mbps ▾" (value cyan `#7DD3FC`, `chevron.down`); "Speed-test server / Auto · FRA-1 ›" (`chevron.right`); "Reduce motion / [toggle ON]"
5. About box — radius 16, `surface.cardFaint`, border `rgba(255,255,255,.08)`, padding 14×16, gap 5: "Nebula Stats 1.4.0" 12/600 `#F2F2FA`; privacy paragraph 11 `#8F8FB8` lh 1.5: "All measurements happen on-device. No analytics, no tracking, no data leaves your phone. Speed tests exchange traffic only with the server you choose."; links "Privacy policy · Acknowledgements" 11 `#7DD3FC`

### 5.9 iPad split view (2h) — regular width layout

1024×1366. Sidebar 250pt (fill `rgba(10,10,26,.5)`, right border `rgba(255,255,255,.07)`, padding 56/14/20):
- Brand row: logo 30pt + "Nebula Stats" 17/700
- Nav rows (padding 11×12, radius 12, icon 19 + label 14, gap 12): Dashboard, Performance, Network, Display & Device; **selected** = fill `rgba(167,139,250,.14)`, border violet .30, icon `#C4B5FD` glowed, label 600 `#EDE9FE`; unselected icon `#8F8FB8`, label `#A8ABCB`
- Spacer, then "Settings" row (gear 18 + 13pt label) pinned bottom

Detail pane (padding 56/26/24, 16 gap): title 26/700 + "● LIVE · 1s" SF Mono 11; content grid gap 16, radius 22 cards, padding 20–22.
- Dashboard: 3 columns — hero CPU row spans all (orb 150 + stats + 300×80 sparkline); MEMORY, STORAGE (ring 70 + "118 / 256 GB"), BATTERY tiles; NETWORK · WI-FI 6 chart spans 2; DISPLAY tile ("120 FPS", "PROMOTION · 264 PPI")
- Performance: 2 columns — CPU · 60 S chart spans both (h 110, gridline width .6, line 1.2); PER-CORE card (h 6 bars, footer "A17 PRO / 2P + 4E / 3.78 GHZ"); right column stacks MEMORY + STORAGE cards

No tab bar on iPad; sidebar replaces it. Settings opens from the sidebar row instead of the dashboard gear.

---

## 6. Navigation

### 6.1 Tab bar (iPhone)

Floating capsule-ish bar: margin 0 14 / 8 bottom, padding 10×8, radius 24, fill `rgba(255,255,255,.05)`, border 1px `rgba(255,255,255,.10)`, backdrop blur 20. Four evenly-spaced items; each = 20pt line icon (stroke 1.6) over 8.5pt tracked uppercase label, 3pt gap.

| Label | Icon (design) | Closest SF Symbol | Active tint (icon / label) |
|---|---|---|---|
| DASHBOARD | 2×2 rounded squares | `square.grid.2x2` | `#A78BFA` glow / `#C4B5FD` |
| PERFORMANCE | zig-zag line chart | `chart.xyaxis.line` (alt `waveform.path.ecg`) | `#A78BFA` glow / `#C4B5FD` |
| NETWORK | wifi arcs + dot | `wifi` | `#38BDF8` glow / `#7DD3FC` |
| DISPLAY | portrait rounded rect | `iphone` (alt `rectangle.portrait`) | `#A78BFA` glow / `#C4B5FD` |

Inactive: icon stroke + label `#6B7099`, weight 500, no glow. Active icon gets `drop-shadow 0 0 5px` of its tint at .8. Note the Network tab is the only cyan-tinted active state; all others are violet.

### 6.2 Headers

No system nav bar — custom large header inside the scroll area (62pt top padding clears the status bar): 20pt/700 title left; optional right accessory ("● LIVE · 1s" mono-green on live screens; gear on Dashboard). Network uses icon+title+subtitle stack. Modals (speed test) use text buttons top-left ("✕ Cancel" / "‹ Network") with mono metadata top-right. Settings is a sheet with grabber + title + "Done".

### 6.3 Other icons used

| Use | SF Symbol |
|---|---|
| Settings gear | `gearshape` |
| Location pin (denied card) | `mappin.and.ellipse` / `location.slash` |
| Copy address | `doc.on.doc` |
| Success check | `checkmark` in stroked circle (or `checkmark.circle`) |
| Down/up throughput | `arrow.down` / `arrow.up` (design uses ▼/▲ glyphs inline in mono text — keep as text glyphs) |
| Live dot | `circle.fill` 6pt green (design: "●" text) |
| Charging bolt | `bolt.fill` (design: "⚡" in pill contexts on kit) |
| Warning / critical prefixes | "⚠" / "✕" text glyphs (or `exclamationmark.triangle`, `xmark`) |

---

## 7. Motion, charts, and states

- **Refresh cadence:** all telemetry updates every 1 s (user-selectable 1/2/5 s in Settings). Live screens show "● LIVE · 1s".
- **Charts:** 60-second rolling window; line strokes 1.5 (1.8 hero, 1.2 secondary/iPad), gridlines 3×1px `rgba(255,255,255,.05)`, vertical fade area fills (.30–.35 → 0), glowing end dot marks the newest sample. Animate by shifting points left as new samples append.
- **Gauges:** progress trims animate to new values (ease-out ~0.5s implied by live cadence); the tip dot travels with the trim end. Speed-test needle + arc animate continuously during a run; phase label glow moves LATENCY → DOWNLOAD → UPLOAD.
- **Reduce motion** toggle in Settings must disable decorative animation.
- **State thresholds (GaugeOrb / cards):** normal < ~70%, warning ≥ ~70% (amber gradient, "⚠ HIGH LOAD"), critical ≥ ~90% (solid rose, "✕ CRITICAL"). Memory-pressure warning card mirrors this with amber border/eyebrow/bar.
- **No-data:** gauges show track only + "--" and "NO DATA" in `#5E648F`; pending speed-test values show "--" in `#5E648F`; device offline uses the neutral `OFFLINE` pill.
- **Permission denied (location / SSID):** Wi-Fi name is masked as "••••••••" until "Reveal network name" is tapped; if location is denied, show the §4.14 card with "Open Settings". Copy stresses privacy: "used once, never stored".
- **Buttons:** primary CTA glow (violet 18–22px) is part of the resting state, not a press effect. No press states were drawn — use standard opacity/scale feedback.
- **Starfield:** static decoration; safe to omit from animation entirely.
