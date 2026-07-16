import Foundation

/// Translates Apple's internal model identifiers (e.g. "iPhone17,2") into
/// the names people actually know ("iPhone 16 Pro Max") plus the chip inside.
/// Unknown identifiers fall back to the raw identifier so the app never shows
/// wrong information for future devices.
enum DeviceCatalog {

    /// The hardware model identifier, e.g. "iPhone17,2".
    /// On the simulator, reports the simulated device's identifier.
    static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { rawBuffer in
            let data = Data(rawBuffer)
            return String(decoding: data.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }

    static var marketingName: String {
        names[modelIdentifier] ?? modelIdentifier
    }

    static var chipName: String {
        chips[modelIdentifier] ?? "Apple Silicon"
    }

    static var isRunningOnSimulator: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil
    }

    /// Approximate battery capacity in watt-hours, used to estimate charging
    /// power from level changes. Unknown models fall back to a middle-of-the-
    /// pack value — the estimate is labeled "~" everywhere it's shown.
    static var batteryCapacityWh: Double {
        batteryCapacities[modelIdentifier] ?? (modelIdentifier.hasPrefix("iPad") ? 28.0 : 13.0)
    }

    // MARK: - Lookup tables

    private static let names: [String: String] = [
        // iPhone 12
        "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        // iPhone 13 / SE 3
        "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,6": "iPhone SE (3rd gen)",
        // iPhone 14
        "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
        // iPhone 15
        "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        // iPhone 16
        "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,5": "iPhone 16e",
        // iPhone 17 / Air
        "iPhone18,3": "iPhone 17", "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max", "iPhone18,4": "iPhone Air",
        // iPads (recent)
        "iPad13,18": "iPad (10th gen)", "iPad13,19": "iPad (10th gen)",
        "iPad14,1": "iPad mini (6th gen)", "iPad14,2": "iPad mini (6th gen)",
        "iPad14,3": "iPad Pro 11\" (M2)", "iPad14,4": "iPad Pro 11\" (M2)",
        "iPad14,5": "iPad Pro 12.9\" (M2)", "iPad14,6": "iPad Pro 12.9\" (M2)",
        "iPad14,8": "iPad Air 11\" (M2)", "iPad14,9": "iPad Air 11\" (M2)",
        "iPad14,10": "iPad Air 13\" (M2)", "iPad14,11": "iPad Air 13\" (M2)",
        "iPad16,1": "iPad mini (A17 Pro)", "iPad16,2": "iPad mini (A17 Pro)",
        "iPad16,3": "iPad Pro 11\" (M4)", "iPad16,4": "iPad Pro 11\" (M4)",
        "iPad16,5": "iPad Pro 13\" (M4)", "iPad16,6": "iPad Pro 13\" (M4)",
    ]

    private static let batteryCapacities: [String: Double] = [
        "iPhone13,1": 8.57, "iPhone13,2": 10.78, "iPhone13,3": 10.78, "iPhone13,4": 14.13,
        "iPhone14,4": 9.34, "iPhone14,5": 12.41, "iPhone14,2": 12.41, "iPhone14,3": 16.75,
        "iPhone14,6": 7.82,
        "iPhone14,7": 12.68, "iPhone14,8": 16.68, "iPhone15,2": 12.38, "iPhone15,3": 16.68,
        "iPhone15,4": 13.28, "iPhone15,5": 17.10, "iPhone16,1": 13.19, "iPhone16,2": 17.32,
        "iPhone17,3": 13.61, "iPhone17,4": 18.06, "iPhone17,1": 13.94, "iPhone17,2": 18.31,
        "iPhone17,5": 15.55,
        "iPhone18,3": 13.90, "iPhone18,1": 15.30, "iPhone18,2": 19.00, "iPhone18,4": 12.26,
    ]

    private static let chips: [String: String] = [
        "iPhone13,1": "A14 Bionic", "iPhone13,2": "A14 Bionic",
        "iPhone13,3": "A14 Bionic", "iPhone13,4": "A14 Bionic",
        "iPhone14,4": "A15 Bionic", "iPhone14,5": "A15 Bionic",
        "iPhone14,2": "A15 Bionic", "iPhone14,3": "A15 Bionic",
        "iPhone14,6": "A15 Bionic",
        "iPhone14,7": "A15 Bionic", "iPhone14,8": "A15 Bionic",
        "iPhone15,2": "A16 Bionic", "iPhone15,3": "A16 Bionic",
        "iPhone15,4": "A16 Bionic", "iPhone15,5": "A16 Bionic",
        "iPhone16,1": "A17 Pro", "iPhone16,2": "A17 Pro",
        "iPhone17,3": "A18", "iPhone17,4": "A18",
        "iPhone17,1": "A18 Pro", "iPhone17,2": "A18 Pro",
        "iPhone17,5": "A18",
        "iPhone18,3": "A19", "iPhone18,1": "A19 Pro",
        "iPhone18,2": "A19 Pro", "iPhone18,4": "A19 Pro",
        "iPad14,3": "Apple M2", "iPad14,4": "Apple M2",
        "iPad14,5": "Apple M2", "iPad14,6": "Apple M2",
        "iPad14,8": "Apple M2", "iPad14,9": "Apple M2",
        "iPad14,10": "Apple M2", "iPad14,11": "Apple M2",
        "iPad16,1": "A17 Pro", "iPad16,2": "A17 Pro",
        "iPad16,3": "Apple M4", "iPad16,4": "Apple M4",
        "iPad16,5": "Apple M4", "iPad16,6": "Apple M4",
    ]
}
