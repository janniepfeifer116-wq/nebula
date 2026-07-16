import Foundation

/// Reads device storage via FileManager volume capacity keys.
/// `volumeAvailableCapacityForImportantUsage` matches the free-space number
/// the Settings app shows (it includes purgeable space the system can reclaim).
enum StorageSampler {

    struct Snapshot {
        let totalBytes: Int64
        let freeBytes: Int64

        var usedBytes: Int64 { max(totalBytes - freeBytes, 0) }
        var usedFraction: Double {
            totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
        }
    }

    static func sample() -> Snapshot? {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? home.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]),
        let total = values.volumeTotalCapacity,
        let free = values.volumeAvailableCapacityForImportantUsage
        else { return nil }

        return Snapshot(totalBytes: Int64(total), freeBytes: free)
    }
}
