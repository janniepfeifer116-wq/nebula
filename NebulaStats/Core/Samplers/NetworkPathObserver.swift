import Network
import Observation

/// Watches the device's active network path with NWPathMonitor and republishes
/// it as observable state on the main actor.
@MainActor
@Observable
final class NetworkPathObserver {

    enum ConnectionKind: String {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wired = "Wired"
        case other = "Other"
        case offline = "Offline"
    }

    private(set) var connection: ConnectionKind = .offline
    private(set) var supportsIPv4 = false
    private(set) var supportsIPv6 = false
    /// True on paths the system flags as costly to the user (personal hotspot, some cellular).
    private(set) var isExpensive = false
    /// True when Low Data Mode restricts this path.
    private(set) var isConstrained = false

    private let monitor = NWPathMonitor()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.apply(path)
            }
        }
        monitor.start(queue: DispatchQueue(label: "nebula.network-path"))
    }

    func stop() {
        monitor.cancel()
    }

    private func apply(_ path: NWPath) {
        if path.status != .satisfied {
            connection = .offline
        } else if path.usesInterfaceType(.wifi) {
            connection = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connection = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connection = .wired
        } else {
            connection = .other
        }
        supportsIPv4 = path.supportsIPv4
        supportsIPv6 = path.supportsIPv6
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }
}
