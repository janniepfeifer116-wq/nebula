import Foundation
import Observation

/// Runs a three-phase network speed test (latency → download → upload)
/// against Cloudflare's public speed endpoints. Only ever runs when the
/// user taps the start button, and can be cancelled mid-flight.
@MainActor
@Observable
final class SpeedTestEngine {

    enum Phase: Equatable {
        case idle
        case measuringLatency
        case downloading
        case uploading
        case finished
        case failed(String)
    }

    struct Result {
        let latencyMs: Double
        let downloadMbps: Double
        let uploadMbps: Double
    }

    private(set) var phase: Phase = .idle
    /// Live throughput for the gauge while a transfer phase runs.
    private(set) var liveMbps: Double = 0
    /// The most recent ping round-trip, shown live during the latency phase.
    private(set) var livePingMs: Double?
    /// How many ping rounds have completed (of `pingRounds`).
    private(set) var pingCount = 0
    private(set) var result: Result?

    enum CooldownReason: String {
        /// The server rate-limited us (429) — we honor its Retry-After.
        case serverLimit
        /// Our own pacing between successful runs, to stay under the
        /// server's byte-volume limits.
        case pacing
    }

    /// No new test can start before this moment. Persisted across launches.
    private(set) var cooldownUntil: Date?
    private(set) var cooldownReason: CooldownReason?

    static let pingRounds = 5

    private var runTask: Task<Void, Never>?

    /// Minimum gap between successful runs.
    private static let pacingInterval: TimeInterval = 3 * 60
    /// Backoff when the server rate-limits us without saying for how long.
    private static let fallbackRateLimitCooldown: TimeInterval = 15 * 60

    private struct RateLimited: Error {
        /// Server-provided Retry-After, when present.
        let retryAfter: TimeInterval?
    }

    init() {
        let storedUntil = UserDefaults.standard.double(forKey: "speedCooldownUntil")
        if storedUntil > Date().timeIntervalSince1970 {
            cooldownUntil = Date(timeIntervalSince1970: storedUntil)
            cooldownReason = UserDefaults.standard.string(forKey: "speedCooldownReason")
                .flatMap(CooldownReason.init(rawValue:)) ?? .pacing
        }
    }

    // Cloudflare rate-limits by transferred BYTES per IP (a token bucket),
    // and replies 429 + Retry-After when it's exceeded. So the test keeps
    // chunks small and caps its total appetite: the phase ends at the time
    // limit OR the chunk cap, whichever comes first. Fast connections finish
    // early with plenty of data; slow ones use the full window.
    private static let downloadURL = URL(string: "https://speed.cloudflare.com/__down?bytes=5000000")!
    private static let uploadURL = URL(string: "https://speed.cloudflare.com/__up")!
    private static let pingURL = URL(string: "https://speed.cloudflare.com/__down?bytes=1")!

    private static let downloadDuration: TimeInterval = 10
    private static let uploadDuration: TimeInterval = 6
    /// At most 12 × 5 MB down and 4 × 5 MB up per test (~80 MB total).
    private static let maxDownloadChunks = 12
    private static let maxUploadChunks = 4
    /// Upload payload size per transfer.
    private static let uploadPayloadSize = 5 * 1024 * 1024
    /// Gauge update cadence. 10 Hz reads as continuous motion.
    private static let gaugeTick: Duration = .milliseconds(100)

    func start() {
        guard runTask == nil else { return }
        if let until = cooldownUntil, until > Date() {
            phase = .failed(Self.cooldownMessage(until: until, reason: cooldownReason ?? .pacing))
            return
        }
        setCooldown(nil, reason: nil)
        result = nil
        runTask = Task {
            do {
                phase = .measuringLatency
                let latency = try await measureLatency()

                phase = .downloading
                let download = try await measureDownload()

                phase = .uploading
                let upload = try await measureUpload()

                result = Result(latencyMs: latency, downloadMbps: download, uploadMbps: upload)
                phase = .finished
                // Space out runs so normal use never trips the server's limits.
                setCooldown(Date().addingTimeInterval(Self.pacingInterval), reason: .pacing)
            } catch is CancellationError {
                phase = .idle
            } catch let limit as RateLimited {
                let until = Date().addingTimeInterval(limit.retryAfter ?? Self.fallbackRateLimitCooldown)
                setCooldown(until, reason: .serverLimit)
                phase = .failed(Self.cooldownMessage(until: until, reason: .serverLimit))
            } catch {
                phase = .failed("The test could not reach the server. Check your connection and try again.")
            }
            liveMbps = 0
            runTask = nil
        }
    }

    static func cooldownMessage(until: Date, reason: CooldownReason) -> String {
        let minutes = max(1, Int(until.timeIntervalSinceNow / 60) + 1)
        switch reason {
        case .serverLimit:
            return "The test server is limiting this network right now. It lifts automatically — try again in about \(minutes) min."
        case .pacing:
            return "Runs are spaced out to stay under the server's limits. Next test in about \(minutes) min."
        }
    }

    private func setCooldown(_ until: Date?, reason: CooldownReason?) {
        cooldownUntil = until
        cooldownReason = reason
        UserDefaults.standard.set(until?.timeIntervalSince1970 ?? 0, forKey: "speedCooldownUntil")
        UserDefaults.standard.set(reason?.rawValue, forKey: "speedCooldownReason")
    }

    func cancel() {
        runTask?.cancel()
        runTask = nil
        phase = .idle
        liveMbps = 0
    }

    // MARK: - Phases

    /// Best (lowest) round-trip time of several tiny requests, in
    /// milliseconds. A throwaway request first absorbs the TLS/connection
    /// setup cost, so it neither inflates the readings nor stalls the UI —
    /// after it, each ping is a bare round-trip published live.
    private func measureLatency() async throws -> Double {
        let session = makeSession()
        defer { session.invalidateAndCancel() }

        livePingMs = nil
        pingCount = 0
        let (_, warmup) = try await session.data(from: Self.pingURL) // connection warm-up
        try Self.ensureNotRateLimited(warmup)

        var best = Double.infinity
        for round in 1...Self.pingRounds {
            try Task.checkCancellation()
            let started = ContinuousClock.now
            let (_, response) = try await session.data(from: Self.pingURL)
            try Self.ensureNotRateLimited(response)
            let milliseconds = started.duration(to: .now).milliseconds
            best = min(best, milliseconds)
            livePingMs = milliseconds
            pingCount = round
        }
        return best
    }

    /// Detects a 429 on the small latency requests, so a rate-limited network
    /// fails fast with the right message instead of a generic error.
    private nonisolated static func ensureNotRateLimited(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 429 || http.statusCode == 503 {
            throw RateLimited(retryAfter: retryAfterSeconds(from: http))
        }
    }

    nonisolated static func retryAfterSeconds(from response: HTTPURLResponse) -> TimeInterval? {
        response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
    }

    /// Downloads payloads back-to-back for the full phase duration while a
    /// delegate counts arriving bytes. The result is total bytes over total
    /// elapsed time.
    private func measureDownload() async throws -> Double {
        let started = ContinuousClock.now
        var totalBytes = 0
        var chunks = 0
        liveMbps = 0

        while started.duration(to: .now).seconds < Self.downloadDuration,
              chunks < Self.maxDownloadChunks {
            chunks += 1
            let meter = TransferMeter()
            let session = makeSession(delegate: meter)
            defer { session.invalidateAndCancel() }

            let task = session.dataTask(with: Self.downloadURL)
            task.resume()

            var transferBytes = 0
            while !meter.isFinished {
                try await Task.sleep(for: Self.gaugeTick)
                try Task.checkCancellation()
                transferBytes = meter.receivedBytes
                let seconds = started.duration(to: .now).seconds
                publishLive(megabitsPerSecond(bytes: totalBytes + transferBytes, seconds: seconds))
                if seconds >= Self.downloadDuration {
                    task.cancel()
                    break
                }
            }
            transferBytes = max(transferBytes, meter.receivedBytes)
            try Self.checkTransferHealth(meter, bytesSoFar: totalBytes + transferBytes)
            totalBytes += transferBytes
        }

        let seconds = started.duration(to: .now).seconds
        return megabitsPerSecond(bytes: totalBytes, seconds: seconds)
    }

    /// Uploads payloads back-to-back for the full phase duration while the
    /// delegate reports sent bytes, so the gauge stays live throughout.
    private func measureUpload() async throws -> Double {
        var payload = Data(count: Self.uploadPayloadSize)
        payload.withUnsafeMutableBytes { buffer in
            _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
        var request = URLRequest(url: Self.uploadURL)
        request.httpMethod = "POST"

        let started = ContinuousClock.now
        var totalBytes = 0
        var chunks = 0
        liveMbps = 0

        while started.duration(to: .now).seconds < Self.uploadDuration,
              chunks < Self.maxUploadChunks {
            chunks += 1
            let meter = TransferMeter()
            let session = makeSession(delegate: meter)
            defer { session.invalidateAndCancel() }

            let task = session.uploadTask(with: request, from: payload)
            task.resume()

            var transferBytes = 0
            while !meter.isFinished {
                try await Task.sleep(for: Self.gaugeTick)
                try Task.checkCancellation()
                transferBytes = meter.sentBytes
                let seconds = started.duration(to: .now).seconds
                publishLive(megabitsPerSecond(bytes: totalBytes + transferBytes, seconds: seconds))
                if seconds >= Self.uploadDuration {
                    task.cancel()
                    break
                }
            }
            transferBytes = max(transferBytes, meter.sentBytes)
            try Self.checkTransferHealth(meter, bytesSoFar: totalBytes + transferBytes)
            totalBytes += transferBytes
        }

        let seconds = started.duration(to: .now).seconds
        return megabitsPerSecond(bytes: totalBytes, seconds: seconds)
    }

    /// Blends new readings into the displayed value so the needle glides
    /// instead of jumping, especially in the first seconds of a phase.
    private func publishLive(_ raw: Double) {
        liveMbps = liveMbps == 0 ? raw : liveMbps * 0.7 + raw * 0.3
    }

    /// Fails the run when a transfer went wrong instead of quietly measuring
    /// an error page as ~0 Mbps. 429/503 mean the server is rate-limiting us
    /// and trigger the cooldown; other bad statuses and transport errors are
    /// plain failures (unless we already have real data to average).
    private nonisolated static func checkTransferHealth(
        _ meter: TransferMeter, bytesSoFar: Int
    ) throws {
        if let status = meter.statusCode {
            if status == 429 || status == 503 {
                throw RateLimited(retryAfter: meter.retryAfterSeconds)
            }
            if !(200..<300).contains(status) { throw URLError(.badServerResponse) }
        }
        if bytesSoFar == 0, let failure = meter.failure {
            throw failure
        }
    }

    // MARK: - Helpers

    private func megabitsPerSecond(bytes: Int, seconds: Double) -> Double {
        guard seconds > 0 else { return 0 }
        return Double(bytes) * 8 / seconds / 1_000_000
    }

    private func makeSession(delegate: URLSessionDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}

/// Thread-safe byte counter fed by URLSession delegate callbacks.
/// A delegate (rather than AsyncBytes) is essential here: per-byte async
/// iteration tops out far below fast Wi-Fi speeds and would measure the
/// CPU instead of the network.
private final class TransferMeter: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var _receivedBytes = 0
    private var _sentBytes = 0
    private var _isFinished = false
    private var _failure: Error?
    private var _statusCode: Int?
    private var _retryAfterSeconds: TimeInterval?

    var receivedBytes: Int { lock.withLock { _receivedBytes } }
    var sentBytes: Int { lock.withLock { _sentBytes } }
    var isFinished: Bool { lock.withLock { _isFinished } }
    var failure: Error? { lock.withLock { _failure } }
    var statusCode: Int? { lock.withLock { _statusCode } }
    var retryAfterSeconds: TimeInterval? { lock.withLock { _retryAfterSeconds } }

    func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        lock.withLock {
            _statusCode = (response as? HTTPURLResponse)?.statusCode
            _retryAfterSeconds = (response as? HTTPURLResponse)
                .flatMap(SpeedTestEngine.retryAfterSeconds(from:))
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { _receivedBytes += data.count }
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64
    ) {
        lock.withLock { _sentBytes = Int(totalBytesSent) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.withLock {
            _isFinished = true
            _failure = error
        }
    }
}

private extension Duration {
    var seconds: Double { Double(components.seconds) + Double(components.attoseconds) / 1e18 }
    var milliseconds: Double { seconds * 1000 }
}
