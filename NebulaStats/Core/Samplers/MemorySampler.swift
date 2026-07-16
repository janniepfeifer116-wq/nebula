import Darwin
import Foundation

/// Reads device-wide memory usage via `host_statistics64` and this app's own
/// footprint via `task_vm_info` — both public Mach APIs.
enum MemorySampler {

    struct Snapshot {
        /// Physical RAM installed, in bytes.
        let totalBytes: UInt64
        /// Pages recently used by apps.
        let activeBytes: UInt64
        /// Pages the kernel pins and can never page out.
        let wiredBytes: UInt64
        /// Pages held compressed in RAM.
        let compressedBytes: UInt64
        /// This app's own memory footprint, in bytes.
        let appFootprintBytes: UInt64

        /// Memory in active use — what "used" means throughout the app.
        var usedBytes: UInt64 { activeBytes + wiredBytes + compressedBytes }

        var usedFraction: Double {
            totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
        }
    }

    static func sample() -> Snapshot? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        return Snapshot(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            activeBytes: UInt64(stats.active_count) * pageSize,
            wiredBytes: UInt64(stats.wire_count) * pageSize,
            compressedBytes: UInt64(stats.compressor_page_count) * pageSize,
            appFootprintBytes: appFootprint() ?? 0
        )
    }

    private static func appFootprint() -> UInt64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return info.phys_footprint
    }
}
