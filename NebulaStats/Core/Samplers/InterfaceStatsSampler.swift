import Darwin
import Foundation

/// Walks the network interfaces with `getifaddrs` to read two things:
/// - cumulative bytes sent/received since boot, split into Wi-Fi (`en*`)
///   and cellular (`pdp_ip*`) interface families
/// - the device's local IP addresses
///
/// Live throughput is derived by the caller from deltas between reads.
enum InterfaceStatsSampler {

    struct ByteCounts {
        var wifiReceived: UInt64 = 0
        var wifiSent: UInt64 = 0
        var cellularReceived: UInt64 = 0
        var cellularSent: UInt64 = 0

        var totalReceived: UInt64 { wifiReceived + cellularReceived }
        var totalSent: UInt64 { wifiSent + cellularSent }
    }

    struct Address: Identifiable {
        let interface: String   // "en0", "pdp_ip0"...
        let ip: String
        let isIPv6: Bool
        var id: String { "\(interface)-\(ip)" }
    }

    static func byteCounts() -> ByteCounts? {
        var counts = ByteCounts()
        var found = false

        forEachInterface { name, ifa in
            guard ifa.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
                  let rawData = ifa.ifa_data else { return }
            let stats = rawData.assumingMemoryBound(to: if_data.self).pointee
            if name.hasPrefix("en") {
                counts.wifiReceived += UInt64(stats.ifi_ibytes)
                counts.wifiSent += UInt64(stats.ifi_obytes)
                found = true
            } else if name.hasPrefix("pdp_ip") {
                counts.cellularReceived += UInt64(stats.ifi_ibytes)
                counts.cellularSent += UInt64(stats.ifi_obytes)
                found = true
            }
        }
        return found ? counts : nil
    }

    /// Local IP addresses on real traffic-carrying interfaces,
    /// skipping loopback and link-local noise.
    static func localAddresses() -> [Address] {
        var addresses: [Address] = []

        forEachInterface { name, ifa in
            let family = ifa.ifa_addr.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { return }
            guard name.hasPrefix("en") || name.hasPrefix("pdp_ip") else { return }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length = family == UInt8(AF_INET)
                ? socklen_t(MemoryLayout<sockaddr_in>.size)
                : socklen_t(MemoryLayout<sockaddr_in6>.size)
            guard getnameinfo(ifa.ifa_addr, length,
                              &host, socklen_t(host.count),
                              nil, 0, NI_NUMERICHOST) == 0 else { return }

            var ip = String(cString: host)
            // IPv6 addresses arrive as "fe80::1%en0" — drop the zone suffix,
            // and skip link-local addresses entirely (they aren't routable).
            if ip.hasPrefix("fe80") { return }
            if let zoneIndex = ip.firstIndex(of: "%") {
                ip = String(ip[..<zoneIndex])
            }
            addresses.append(Address(interface: name, ip: ip, isIPv6: family == UInt8(AF_INET6)))
        }
        return addresses
    }

    /// Iterates every interface entry that has both a name and an address.
    private static func forEachInterface(_ visit: (String, ifaddrs) -> Void) {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0 else { return }
        defer { freeifaddrs(first) }

        var cursor = first
        while let entry = cursor?.pointee {
            if entry.ifa_addr != nil {
                visit(String(cString: entry.ifa_name), entry)
            }
            cursor = entry.ifa_next
        }
    }
}
