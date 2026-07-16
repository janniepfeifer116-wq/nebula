import SwiftUI

/// Live FPS readout with a stress toggle, plus display, device and battery
/// details. The stress animation forces ProMotion panels to ramp to 120 Hz,
/// which makes the FPS number fun to watch.
struct DisplayDeviceView: View {
    @Environment(StatsHub.self) private var hub
    @State private var isStressing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ScreenHeader(title: "Display & Device", showsLiveBadge: true, interval: hub.refreshInterval)
                frameRateCard
                displayList
                deviceList
                batteryCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
        .onChange(of: isStressing) { _, on in
            if on { hub.reviewPrompt.registerSignificantAction() }
        }
    }

    // MARK: - Live frame rate

    private var frameRateCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    MicroLabel(text: "Live frame rate", size: 10)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(Int(hub.fpsMonitor.currentFPS.rounded()))")
                            .font(.mono(50, .semibold))
                            .foregroundStyle(Theme.textHero)
                            .shadow(color: Theme.violet.opacity(0.4), radius: 8)
                            .contentTransition(.numericText())
                        Text("FPS")
                            .font(.sans(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    MicroLabel(text: "Stress", size: 8)
                    Toggle("", isOn: $isStressing.animation())
                        .labelsHidden()
                        .tint(Theme.aurora.opacity(0.5))
                }
            }

            if isStressing {
                StressField()
                    .frame(height: 72)
                    .frame(maxWidth: .infinity)
                Text(hub.fpsMonitor.maximumFPS > 60
                     ? "DRIVING DISPLAY TO \(hub.fpsMonitor.maximumFPS) HZ"
                     : "THIS PANEL TOPS OUT AT \(hub.fpsMonitor.maximumFPS) HZ")
                    .font(.mono(9))
                    .kerning(1)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .glassCard(
            border: Theme.violet.opacity(0.28),
            fill: Theme.cardHero,
            glow: Theme.violetCTA.opacity(0.24),
            padding: 18
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Display info

    private var displayList: some View {
        let screen = UIScreen.main
        let pixels = CGSize(
            width: screen.nativeBounds.width,
            height: screen.nativeBounds.height
        )
        return KeyValueList(header: "Display", rows: [
            .init(label: "Resolution", value: "\(Int(pixels.width)) × \(Int(pixels.height))"),
            .init(label: "Refresh rate", value: "up to \(hub.fpsMonitor.maximumFPS) Hz"),
            .init(label: "Brightness", value: Format.percent(Double(screen.brightness))),
            .init(label: "Scale", value: "@\(Int(screen.scale))x"),
        ])
    }

    // MARK: - Device info

    private var deviceList: some View {
        KeyValueList(header: "Device", rows: [
            .init(label: "Model", value: DeviceCatalog.marketingName),
            .init(label: "Identifier", value: DeviceCatalog.modelIdentifier, isCopyable: true),
            .init(label: "Chip", value: DeviceCatalog.chipName),
            .init(label: "iOS", value: UIDevice.current.systemVersion),
            .init(label: "Uptime", value: Format.uptime(ProcessInfo.processInfo.systemUptime)),
        ])
    }

    // MARK: - Battery

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                MicroLabel(text: "Battery", size: 9)
                Spacer()
                if let pill = hub.battery?.statusPill {
                    StatusPill(text: pill.text, color: pill.color)
                }
            }
            if let battery = hub.battery {
                HStack(spacing: 18) {
                    batteryStat("LEVEL", battery.level.map { Format.percent($0) } ?? "--")
                    batteryStat("STATE", batteryStateLabel(battery.state))
                    batteryStat("THERMAL", battery.thermalState.label.uppercased(),
                                valueColor: battery.thermalState == .nominal ? Theme.aurora : Theme.warning)
                }
                if let power = hub.chargingPower.estimate {
                    batteryStat("POWER", "~\(Int(power.watts.rounded())) W", valueColor: Theme.aurora)
                } else if hub.chargingPower.isMeasuring {
                    Text("MEASURING CHARGE RATE — TAKES A FEW MINUTES")
                        .font(.mono(9))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.aurora.opacity(0.2))
    }

    private func batteryStat(_ label: String, _ value: String, valueColor: Color = Theme.textPrimary) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(Theme.textMicro)
            Text(value).foregroundStyle(valueColor)
        }
        .font(.mono(11))
    }

    private func batteryStateLabel(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging: "CHARGING"
        case .full: "FULL"
        case .unplugged: "ON BATTERY"
        default: DeviceCatalog.isRunningOnSimulator ? "SIMULATOR" : "UNKNOWN"
        }
    }
}

/// A swarm of glowing particles redrawn every frame. Its purpose is to keep
/// the render loop saturated so ProMotion panels ramp to their maximum
/// refresh rate — and to make it obvious on screen that the stress test is
/// running.
private struct StressField: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                // This closure runs every frame, so it must stay cheap:
                // no GraphicsContext filters (they stack up and can hang the
                // render loop) — each dot's glow is just a soft halo circle.
                let colors = [Theme.violet, Theme.cyan, Theme.aurora, Theme.magenta]
                for index in 0..<24 {
                    let phase = Double(index) / 24
                    let speed = 0.5 + phase * 2.0
                    let angle = time * speed + phase * .pi * 2
                    let x = size.width * (0.5 + 0.46 * Darwin.cos(angle))
                    let y = size.height * (0.5 + 0.42 * Darwin.sin(angle * 1.7 + phase * 3))
                    let dotSize = 2.5 + phase * 3.5
                    let color = colors[index % colors.count]

                    let halo = CGRect(x: x - dotSize * 1.5, y: y - dotSize * 1.5,
                                      width: dotSize * 3, height: dotSize * 3)
                    canvas.fill(Path(ellipseIn: halo), with: .color(color.opacity(0.22)))

                    let dot = CGRect(x: x - dotSize / 2, y: y - dotSize / 2,
                                     width: dotSize, height: dotSize)
                    canvas.fill(Path(ellipseIn: dot), with: .color(color.opacity(0.95)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
