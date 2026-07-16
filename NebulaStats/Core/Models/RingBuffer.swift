import Foundation

/// A fixed-capacity FIFO buffer for chart history.
/// Appending beyond capacity drops the oldest value, so memory stays constant
/// no matter how long the app samples.
struct RingBuffer<Element> {
    private var storage: [Element] = []
    let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        storage.reserveCapacity(capacity)
    }

    mutating func append(_ element: Element) {
        storage.append(element)
        if storage.count > capacity {
            storage.removeFirst(storage.count - capacity)
        }
    }

    /// Values in insertion order, oldest first.
    var values: [Element] { storage }

    var last: Element? { storage.last }
    var isEmpty: Bool { storage.isEmpty }
}
