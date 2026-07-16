# App Store Connect metadata — Nebula Stats 1.0

Paste-ready. Character limits noted per field.

## App name (30 max)
Nebula Stats — Device Monitor

## Subtitle (30 max)
Live CPU, RAM, FPS & Network

## Promotional text (170 max, editable without review)
Watch your iPhone think — live CPU, memory, network and FPS in a starship-console dashboard. No accounts, no ads, zero permissions. Nothing leaves your device.

## Keywords (100 max, comma-separated — don't repeat words from the app name)
cpu,ram,memory,monitor,fps,hz,speed,test,network,wifi,battery,storage,system,device,benchmark,info

## Description (4000 max)
Nebula Stats turns your iPhone and iPad into their own mission control: a live, beautifully drawn dashboard of everything happening under the glass — CPU, memory, storage, battery, network and display — refreshed every second.

No accounts. No ads. No permissions. Everything is measured on your device, and nothing ever leaves it.

YOUR DASHBOARD
• CPU load as a glowing gauge, with per-core bars for performance and efficiency cores and a rolling 60-second chart
• Memory the way iOS really sees it: active, wired and compressed — plus this app's own footprint, so you can see exactly what it costs to watch
• Storage: the same honest numbers Settings shows, drawn as a glowing ring
• Battery: level, charging state, Low Power Mode and thermal status — with an estimated charging wattage while plugged in
• Display: a live FPS meter. On ProMotion screens, flip the stress toggle and watch the panel ramp to 120 Hz before your eyes

NETWORK INSIGHT
• Live throughput, down and up, with a rolling chart
• Your local addresses — and your public IP, fetched only when you ask
• A built-in speed test: latency, download and upload, with results kept on your device for 7 days so you can see how your connection behaves over time

THE NEBULA SCORE
A quick, safe engine test for your chip: one core at full thrust, then all of them — a few seconds of pure math. The app reads iOS's thermal state before and during the run and won't start if your device is already warm. Nothing on your device is touched or changed; you just learn what it can do.

PRIVATE BY DESIGN
• Zero permissions requested — no location, no camera, no contacts, nothing
• No analytics, no trackers, no third-party SDKs
• The only network calls are the two you make yourself: the speed test and the public-IP lookup
• Delete the app and every trace of it is gone — we never had any of it

Built natively in SwiftUI for iOS 17 and later, on iPhone and iPad, with a dark science-fiction design that makes telemetry a pleasure to watch.

## App Review notes
Thank you for reviewing Nebula Stats.

WHAT IT IS
A read-only system information utility. It displays live device statistics (CPU, memory, storage, battery, network, display refresh rate) using only public APIs: host_processor_info, host_statistics64, task_vm_info, FileManager volume capacity keys, UIDevice battery APIs, ProcessInfo thermal state, NWPathMonitor, getifaddrs, CoreTelephony radio technology, CADisplayLink, and UIScreen.

NO SETUP NEEDED
No account, no sign-in, no configuration. Every feature is available immediately on first launch. A short skippable overlay tour explains the dashboard.

PERMISSIONS & PRIVACY
The app requests no permissions of any kind (no location, camera, contacts, photos, or notifications). The privacy label is "Data Not Collected": there are no analytics, trackers, or third-party SDKs. Settings and speed-test history are stored only in the app container.

NETWORK USE (both user-initiated)
1) Speed test (Network tab → "Run test"): exchanges randomized test traffic with Cloudflare's public measurement service (speed.cloudflare.com) to measure latency, download, and upload. Data volume is capped (~80 MB per run) and runs are client-side rate-limited (3-minute spacing) to respect the service.
2) "Fetch public IP": a single request to api.ipify.org; the response is displayed on screen and not stored.
All other features work fully offline / in airplane mode.

BENCHMARK ("Nebula Score")
A ~6-second CPU benchmark running deterministic integer math. It reads ProcessInfo.thermalState before starting and between phases, and refuses to run if the device is already warm. It writes nothing, changes nothing, and uses no private APIs. Cross-chip comparison bars are labeled as approximate ratios; the user's own bar is the measured value.

DISPLAY NOTES
The FPS meter observes CADisplayLink callbacks (it does not force a frame rate). On 60 Hz devices it tops out at 60 and the app labels this; on ProMotion devices the "Stress" toggle drives the panel to 120 Hz. Low Power Mode caps all displays at 60 Hz — expected iOS behavior.

RATING PROMPT
Uses only the native StoreKit requestReview API, triggered after several completed user actions, at most once per version. No custom review prompts.

## Reminders
- Category: Utilities. Secondary: Developer Tools (optional).
- Privacy label: Data Not Collected.
- Privacy Policy URL + Support URL: host NebulaStats.html and use its URL (policy anchor: #privacy).
- After the app record exists: fill appStoreID in ReviewPromptCoordinator.swift and the App Store link in NebulaStats.html.
