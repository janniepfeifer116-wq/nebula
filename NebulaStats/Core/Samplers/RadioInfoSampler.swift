import CoreTelephony

/// Reads the current cellular radio technology (LTE, 5G, ...).
/// Devices without a cellular radio (Wi-Fi iPads, the simulator) return nil,
/// and the UI hides the cellular section entirely rather than showing blanks.
enum RadioInfoSampler {

    static func currentRadioTechnology() -> String? {
        let info = CTTelephonyNetworkInfo()
        guard let radios = info.serviceCurrentRadioAccessTechnology,
              let radio = radios.values.first
        else { return nil }
        return readableNames[radio] ?? "Cellular"
    }

    private static let readableNames: [String: String] = [
        CTRadioAccessTechnologyLTE: "4G LTE",
        CTRadioAccessTechnologyNR: "5G",
        CTRadioAccessTechnologyNRNSA: "5G",
        CTRadioAccessTechnologyWCDMA: "3G",
        CTRadioAccessTechnologyHSDPA: "3G",
        CTRadioAccessTechnologyHSUPA: "3G",
        CTRadioAccessTechnologyEdge: "EDGE",
        CTRadioAccessTechnologyGPRS: "GPRS",
    ]
}
