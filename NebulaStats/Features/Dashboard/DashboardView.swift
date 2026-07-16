import SwiftUI

/// Home screen: the CPU hero card over a two-column grid of live summary
/// cards. Tapping a card jumps to its detail tab.
struct DashboardView: View {
    @Environment(StatsHub.self) private var hub
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedTab: AppTab
    let openSettings: () -> Void
    @State private var showsBenchmark = false

    @AppStorage("hasSeenDashboardTour") private var hasSeenTour = false
    /// Current tour step, or nil when the tour isn't showing.
    @State private var tourStep: Int?

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView {
                VStack(spacing: 12) {
                    // On iPad the sidebar carries the brand and settings row,
                    // so the in-content header is iPhone-only.
                    if horizontalSizeClass != .regular {
                        header
                    }

                    cpuHeroCard
                        .onTapGesture { selectedTab = .performance }
                        .tourTarget(.cpu)
                        .id(TourTarget.cpu)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 12) {
                            memoryCard.onTapGesture { selectedTab = .performance }
                                .tourTarget(.memory).id(TourTarget.memory)
                            batteryCard.onTapGesture { selectedTab = .display }
                                .tourTarget(.battery).id(TourTarget.battery)
                            displayCard.onTapGesture { selectedTab = .display }
                                .tourTarget(.display).id(TourTarget.display)
                        }
                        VStack(spacing: 12) {
                            storageCard.onTapGesture { selectedTab = .performance }
                                .tourTarget(.storage).id(TourTarget.storage)
                            networkCard.onTapGesture { selectedTab = .network }
                                .tourTarget(.network).id(TourTarget.network)
                        }
                    }

                    benchmarkCard
                        .tourTarget(.score)
                        .id(TourTarget.score)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90) // clear the floating tab bar
            }
            .overlayPreferenceValue(TourAnchorKey.self) { anchors in
                if let step = tourStep {
                    TourOverlay(
                        stepIndex: step,
                        anchors: anchors,
                        onNext: { advanceTour() },
                        onSkip: { endTour() }
                    )
                }
            }
            .onChange(of: tourStep) { _, step in
                guard let step, let target = DashboardTour.steps[step].target else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    scroller.scrollTo(target, anchor: UnitPoint(x: 0.5, y: 0.35))
                }
            }
        }
        .fullScreenCover(isPresented: $showsBenchmark) {
            BenchmarkView()
        }
        .onAppear(perform: maybeStartTour)
        .onChange(of: hasSeenTour) { _, seen in
            // Settings' "Replay dashboard tour" resets the flag.
            if !seen { withAnimation { tourStep = 0 } }
        }
    }

    // MARK: - Tour control

    private func maybeStartTour() {
        guard !hasSeenTour, tourStep == nil else { return }
        Task {
            // Give the cards a beat to lay out before spotlighting them.
            try? await Task.sleep(for: .seconds(0.8))
            if !hasSeenTour { withAnimation { tourStep = 0 } }
        }
    }

    private func advanceTour() {
        guard let step = tourStep else { return }
        if step >= DashboardTour.steps.count - 1 {
            endTour()
        } else {
            withAnimation { tourStep = step + 1 }
        }
    }

    private func endTour() {
        withAnimation { tourStep = nil }
        hasSeenTour = true
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Nebula")
                    .font(.sans(20, .bold))
                    .kerning(0.5)
                    .foregroundStyle(Theme.textPrimary)
                Text("STATS")
                    .font(.sans(10, .semibold))
                    .kerning(2.5)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.textMicro)
                    .shadow(color: Theme.textMicro.opacity(0.5), radius: 2)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Cards

    private var cpuHeroCard: some View {
        HStack(spacing: 20) {
            GaugeOrb(value: hub.cpu?.totalLoad, diameter: 118)

            VStack(alignment: .leading, spacing: 8) {
                MicroLabel(text: "CPU Load", size: 10)
                if let cpu = hub.cpu {
                    let (performance, efficiency) = coreSplit(cpu.perCoreLoad)
                    monoStatRow("PERF", Format.percent(performance), Theme.violetBright)
                    monoStatRow("EFF", Format.percent(efficiency), Theme.cyanBright)
                }
                monoStatRow(DeviceCatalog.chipName.uppercased(),
                            hub.cpu.map { "\($0.perCoreLoad.count) CORES" } ?? "",
                            Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .glassCard(
            border: Theme.violet.opacity(0.28),
            fill: Theme.cardHero,
            glow: Theme.violetCTA.opacity(0.30), glowRadius: 32,
            padding: 18
        )
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Memory", size: 9)
            if let memory = hub.memory {
                valueWithUnit(Format.bytes(memory.usedBytes), "/ \(Format.bytes(memory.totalBytes))")
                MemoryBar(fraction: memory.usedFraction)
                monoFootnote("\(Format.bytes(memory.totalBytes - memory.usedBytes)) FREE")
            } else {
                placeholderValue
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.cyanBright.opacity(0.2))
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Storage", size: 9)
            if let storage = hub.storage {
                HStack(spacing: 12) {
                    RingChart(fraction: storage.usedFraction, diameter: 58, lineWidth: 7)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Format.bytes(storage.usedBytes))
                            .font(.mono(20, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("of \(Format.bytes(storage.totalBytes))")
                            .font(.sans(10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                placeholderValue
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.violet.opacity(0.2))
    }

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Battery", size: 9)
            if let battery = hub.battery {
                valueWithUnit(battery.level.map { "\(Int(($0 * 100).rounded()))" } ?? "--", "%")
                if let pill = battery.statusPill {
                    StatusPill(text: pill.text, color: pill.color)
                }
                if battery.level == nil && DeviceCatalog.isRunningOnSimulator {
                    monoFootnote("NO BATTERY IN SIMULATOR")
                } else if let power = hub.chargingPower.estimate {
                    Text("⚡ ~\(Int(power.watts.rounded())) W")
                        .font(.mono(11, .semibold))
                        .foregroundStyle(Theme.aurora)
                } else if hub.chargingPower.isMeasuring {
                    monoFootnote("MEASURING CHARGE RATE…")
                } else {
                    monoFootnote("THERMAL · \(battery.thermalState.label.uppercased())")
                }
            } else {
                placeholderValue
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.aurora.opacity(0.2))
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Network", size: 9)
            HStack(spacing: 8) {
                Text("▼ \(Format.byteRate(hub.downloadBytesPerSecond))")
                    .font(.mono(11, .semibold))
                    .foregroundStyle(Theme.aurora)
                Text("▲ \(Format.byteRate(hub.uploadBytesPerSecond))")
                    .font(.mono(11, .semibold))
                    .foregroundStyle(Theme.cyanBright)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            SparklineChart(
                values: hub.downloadHistory.values,
                maxValue: nil,
                color: Theme.aurora,
                showsAreaFill: true
            )
            .frame(height: 30)

            monoFootnote(hub.networkPath.connection.rawValue.uppercased())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.cyanBright.opacity(0.2))
    }

    private var displayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Display", size: 9)
            valueWithUnit("\(Int(hub.fpsMonitor.currentFPS.rounded()))", "FPS")
            monoFootnote(hub.fpsMonitor.maximumFPS > 60
                         ? "PROMOTION · \(hub.fpsMonitor.maximumFPS) HZ MAX"
                         : "\(hub.fpsMonitor.maximumFPS) HZ PANEL")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(border: Theme.violet.opacity(0.2))
    }

    /// Full-width Nebula Score card: shows the best score once one exists,
    /// otherwise invites the first run.
    private var benchmarkCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                MicroLabel(text: "Nebula Score", size: 9)
                if let best = hub.benchmark.best {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(best.total)")
                            .font(.mono(26, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("SINGLE \(best.single) · MULTI \(best.multi)")
                            .font(.mono(10))
                            .foregroundStyle(Theme.textMuted)
                    }
                } else {
                    Text("Measure your chip's thrust")
                        .font(.sans(13, .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A \(Int(BenchmarkEngine.phaseDuration * 2))-second engine test, fully on-device")
                        .font(.sans(10))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Button(hub.benchmark.best == nil ? "Run test" : "Again") {
                showsBenchmark = true
            }
            .buttonStyle(PrimaryButtonStyle(small: true))
        }
        .glassCard(
            border: Theme.violet.opacity(0.28),
            fill: Theme.cardHero,
            glow: Theme.violetCTA.opacity(0.24), glowRadius: 24
        )
    }

    // MARK: - Small shared pieces

    private func valueWithUnit(_ value: String, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.mono(24, .semibold))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.sans(11))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func monoStatRow(_ label: String, _ value: String, _ valueColor: Color) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(Theme.textMuted)
            Text(value).foregroundStyle(valueColor)
        }
        .font(.mono(12, .semibold))
    }

    private func monoFootnote(_ text: String) -> some View {
        Text(text)
            .font(.mono(10))
            .foregroundStyle(Theme.textMuted)
    }

    private var placeholderValue: some View {
        Text("--")
            .font(.mono(24, .semibold))
            .foregroundStyle(Theme.textDisabled)
    }

    /// Average load of the first-half vs second-half core groups. Apple lists
    /// performance cores first, so this approximates the P/E split.
    private func coreSplit(_ loads: [Double]) -> (performance: Double, efficiency: Double) {
        guard loads.count >= 2 else { return (loads.first ?? 0, 0) }
        let performanceCount = max(loads.count / 3, 2)
        let performance = loads.prefix(performanceCount)
        let efficiency = loads.dropFirst(performanceCount)
        return (
            performance.reduce(0, +) / Double(performance.count),
            efficiency.isEmpty ? 0 : efficiency.reduce(0, +) / Double(efficiency.count)
        )
    }
}

// MARK: - Battery presentation helpers

extension BatterySampler.Snapshot {
    /// The most relevant status pill for the battery card, or nil when idle.
    var statusPill: (text: String, color: Color)? {
        if thermalState == .serious || thermalState == .critical {
            return ("THERMAL", Theme.critical)
        }
        if isLowPowerModeOn { return ("LOW POWER", Theme.warning) }
        switch state {
        case .charging: return ("CHARGING", Theme.aurora)
        case .full: return ("FULL", Theme.aurora)
        default: return nil
        }
    }
}

extension ProcessInfo.ThermalState {
    var label: String {
        switch self {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }
}
