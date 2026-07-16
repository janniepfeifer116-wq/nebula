import Foundation
import Observation

/// The "engine test": a fixed-duration integer workload run first on one
/// core, then on all cores, producing a Nebula Score.
///
/// The workload is deterministic hashing math, so scores are comparable
/// between runs and devices. Cross-chip comparisons are shown as ratios
/// anchored to the user's own measured score (using well-known relative
/// performance between Apple chips), so no absolute number is ever invented.
@MainActor
@Observable
final class BenchmarkEngine {

    enum Phase: Equatable {
        case idle
        case singleCore
        case multiCore
        case finished
        /// The thermal guard refused to run: the device is already warm.
        case tooWarm
    }

    struct Score: Codable {
        let single: Int
        let multi: Int
        let date: Date
        let chip: String

        /// The headline Nebula Score: multi-core weighted, single-core counted.
        var total: Int { Int(Double(single) * 0.4 + Double(multi) * 0.6) }
    }

    private(set) var phase: Phase = .idle
    private(set) var latest: Score?
    private(set) var best: Score? = BenchmarkEngine.loadBest()

    /// Each phase runs this long.
    static let phaseDuration: TimeInterval = 3

    private var runTask: Task<Void, Never>?

    /// True when iOS reports the device is already running hot. The test
    /// refuses to start (or continue) in that state — this is the concrete
    /// "we check before we push" safety guarantee shown to the user.
    static var deviceIsWarm: Bool {
        let thermal = ProcessInfo.processInfo.thermalState
        return thermal == .serious || thermal == .critical
    }

    func start() {
        guard runTask == nil else { return }
        guard !Self.deviceIsWarm else {
            phase = .tooWarm
            return
        }
        latest = nil
        runTask = Task {
            phase = .singleCore
            let singleOps = await Self.crunch(threads: 1)

            // Re-check between phases; abort rather than push a warm device.
            if Self.deviceIsWarm {
                phase = .tooWarm
                runTask = nil
                return
            }

            phase = .multiCore
            let coreCount = ProcessInfo.processInfo.activeProcessorCount
            let multiOps = await Self.crunch(threads: coreCount)

            let score = Score(
                single: Self.score(from: singleOps),
                multi: Self.score(from: multiOps),
                date: Date(),
                chip: DeviceCatalog.chipName
            )
            latest = score
            if score.total > (best?.total ?? 0) {
                best = score
                Self.saveBest(score)
            }
            phase = .finished
            runTask = nil
        }
    }

    func cancel() {
        runTask?.cancel()
        runTask = nil
        phase = .idle
    }

    // MARK: - Workload

    /// Runs the hashing workload on `threads` parallel tasks for the phase
    /// duration and returns total operations completed.
    private nonisolated static func crunch(threads: Int) async -> UInt64 {
        let deadline = ContinuousClock.now.advanced(by: .seconds(phaseDuration))
        return await withTaskGroup(of: UInt64.self) { group in
            for _ in 0..<threads {
                group.addTask { crunchOneThread(until: deadline) }
            }
            return await group.reduce(0, +)
        }
    }

    /// FNV-style integer mixing in a tight loop — enough real data
    /// dependency that the compiler can't optimize the work away.
    private nonisolated static func crunchOneThread(until deadline: ContinuousClock.Instant) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        var operations: UInt64 = 0
        while ContinuousClock.now < deadline {
            for _ in 0..<50_000 {
                hash = (hash ^ operations) &* 0x0000_0100_0000_01B3
                hash ^= hash >> 33
                operations &+= 1
            }
        }
        // Consume the hash so the loop above has an observable result.
        return hash == 0 ? operations &+ 1 : operations
    }

    /// Millions of operations per phase, scaled into a friendly range.
    private nonisolated static func score(from operations: UInt64) -> Int {
        Int(operations / 2_000_000)
    }

    // MARK: - Chip comparison (relative)

    /// Relative performance of recent Apple chips (A14 = 100), based on
    /// public single/multi-core benchmark ratios. Used only to scale bars
    /// around the user's own measured score.
    static let chipRatios: [(chip: String, single: Double, multi: Double)] = [
        ("A14 Bionic", 100, 100),
        ("A15 Bionic", 108, 120),
        ("A16 Bionic", 118, 133),
        ("A17 Pro", 135, 154),
        ("A18", 142, 162),
        ("A18 Pro", 148, 171),
        ("A19", 158, 187),
        ("A19 Pro", 165, 200),
        ("Apple M2", 120, 229),
        ("Apple M4", 165, 333),
    ]

    // MARK: - Persistence

    private static let bestKey = "bestBenchmarkScore"

    private static func loadBest() -> Score? {
        guard let data = UserDefaults.standard.data(forKey: bestKey) else { return nil }
        return try? JSONDecoder().decode(Score.self, from: data)
    }

    private static func saveBest(_ score: Score) {
        if let data = try? JSONEncoder().encode(score) {
            UserDefaults.standard.set(data, forKey: bestKey)
        }
    }
}
