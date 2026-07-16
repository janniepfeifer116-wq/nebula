import Foundation
import Observation

/// Decides when to ask for an App Store rating.
///
/// Uses Apple's native StoreKit prompt (triggered from RootView) — custom
/// "rate us" modals are disallowed by App Review, and the system sheet
/// already handles dismissal, a global user opt-out, and a hard cap of
/// 3 prompts per user per year.
///
/// Our own policy on top: ask only after the user has completed a few
/// significant actions (finished a speed test, ran the benchmark, ...),
/// and at most once per app version.
@MainActor
@Observable
final class ReviewPromptCoordinator {

    /// Set when the threshold is crossed; RootView watches it and shows
    /// the system prompt.
    private(set) var shouldAsk = false

    /// The App Store numeric app ID — used by the Settings "Rate" row.
    static let appStoreID = "6791660668"

    private static let threshold = 5
    private static let countKey = "reviewActionCount"
    private static let promptedVersionKey = "reviewPromptedVersion"

    /// Call after the user completes something meaningful.
    func registerSignificantAction() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: Self.countKey) + 1
        defaults.set(count, forKey: Self.countKey)

        guard count >= Self.threshold,
              defaults.string(forKey: Self.promptedVersionKey) != Self.currentVersion
        else { return }
        shouldAsk = true
    }

    /// Call right after the system prompt was requested.
    func didAsk() {
        shouldAsk = false
        UserDefaults.standard.set(Self.currentVersion, forKey: Self.promptedVersionKey)
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
