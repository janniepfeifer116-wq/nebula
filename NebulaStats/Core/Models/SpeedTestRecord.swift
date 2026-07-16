import Foundation

/// One saved speed test result. History is kept for the last 7 days only,
/// stored locally in UserDefaults — nothing ever leaves the device.
struct SpeedTestRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let downloadMbps: Double
    let uploadMbps: Double
    let latencyMs: Double
    /// Network context at test time: "Wi-Fi", "Cellular", "5G"...
    let connection: String
}

enum SpeedTestHistoryStore {
    private static let key = "speedTestHistory"
    private static let retention: TimeInterval = 7 * 24 * 3600

    /// Records from the last week, newest first.
    static func load() -> [SpeedTestRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([SpeedTestRecord].self, from: data)
        else { return [] }
        let cutoff = Date().addingTimeInterval(-retention)
        return records.filter { $0.date > cutoff }.sorted { $0.date > $1.date }
    }

    static func append(_ record: SpeedTestRecord) -> [SpeedTestRecord] {
        let records = [record] + load()
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
        return records
    }
}
