import SwiftUI

/// Full-screen speed test: phase indicator, the big semicircular gauge with
/// a live readout while running, and a results card when done.
struct SpeedTestView: View {
    @Environment(StatsHub.self) private var hub
    @Environment(\.dismiss) private var dismiss

    private var engine: SpeedTestEngine { hub.speedTest }

    var body: some View {
        ZStack {
            NebulaBackground(style: .speedTest)

            switch engine.phase {
            case .finished:
                if let result = engine.result {
                    resultsScreen(result)
                } else {
                    runningScreen
                }
            default:
                runningScreen
            }
        }
        .onAppear {
            // Always begin a fresh run when the screen opens — a previous
            // run's result should never greet the user instead of a test.
            // (start() is a no-op while a run is already in flight.)
            engine.start()
        }
        .onChange(of: engine.phase) { _, newPhase in
            // Save every completed run into the 7-day history.
            if newPhase == .finished, let result = engine.result {
                hub.recordSpeedResult(result)
            }
        }
    }

    // MARK: - Running

    private var runningScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    engine.cancel()
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.sans(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("CLOUDFLARE · SPEED.CLOUDFLARE.COM")
                    .font(.mono(9))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)

            phaseIndicator
                .padding(.top, 34)

            SpeedGauge(mbps: engine.liveMbps)
                .frame(maxWidth: 300)
                .padding(.top, 26)

            VStack(spacing: 4) {
                Text(heroReadout)
                    .font(.mono(58, .semibold))
                    .foregroundStyle(Theme.textHero)
                    .shadow(color: Theme.cyan.opacity(0.4), radius: 9)
                    .contentTransition(.numericText())
                MicroLabel(text: heroCaption, color: Theme.cyanBright, size: 10)
            }
            .padding(.top, 8)

            if case .failed(let message) = engine.phase {
                Text(message)
                    .font(.sans(12))
                    .foregroundStyle(Theme.critical)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                Button("Try again") { engine.start() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 16)
            }

            Spacer()

            HStack(spacing: 12) {
                miniTile("PING", value: pingText)
                miniTile("DOWNLOAD", value: downloadText)
                miniTile("UPLOAD", value: uploadText)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private var phaseIndicator: some View {
        HStack(spacing: 8) {
            phaseWord("LATENCY", isActive: engine.phase == .measuringLatency)
            dotSeparator
            phaseWord("DOWNLOAD", isActive: engine.phase == .downloading)
            dotSeparator
            phaseWord("UPLOAD", isActive: engine.phase == .uploading)
        }
    }

    private var dotSeparator: some View {
        Text("·").font(.sans(9, .semibold)).foregroundStyle(Theme.textDisabled)
    }

    private func phaseWord(_ word: String, isActive: Bool) -> some View {
        Text(word)
            .font(.sans(9, .semibold))
            .kerning(2)
            .foregroundStyle(isActive ? Theme.cyanBright : Theme.textDisabled)
            .shadow(color: isActive ? Theme.cyanBright.opacity(0.7) : .clear, radius: 4)
    }

    private var heroReadout: String {
        switch engine.phase {
        case .measuringLatency:
            engine.livePingMs.map { String(format: "%.0f", $0) } ?? "…"
        case .downloading, .uploading:
            String(format: "%.1f", engine.liveMbps)
        case .failed:
            "--"
        default:
            "0.0"
        }
    }

    private var heroCaption: String {
        switch engine.phase {
        case .measuringLatency:
            engine.livePingMs == nil
                ? "CONNECTING…"
                : "MS · PING \(engine.pingCount)/\(SpeedTestEngine.pingRounds)"
        case .uploading:
            "MBPS · UPLOAD"
        default:
            "MBPS · DOWNLOAD"
        }
    }

    private var pingText: String {
        if let result = engine.result { return "\(Int(result.latencyMs.rounded())) ms" }
        if let live = engine.livePingMs { return "\(Int(live.rounded())) ms" }
        return pendingOrDone(.measuringLatency)
    }
    private var downloadText: String {
        engine.result.map { Format.megabits($0.downloadMbps) } ?? pendingOrDone(.downloading)
    }
    private var uploadText: String {
        engine.result.map { Format.megabits($0.uploadMbps) } ?? "--"
    }

    private func pendingOrDone(_ phase: SpeedTestEngine.Phase) -> String {
        engine.phase == phase ? "…" : "--"
    }

    private func miniTile(_ label: String, value: String) -> some View {
        VStack(spacing: 6) {
            MicroLabel(text: label, size: 8)
            Text(value)
                .font(.mono(15, .semibold))
                .foregroundStyle(value == "--" ? Theme.textDisabled : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 16, padding: 12)
    }

    // MARK: - Results

    private func resultsScreen(_ result: SpeedTestEngine.Result) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Network", systemImage: "chevron.left")
                        .font(.sans(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(Date.now.formatted(date: .omitted, time: .shortened))
                    .font(.mono(10))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Theme.aurora)
                    .shadow(color: Theme.aurora.opacity(0.6), radius: 4)
                Text("Test complete")
                    .font(.sans(15, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(qualitySummary(for: result.downloadMbps))
                    .font(.sans(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 36)

            resultCard(result)
                .padding(.top, 30)

            Spacer()

            Button("Test again") { engine.start() }
                .buttonStyle(PrimaryButtonStyle())
            Button("Done") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private func resultCard(_ result: SpeedTestEngine.Result) -> some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    MicroLabel(text: "▼ Download", size: 9)
                    Text(String(format: "%.1f", result.downloadMbps))
                        .font(.mono(34, .semibold))
                        .foregroundStyle(Theme.aurora)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    MicroLabel(text: "▲ Upload", size: 9)
                    Text(String(format: "%.1f", result.uploadMbps))
                        .font(.mono(34, .semibold))
                        .foregroundStyle(Theme.cyanBright)
                }
            }

            Divider().overlay(Theme.divider)

            HStack {
                Text("PING")
                    .foregroundStyle(Theme.textMicro)
                Text("\(Int(result.latencyMs.rounded())) ms")
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("MBPS")
                    .foregroundStyle(Theme.textMicro)
            }
            .font(.mono(11))

            HStack {
                Text("SERVER CLOUDFLARE")
                Spacer()
                Text(hub.networkPath.connection.rawValue.uppercased())
            }
            .font(.mono(10))
            .foregroundStyle(Theme.textMuted)
        }
        .glassCard(
            border: Theme.aurora.opacity(0.24),
            glow: Theme.aurora.opacity(0.18), glowRadius: 30,
            padding: 22
        )
    }

    private func qualitySummary(for downloadMbps: Double) -> String {
        switch downloadMbps {
        case 200...: "Your connection can stream 4K on several devices"
        case 50..<200: "Great for 4K streaming and video calls"
        case 10..<50: "Fine for HD streaming and browsing"
        default: "Good enough for browsing and music"
        }
    }
}
