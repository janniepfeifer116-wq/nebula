import UIKit

/// Reads battery level/state from UIDevice and power/thermal flags from
/// ProcessInfo. Call `enableMonitoring()` once at app start — UIDevice only
/// reports battery values while monitoring is on.
@MainActor
enum BatterySampler {

    struct Snapshot {
        /// 0...1, or nil when unknown (e.g. some simulators).
        let level: Double?
        let state: UIDevice.BatteryState
        let isLowPowerModeOn: Bool
        let thermalState: ProcessInfo.ThermalState
    }

    static func enableMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    static func sample() -> Snapshot {
        let rawLevel = UIDevice.current.batteryLevel
        return Snapshot(
            level: rawLevel >= 0 ? Double(rawLevel) : nil,
            state: UIDevice.current.batteryState,
            isLowPowerModeOn: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: ProcessInfo.processInfo.thermalState
        )
    }
}
