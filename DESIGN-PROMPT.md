# Design prompt — Nebula Stats (iOS device-monitor app)

> Copy everything below the line into the design tool / design agent.

---

Design a complete UI kit and all screens for **Nebula Stats**, a native iOS 17+ SwiftUI utility app (universal iPhone + iPad) that displays live hardware and network statistics. The app is **dark-only** with a **deep-space science-fiction** identity: the user should feel like they opened the mission-control console of a starship, where their phone's internals are the ship's systems.

## Art direction

- **Backgrounds:** near-black with cool undertones — layered radial "nebula" gradients drifting from deep indigo (#0B0B1E-ish) through violet and petrol blue, never flat black. A **subtle starfield** (tiny dots, 2–3 brightness levels, very sparse) sits behind content; it must stay quiet enough to never compete with data.
- **Accent palette (the "aurora" set):** electric violet/purple, cyan-blue, and aurora green as the three primary data colors; a warm magenta/amber reserved exclusively for warnings (thermal, low battery, memory pressure) and red only for critical states. Accents are used as **glows and gradients on data elements** (gauge arcs, chart lines, icons), not as large fills.
- **Surfaces:** frosted "glass" cards — translucent dark panels with 1 px luminous borders (subtle gradient stroke), soft outer glow on the active/hero card, large corner radii (~20 pt). Depth comes from glow and translucency, not drop shadows.
- **Typography:** SF Pro / SF Pro Rounded for labels; **monospaced digits for every live number** so values don't jitter. Big hero numerals (48–64 pt) for key readouts. Small caps or tracked-out uppercase micro-labels ("CPU LOAD", "DOWNLINK") for that instrument-panel feel.
- **Iconography:** thin-stroke line icons with a slight glow, consistent with SF Symbols weights so we can mix in real SF Symbols.
- **Motion (describe, for later implementation):** gauges sweep on appear, chart lines draw in, cards fade-rise ~12 pt with stagger. Everything must have a Reduce-Motion-safe static variant.
- **Accessibility constraints (hard requirements):** all text ≥ 4.5:1 contrast on its surface; data colors distinguishable for color-blind users (vary luminance + add labels/icons, never color alone); layouts must survive Dynamic Type up to XL.

## Components to design (reusable kit)

1. **GaugeOrb** — circular gauge with gradient arc, glowing tip, big center numeral + unit, micro-label below. States: normal / warning / critical.
2. **StatCard** — glass card: micro-label, hero value, trend sparkline, optional status pill (e.g. "CHARGING", "LOW POWER").
3. **RingChart** — segmented ring for storage (used vs free).
4. **Line chart** — 60-second live history: gradient stroke, soft area fill fading to transparent, no gridlines except faint horizontal quarters, current-value dot with glow.
5. **Bar row** — per-CPU-core horizontal bars with core labels (P1, P2, E1…).
6. **Speed-test gauge** — large semicircular gauge with animated needle/arc, Mbps readout, phase label (LATENCY → DOWNLOAD → UPLOAD), result summary card.
7. **List rows** — key–value rows for device/network info (label left, monospaced value right, copy icon on tap-and-hold affordance).
8. **Tab bar (iPhone)** — 4 items: Dashboard, Performance, Network, Display. Custom glow on the selected item. **Sidebar (iPad)** with the same sections.
9. **Buttons** — primary (gradient fill + glow), secondary (glass outline), destructive/warn variant. Include the special "Reveal network name" button with a small location-permission hint line under it.
10. **Status pills, badges, empty/denied states** (e.g. location denied → calm explainer, not an error scream).

## Screens to deliver

**iPhone (390×844 baseline) — all screens; iPad (1024×1366) — Dashboard + one detail screen showing the split-view layout.**

1. **Onboarding (single screen):** logo over nebula, three feature bullets with icons, one primary button "Enter the dashboard". No permission requests.
2. **Dashboard:** greeting-free, straight to a 2-column grid of live cards — CPU orb, Memory bar, Storage ring, Battery cell (with thermal indicator), Network card with ▲▼ throughput sparkline, Display/FPS card. Gear icon top-right.
3. **Performance tab:** CPU section (60 s line chart, per-core bars, chip info row), Memory section (used/free chart + app footprint), Storage section (ring + breakdown rows).
4. **Network tab:** connection header (type icon + status), addresses list, Wi-Fi card with "Reveal network name" state **and** revealed state, data counters with live throughput chart, speed-test entry card → **separate speed-test running screen** with the big gauge, and a results state.
5. **Display & Device tab:** hero live FPS readout with "stress" toggle, display info rows, device info rows (model name, chip, iOS, uptime), battery detail.
6. **Settings (sheet):** refresh rate picker, units toggle, speed-test server, about/privacy block.
7. **App icon:** a glowing gauge/orbit motif on a nebula field — must read at 60×60; no text in the icon.

## Tone and constraints

- This is a **precision instrument**, not a game: sci-fi comes from glow, gradients, and typography — not from skeuomorphic cockpit clutter. Data density is a feature; whitespace is controlled but the screens should feel alive.
- Respect iOS conventions: safe areas, native navigation patterns, SF Symbols compatibility, standard sheet grabber on Settings.
- Deliver: color tokens (hex), gradient definitions, type scale, spacing scale, all components in default + warning/critical + inactive states, and every screen listed above. Name layers/tokens so they map cleanly to SwiftUI (e.g. `surface.card`, `accent.aurora`, `state.critical`).
