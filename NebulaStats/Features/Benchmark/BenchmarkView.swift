import SwiftUI

/// Full-screen engine test: an animated orb while the workload runs, then
/// the Nebula Score with a relative chip comparison.
struct BenchmarkView: View {
    @Environment(StatsHub.self) private var hub
    @Environment(\.dismiss) private var dismiss

    private var engine: BenchmarkEngine { hub.benchmark }

    var body: some View {
        ZStack {
            NebulaBackground(style: .speedTest)

            if engine.phase == .finished, let score = engine.latest {
                resultsScreen(score)
            } else if engine.phase == .tooWarm {
                coolDownScreen
            } else {
                runningScreen
            }
        }
        .onAppear { engine.start() }
        .onChange(of: engine.phase) { _, newPhase in
            if newPhase == .finished {
                hub.reviewPrompt.registerSignificantAction()
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
                Text(DeviceCatalog.chipName.uppercased())
                    .font(.mono(10))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                phaseWord("SINGLE-CORE", isActive: engine.phase == .singleCore)
                Text("·").font(.sans(9, .semibold)).foregroundStyle(Theme.textDisabled)
                phaseWord("MULTI-CORE", isActive: engine.phase == .multiCore)
            }
            .padding(.top, 34)

            Spacer()

            spinningOrb
            Text(engine.phase == .multiCore
                 ? "ALL \(ProcessInfo.processInfo.activeProcessorCount) CORES ENGAGED"
                 : "ONE CORE AT FULL THRUST")
                .font(.mono(10))
                .kerning(1)
                .foregroundStyle(Theme.textMicro)
                .padding(.top, 26)

            Spacer()

            safetyNote
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    /// Plain-language reassurance, backed by the engine's real thermal guard.
    private var safetyNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "shield")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.aurora)
                MicroLabel(text: "Safe by design", size: 8)
            }
            Text("This is ordinary math — the same kind of work a game gives your chip, just for \(Int(BenchmarkEngine.phaseDuration * 2)) seconds. Nothing on your device is touched or changed. We read iOS's thermal sensor before and during the run and stop if your device is warm — and iOS itself always has the final say on heat.")
                .font(.sans(11))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .glassCard(border: Theme.aurora.opacity(0.2), padding: 14)
    }

    /// Shown when the thermal guard refused to run or aborted mid-test.
    private var coolDownScreen: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Text(DeviceCatalog.chipName.uppercased())
                    .font(.mono(10))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)
            Spacer()
            Image(systemName: "thermometer.medium")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.warning)
                .shadow(color: Theme.warning.opacity(0.6), radius: 5)
            Text("Let it cool down first")
                .font(.sans(16, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Your device is already running warm, so the test won't start — that's the safety check doing its job. Give it a few minutes and try again.")
                .font(.sans(12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private var spinningOrb: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(Theme.gaugeGradient,
                                style: StrokeStyle(lineWidth: 5 - CGFloat(ring), lineCap: .round))
                        .frame(width: 120 - CGFloat(ring) * 28,
                               height: 120 - CGFloat(ring) * 28)
                        .rotationEffect(.degrees(time * (80 + Double(ring) * 60)
                            * (ring % 2 == 0 ? 1 : -1)))
                }
                Circle()
                    .fill(Theme.logoGradient)
                    .frame(width: 26, height: 26)
                    .shadow(color: Theme.cyan.opacity(0.8), radius: 6)
            }
        }
        .frame(width: 130, height: 130)
        .accessibilityLabel("Benchmark running")
    }

    private func phaseWord(_ word: String, isActive: Bool) -> some View {
        Text(word)
            .font(.sans(9, .semibold))
            .kerning(2)
            .foregroundStyle(isActive ? Theme.violetBright : Theme.textDisabled)
            .shadow(color: isActive ? Theme.violetBright.opacity(0.7) : .clear, radius: 4)
    }

    // MARK: - Results

    private func resultsScreen(_ score: BenchmarkEngine.Score) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.sans(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(score.date.formatted(date: .omitted, time: .shortened))
                    .font(.mono(10))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)

            VStack(spacing: 4) {
                MicroLabel(text: "Nebula Score", size: 10)
                Text("\(score.total)")
                    .font(.mono(58, .semibold))
                    .foregroundStyle(Theme.textHero)
                    .shadow(color: Theme.violet.opacity(0.4), radius: 9)
                if let best = engine.best, best.total > score.total {
                    Text("BEST \(best.total)")
                        .font(.mono(10))
                        .foregroundStyle(Theme.textMuted)
                } else {
                    StatusPill(text: "New best", color: Theme.aurora)
                }
            }
            .padding(.top, 30)

            HStack(spacing: 12) {
                scoreTile("SINGLE-CORE", score.single)
                scoreTile("MULTI-CORE", score.multi)
            }
            .padding(.top, 22)

            comparisonCard(score)
                .padding(.top, 12)

            Spacer()

            Button("Run again") { engine.start() }
                .buttonStyle(PrimaryButtonStyle())
            Button("Done") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private func scoreTile(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 6) {
            MicroLabel(text: label, size: 8)
            Text("\(value)")
                .font(.mono(22, .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 16, padding: 12)
    }

    /// Bars for nearby chips, scaled off the user's own measured score using
    /// known relative chip performance — the user's bar is real, the others
    /// are proportional estimates.
    private func comparisonCard(_ score: BenchmarkEngine.Score) -> some View {
        let userChip = DeviceCatalog.chipName
        let ratios = BenchmarkEngine.chipRatios
        let userRatio = ratios.first { $0.chip == userChip }?.multi ?? 150
        let scale = Double(score.multi) / userRatio
        let shown = nearbyChips(around: userChip)
        let maxValue = shown.map { $0.multi * scale }.max() ?? 1

        return VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: "Multi-core vs typical chips", size: 8)
            ForEach(shown, id: \.chip) { entry in
                let isUser = entry.chip == userChip
                let value = isUser ? Double(score.multi) : entry.multi * scale
                HStack(spacing: 8) {
                    Text(isUser ? "YOU · \(entry.chip)" : entry.chip)
                        .font(.mono(9, isUser ? .semibold : .regular))
                        .foregroundStyle(isUser ? Theme.violetBright : Theme.textMuted)
                        .frame(width: 110, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geometry in
                        Capsule()
                            .fill(isUser ? AnyShapeStyle(Theme.gaugeGradient)
                                         : AnyShapeStyle(Color.white.opacity(0.14)))
                            .frame(width: max(geometry.size.width * value / maxValue, 4))
                            .shadow(color: isUser ? Theme.violet.opacity(0.8) : .clear, radius: 3)
                    }
                    .frame(height: 6)
                    Text("\(Int(value))")
                        .font(.mono(9))
                        .foregroundStyle(isUser ? Theme.textPrimary : Theme.textDisabled)
                        .frame(width: 38, alignment: .trailing)
                }
            }
            Text("Estimates from typical chip ratios · your bar is measured")
                .font(.sans(9))
                .foregroundStyle(Theme.textMuted)
        }
        .glassCard(border: Theme.violet.opacity(0.24), padding: 14)
    }

    /// The user's chip plus up to four neighbours in the ratio table.
    private func nearbyChips(around chip: String) -> [(chip: String, single: Double, multi: Double)] {
        let ratios = BenchmarkEngine.chipRatios
        guard let index = ratios.firstIndex(where: { $0.chip == chip }) else {
            return Array(ratios.suffix(5))
        }
        let start = max(0, index - 2)
        let end = min(ratios.count, start + 5)
        return Array(ratios[max(0, end - 5)..<end])
    }
}
