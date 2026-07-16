import Foundation
import Observation

/// Estimates live charging power by watching battery-level steps.
///
/// iOS reports the battery level in 1% increments. The first step we see
/// only ANCHORS the clock — we can't know when the previous step happened,
/// so timing from "measurement started" wildly overestimates power. Real
/// readings are computed strictly between two consecutive observed steps.
///
/// On slow chargers that takes a couple of minutes; near a full battery,
/// charging trickles or pauses entirely (Optimized Charging), so if no step
/// arrives within the timeout we stop claiming to measure and show nothing.
@MainActor
@Observable
final class ChargingPowerEstimator {

    struct Estimate {
        /// Approximate charging power in watts.
        let watts: Double
    }

    private(set) var estimate: Estimate?
    /// True while charging and still waiting for enough level steps.
    private(set) var isMeasuring = false

    /// Readings outside this band are discarded as timing noise —
    /// no phone or iPad draws more than ~60 W from any charger.
    private static let plausibleWatts = 0.5...60.0
    /// Steps further apart than the sampler could reliably time are ignored.
    private static let minimumStepSeconds: TimeInterval = 10
    /// Give up on "measuring…" if no step arrives for this long.
    private static let measuringTimeout: TimeInterval = 4 * 60

    private var anchor: (level: Double, at: Date)?
    /// True once the anchor comes from an observed step (not from whenever
    /// measurement happened to start), making the next interval trustworthy.
    private var anchorIsRealStep = false
    private var smoothedWatts: Double?
    private var measuringSince: Date?

    /// Feed every battery snapshot here; the estimator ignores non-charging ones.
    func update(level: Double?, isCharging: Bool) {
        guard isCharging, let level else {
            reset()
            return
        }

        guard let anchor else {
            startMeasuring(at: level)
            return
        }

        if level < anchor.level {
            // Level went down while "charging" — cable swap or stale state.
            reset()
            startMeasuring(at: level)
            return
        }

        if level > anchor.level {
            recordStep(from: anchor, to: level)
            return
        }

        // No step yet — stop promising a reading if it's clearly not coming
        // (trickle charging near full, or charging paused by iOS).
        if estimate == nil, isMeasuring,
           let since = measuringSince,
           Date().timeIntervalSince(since) > Self.measuringTimeout {
            isMeasuring = false
        }
    }

    // MARK: - Internals

    private func startMeasuring(at level: Double) {
        anchor = (level, Date())
        anchorIsRealStep = false
        isMeasuring = true
        measuringSince = Date()
    }

    private func recordStep(from anchor: (level: Double, at: Date), to level: Double) {
        let now = Date()
        defer {
            self.anchor = (level, now)
            anchorIsRealStep = true // step-to-step intervals are reliable from here on
        }

        guard anchorIsRealStep else { return } // first step only anchors the clock

        let elapsed = now.timeIntervalSince(anchor.at)
        guard elapsed >= Self.minimumStepSeconds else { return }

        let stepEnergyWh = (level - anchor.level) * DeviceCatalog.batteryCapacityWh
        let watts = stepEnergyWh * 3600 / elapsed
        guard Self.plausibleWatts.contains(watts) else { return }

        smoothedWatts = smoothedWatts.map { $0 * 0.6 + watts * 0.4 } ?? watts
        estimate = Estimate(watts: smoothedWatts ?? watts)
        isMeasuring = false
    }

    private func reset() {
        anchor = nil
        anchorIsRealStep = false
        smoothedWatts = nil
        estimate = nil
        isMeasuring = false
        measuringSince = nil
    }
}
