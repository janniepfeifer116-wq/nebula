import Darwin

/// Reads per-core CPU load through the public Mach API `host_processor_info`.
///
/// The kernel exposes cumulative tick counters (user/system/idle/nice) per core.
/// Load over an interval is the ratio of busy ticks to total ticks between two
/// consecutive reads, so the very first call returns nil — there is no interval
/// to compare against yet.
final class CPUSampler {

    struct Snapshot {
        /// Overall load across all cores, 0...1.
        let totalLoad: Double
        /// Load of each core, 0...1, in kernel order.
        let perCoreLoad: [Double]
    }

    private struct CoreTicks {
        var busy: UInt32
        var total: UInt32
    }

    private var previousTicks: [CoreTicks]?

    func sample() -> Snapshot? {
        guard let currentTicks = readTicks() else { return nil }
        defer { previousTicks = currentTicks }

        guard let previousTicks, previousTicks.count == currentTicks.count else { return nil }

        let perCoreLoad = zip(previousTicks, currentTicks).map { earlier, now -> Double in
            let busyDelta = Double(now.busy &- earlier.busy)
            let totalDelta = Double(now.total &- earlier.total)
            guard totalDelta > 0 else { return 0 }
            return min(max(busyDelta / totalDelta, 0), 1)
        }

        let totalLoad = perCoreLoad.reduce(0, +) / Double(max(perCoreLoad.count, 1))
        return Snapshot(totalLoad: totalLoad, perCoreLoad: perCoreLoad)
    }

    /// One cumulative (busy, total) tick pair per core.
    private func readTicks() -> [CoreTicks]? {
        var coreCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &coreCount, &info, &infoCount
        )
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        return (0..<Int(coreCount)).map { core in
            let base = core * Int(CPU_STATE_MAX)
            let user = UInt32(bitPattern: info[base + Int(CPU_STATE_USER)])
            let system = UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)])
            let nice = UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)])
            let idle = UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)])
            let busy = user &+ system &+ nice
            return CoreTicks(busy: busy, total: busy &+ idle)
        }
    }
}
