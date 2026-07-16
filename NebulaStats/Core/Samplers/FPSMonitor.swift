import Observation
import QuartzCore
import UIKit

/// Measures the display's actual frame rate with CADisplayLink.
///
/// The link fires once per rendered frame; we count frames and publish the
/// rate twice a second. On ProMotion displays the rate floats with content —
/// idle screens report low values, animation pushes it toward 120.
@MainActor
@Observable
final class FPSMonitor {

    /// Frames per second measured over the last window.
    private(set) var currentFPS: Double = 0

    /// The panel's ceiling (60 on standard displays, 120 on ProMotion).
    let maximumFPS = UIScreen.main.maximumFramesPerSecond

    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var windowStart: CFTimeInterval = 0

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frameDidRender))
        // Allow the full range but express no preference: the meter must
        // OBSERVE the display's real rate, not push it up — requesting the
        // maximum would inflate its own readings on ProMotion panels.
        // (The stress animation is what legitimately drives the rate to max.)
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 10, maximum: Float(maximumFPS)
        )
        link.add(to: .main, forMode: .common)
        displayLink = link
        frameCount = 0
        windowStart = CACurrentMediaTime()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        currentFPS = 0
    }

    @objc private func frameDidRender(link: CADisplayLink) {
        frameCount += 1
        let elapsed = link.timestamp - windowStart
        guard elapsed >= 0.5 else { return }

        currentFPS = Double(frameCount) / elapsed
        frameCount = 0
        windowStart = link.timestamp
    }
}
