# Nebula Stats — Device & Network Monitor

**Version:** 1.0 (planning)
**Date:** 2026-07-15
**Platform:** iOS 17.0+ / iPadOS 17.0+ (universal app)
**Stack:** Swift 6, SwiftUI, Swift Charts, no third-party dependencies
**Theme:** Deep-space / science-fiction. Dark-only UI with nebula purples, electric blues, and aurora greens.

---

## 1. Product summary

Nebula Stats is a single-purpose utility that shows live hardware and network statistics of the user's iPhone or iPad in a beautiful, space-themed dashboard: CPU load, memory pressure, storage, battery and thermal state, display refresh rate with a live FPS meter, and network details (connection type, IP addresses, Wi-Fi info, data counters, and an on-demand speed test).

Everything is read from public Apple APIs, computed on-device, and displayed in real time. The app collects no data, shows no ads, requires no account, and requests no permissions to perform its core function.

### Why it passes review (guideline mapping)

| Risk | Mitigation |
|---|---|
| 4.3(b) spam / template app | Distinctive custom visual identity (space theme, custom gauges, animated starfield), broader feature set than single-metric competitor apps, original name and branding. |
| 2.5.1 private APIs | Only public APIs: `ProcessInfo`, `UIDevice`, `host_statistics64` / `host_processor_info` (public Mach APIs), `getifaddrs`, `NWPathMonitor`, `NEHotspotNetwork`, `CADisplayLink`, `FileManager` volume capacity keys. No sysctl on private keys, no battery-health private data, no jailbreak-style probing. |
| 5.1.1 permission abuse | Zero permission prompts at launch. Location (When-In-Use) requested only when the user explicitly taps "Reveal Wi-Fi name", with a purpose string explaining Apple requires it for SSID access. Feature degrades gracefully if denied. |
| 5.1.2 data use | No tracking, no third-party SDKs, no network calls except the user-initiated speed test against our own endpoint. Privacy nutrition label: **Data Not Collected**. |
| 2.3.1 hidden features / misleading claims | No "RAM cleaner", "battery doctor", "cooler", or performance-boost claims anywhere in the app or App Store copy — only measurement and display. |
| 2.1 completeness | No placeholder screens; every tab fully functional on both iPhone and iPad at submission. |

### Monetization (v1)

Free, no ads, no IAP. Keeps the first review maximally simple. (v1.x can add a one-time "Pro" unlock for widgets/extra themes.)

---

## 2. Feature specification

### 2.1 Dashboard tab (home)

A scrollable grid of live summary cards, each tappable to open its detail tab/section:

- **CPU orb** — total CPU load % as a glowing circular gauge, chip name (e.g. "A18 Pro"), core count.
- **Memory bar** — used / total RAM, memory-pressure tint (green → amber → red).
- **Storage ring** — used / free space with formatted GB values.
- **Battery cell** — charge %, charging/unplugged/full state, Low Power Mode badge, thermal state (nominal / fair / serious / critical) shown as a color-coded "core temperature" indicator.
- **Network card** — current connection type (Wi-Fi / Cellular / Wired / none), local IP, live ▲▼ throughput sparkline.
- **Display card** — current FPS (live), max refresh rate (60/120 Hz), resolution.

Data refresh: 1 s timer while foregrounded; all timers suspended on background/inactive to keep energy impact low.

### 2.2 Performance tab (CPU · Memory · Storage)

- **CPU**
  - Live total load line chart (Swift Charts, last 60 s window).
  - Per-core load bars (from `host_processor_info`), performance vs. efficiency cores labeled where core counts allow inference.
  - Static info: chip marketing name (device-model lookup table), physical/logical core count, architecture (arm64).
- **Memory**
  - Used / free / total from `host_statistics64` (active + wired + compressed as "used").
  - This-app memory footprint (`task_vm_info`), memory-pressure state.
  - 60 s history chart.
- **Storage**
  - Total / used / free via `volumeTotalCapacity` + `volumeAvailableCapacityForImportantUsage` (matches Settings app numbers).
  - Segmented ring visualization.

### 2.3 Network tab

- **Connection status** — `NWPathMonitor`: interface type (Wi-Fi / Cellular / Wired / Loopback / none), expensive/constrained flags, IPv4/IPv6 support.
- **Addresses** — local IP per interface via `getifaddrs` (en0, pdp_ip0…); public IP fetched only on user tap ("Fetch public IP" button — user-initiated network call, with a small note).
- **Wi-Fi details** — ~~SSID reveal via `NEHotspotNetwork`~~ **Cut from v1** (2026-07-15): the SSID requires location permission, and dropping it makes the app require zero permissions — the strongest possible privacy posture for review. Can return in v1.x if users ask.
- **Cellular** — radio technology (LTE / 5G NSA / 5G SA) via `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology`. (No carrier name — deprecated/redacted by iOS; do not display "--" junk, just omit.)
- **Data counters** — bytes sent/received since boot per interface class (Wi-Fi vs cellular) from `getifaddrs` stats; live ▲▼ throughput chart (delta per second).
- **Speed test** — user-initiated download + upload test against a configurable HTTPS endpoint (e.g. Cloudflare's speed endpoints), animated gauge, results in Mbps with latency (ms). Runs only on tap; cancellable; warns on cellular/constrained paths.

### 2.4 Display & Device tab

- **Live FPS meter** — `CADisplayLink` measuring actual frame cadence; big animated readout. "Stress" toggle runs a lightweight on-screen particle animation so 120 Hz ProMotion panels visibly ramp from idle to max — this is the fun, shareable feature (analog of "120 FPS Meter" competitor).
- **Display info** — max refresh rate (`UIScreen.maximumFramesPerSecond`), point + pixel resolution, scale factor, display gamut (P3/sRGB), current brightness slider readout.
- **Device info** — marketing model name (identifier → name lookup table, e.g. `iPhone17,2` → "iPhone 16 Pro Max"), model identifier, iOS version + build, uptime since boot, locale/region, accessibility text-size setting.
- **Battery detail** — level, state, Low Power Mode (live via notification), thermal state history for this session.

### 2.5 Settings screen (modal, gear icon)

- Refresh rate for live stats (0.5 s / 1 s / 2 s).
- Units (binary GiB vs decimal GB).
- Speed-test server selection.
- About: version, privacy explainer ("all stats computed on your device; nothing leaves it"), link to privacy policy + support page (required by review), "Rate the app" (SKStoreReviewController, only after ≥3 sessions).

### Explicitly out of scope for v1 (roadmap)

- LAN device scanner / Wi-Fi device finder (needs Local Network permission → v1.1).
- Home-screen widgets (WidgetKit) and Live Activities — v1.1, strong retention feature.
- Additional theme packs / Pro IAP — v1.2.
- Export/share stat cards as images — v1.2.

---

## 3. User flow

### First launch
1. **Splash → one onboarding screen** (single page, not a multi-step wizard): app logo over animated starfield, three bullet highlights (Live performance · Network insight · Display meter), one button "Enter the dashboard". No permission prompts, no sign-in.
2. Lands on **Dashboard** with all cards already live (no permissions needed for any of them).

### Core loop
1. User opens app → Dashboard animates in, cards tick with live data.
2. Taps a card → navigates to the corresponding tab section with charts.
3. In Network: taps "Reveal network name" → system location prompt (first time) → SSID appears; taps "Start speed test" → animated gauge → result saved to session history.
4. In Display: taps FPS stress toggle → watches refresh rate ramp to 120 Hz.
5. Backgrounds the app → all timers/display links pause. Returns → charts resume with a gap marker (no fake backfilled data).

### Navigation structure
- **iPhone:** `TabView` — Dashboard · Performance · Network · Display. Settings as gear in nav bar.
- **iPad:** `NavigationSplitView` sidebar with the same four sections; dashboard grid uses 2–3 columns; charts get wider time windows. Supports all orientations and Split View/Stage Manager (plain adaptive SwiftUI — no fixed frames).

---

## 4. Technical architecture

```
NebulaStats/
├── App/                    NebulaStatsApp.swift, RootView (Tab vs SplitView by size class)
├── Core/
│   ├── Samplers/           CPUSampler, MemorySampler, StorageSampler,
│   │                       BatterySampler, ThermalSampler, DisplayLinkFPS,
│   │                       NetworkPathObserver, InterfaceStatsSampler, WiFiInfoProvider
│   ├── SpeedTest/          SpeedTestEngine (URLSession, async/await, cancellable)
│   ├── Models/             Snapshot structs (value types), RingBuffer<T> for chart history
│   └── DeviceCatalog/      model-identifier → marketing name / chip lookup (bundled JSON)
├── Features/
│   ├── Dashboard/          Performance/   Network/   DisplayDevice/   Settings/
├── DesignSystem/
│   ├── Theme.swift         colors, gradients, typography tokens
│   ├── Components/         GaugeOrb, RingChart, StatCard, SparklineView,
│   │                       StarfieldBackground (TimelineView + Canvas), GlowModifier
└── Resources/              Assets, device catalog JSON, localized strings (en for v1)
```

- **Pattern:** lightweight MVVM — each feature has an `@Observable` view model consuming sampler `AsyncStream`s. Samplers are actors where they touch shared state.
- **Concurrency:** Swift 6 strict concurrency on; samplers publish snapshots on the main actor for UI.
- **Charts:** Swift Charts with fixed 60-sample ring buffers — O(1) memory, no unbounded growth.
- **Energy discipline:** `scenePhase`-driven start/stop of every timer and the CADisplayLink; starfield animation uses `TimelineView(.animation)` paused when reduced-motion is on or scene is inactive.
- **Accessibility:** all gauges expose `accessibilityValue`; contrast ≥ 4.5:1 for text on the dark theme; Dynamic Type supported (cards reflow); Reduce Motion swaps starfield for static gradient.
- **Testing:** unit tests for samplers (formatting, ring buffer, byte-rate deltas), device-catalog lookup, speed-test math. UI smoke test that each tab renders.
- **App won't break because:** no private APIs, no force-unwraps in samplers (every Mach/API call returns optional-safe snapshots with "—" placeholder rendering), no assumptions about core count/refresh rate/cellular presence (Wi-Fi-only iPads fully supported — cellular section hidden when no radio).

### App Store metadata plan
- **Name:** Nebula Stats — Device Monitor
- **Subtitle:** CPU, RAM, Network & FPS live
- **Keywords:** cpu, ram, monitor, fps, hz, network, speed test, storage, battery, system info
- **Category:** Utilities
- **Privacy label:** Data Not Collected
- **Screenshots:** 6 per device class, themed captions ("Mission control for your iPhone").
- **Review notes:** explain the optional location permission (Apple requires it for SSID) and that the speed test is user-initiated.

---

## 5. Milestones

1. **M1 — Core samplers + Dashboard** (CPU/memory/storage/battery/path monitor, static theme).
2. **M2 — Performance & Network tabs** (charts, counters, speed test, Wi-Fi reveal flow).
3. **M3 — Display tab + FPS meter + stress animation.**
4. **M4 — iPad layout, Settings, accessibility, onboarding, polish pass on theme.**
5. **M5 — QA on oldest supported device (iOS 17 hardware), App Store assets, privacy policy page, submission.**
