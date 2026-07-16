import Foundation
import Observation
import SwiftUI

/// The app's single source of truth for live stats.
///
/// One instance lives at the root and is passed down through the environment.
/// It ticks a sampling loop once per second while the app is in the
/// foreground; RootView starts and stops it from scenePhase changes, so
/// nothing runs (and no battery is spent) in the background.
@MainActor
@Observable
final class StatsHub {

    // MARK: Latest snapshots

    private(set) var cpu: CPUSampler.Snapshot?
    private(set) var memory: MemorySampler.Snapshot?
    private(set) var storage: StorageSampler.Snapshot?
    private(set) var battery: BatterySampler.Snapshot?
    private(set) var byteCounts: InterfaceStatsSampler.ByteCounts?
    private(set) var localAddresses: [InterfaceStatsSampler.Address] = []
    private(set) var radioTechnology: String?

    // MARK: Live throughput (derived from byte-count deltas)

    private(set) var downloadBytesPerSecond: Double = 0
    private(set) var uploadBytesPerSecond: Double = 0

    // MARK: Chart histories (~60 samples ≈ one minute at the default interval)

    private(set) var cpuHistory = RingBuffer<Double>(capacity: 60)
    private(set) var memoryHistory = RingBuffer<Double>(capacity: 60)
    private(set) var downloadHistory = RingBuffer<Double>(capacity: 60)
    private(set) var uploadHistory = RingBuffer<Double>(capacity: 60)

    // MARK: Long-lived observers

    let networkPath = NetworkPathObserver()
    let fpsMonitor = FPSMonitor()
    let speedTest = SpeedTestEngine()
    let chargingPower = ChargingPowerEstimator()
    let benchmark = BenchmarkEngine()
    let reviewPrompt = ReviewPromptCoordinator()

    /// Speed test results from the last 7 days, newest first.
    private(set) var speedHistory: [SpeedTestRecord] = SpeedTestHistoryStore.load()

    // MARK: Public IP (fetched only when the user taps the button)

    private(set) var publicIP: String?
    private(set) var isFetchingPublicIP = false

    /// Seconds between samples — user-selectable in Settings (1 / 2 / 5).
    var refreshInterval: TimeInterval {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }

    private let cpuSampler = CPUSampler()
    private var samplingTask: Task<Void, Never>?
    private var previousByteReading: (counts: InterfaceStatsSampler.ByteCounts, at: Date)?

    init() {
        let stored = UserDefaults.standard.double(forKey: "refreshInterval")
        refreshInterval = stored > 0 ? stored : 1
    }

    // MARK: - Lifecycle

    func startSampling() {
        guard samplingTask == nil else { return }
        BatterySampler.enableMonitoring()
        networkPath.start()
        fpsMonitor.start()

        samplingTask = Task {
            while !Task.isCancelled {
                tick()
                try? await Task.sleep(for: .seconds(refreshInterval))
            }
        }
    }

    func stopSampling() {
        samplingTask?.cancel()
        samplingTask = nil
        fpsMonitor.stop()
        networkPath.stop()
        // Forget the last byte reading so the first tick after returning to
        // the foreground doesn't report the whole backgrounded period as a
        // one-second burst.
        previousByteReading = nil
    }

    // MARK: - Sampling

    private func tick() {
        if let cpuSnapshot = cpuSampler.sample() {
            cpu = cpuSnapshot
            cpuHistory.append(cpuSnapshot.totalLoad)
        }
        if let memorySnapshot = MemorySampler.sample() {
            memory = memorySnapshot
            memoryHistory.append(memorySnapshot.usedFraction)
        }
        storage = StorageSampler.sample()
        battery = BatterySampler.sample()
        if let battery {
            chargingPower.update(level: battery.level, isCharging: battery.state == .charging)
        }
        localAddresses = InterfaceStatsSampler.localAddresses()
        radioTechnology = RadioInfoSampler.currentRadioTechnology()
        updateThroughput()
    }

    private func updateThroughput() {
        guard let currentCounts = InterfaceStatsSampler.byteCounts() else { return }
        defer { previousByteReading = (currentCounts, Date()) }
        byteCounts = currentCounts

        guard let previous = previousByteReading else { return }
        let elapsed = Date().timeIntervalSince(previous.at)
        guard elapsed > 0 else { return }

        // Interface counters can reset (e.g. toggling Airplane Mode); a
        // negative delta means exactly that, so report zero for the tick.
        let receivedDelta = currentCounts.totalReceived >= previous.counts.totalReceived
            ? currentCounts.totalReceived - previous.counts.totalReceived : 0
        let sentDelta = currentCounts.totalSent >= previous.counts.totalSent
            ? currentCounts.totalSent - previous.counts.totalSent : 0

        downloadBytesPerSecond = Double(receivedDelta) / elapsed
        uploadBytesPerSecond = Double(sentDelta) / elapsed
        downloadHistory.append(downloadBytesPerSecond)
        uploadHistory.append(uploadBytesPerSecond)
    }

    // MARK: - Speed test history

    func recordSpeedResult(_ result: SpeedTestEngine.Result) {
        var connection = networkPath.connection.rawValue
        if networkPath.connection == .cellular, let radio = radioTechnology {
            connection = radio
        }
        speedHistory = SpeedTestHistoryStore.append(SpeedTestRecord(
            id: UUID(), date: Date(),
            downloadMbps: result.downloadMbps,
            uploadMbps: result.uploadMbps,
            latencyMs: result.latencyMs,
            connection: connection
        ))
        reviewPrompt.registerSignificantAction()
    }

    // MARK: - Public IP

    func fetchPublicIP() async {
        guard !isFetchingPublicIP else { return }
        isFetchingPublicIP = true
        defer { isFetchingPublicIP = false }

        do {
            let url = URL(string: "https://api.ipify.org")!
            let (data, _) = try await URLSession.shared.data(from: url)
            publicIP = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            reviewPrompt.registerSignificantAction()
        } catch {
            publicIP = nil
        }
    }
}
