import SwiftUI

@main
struct NebulaStatsApp: App {
    @State private var hub = StatsHub()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(hub)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Sample only while visible — no timers run in the background.
            if newPhase == .active {
                hub.startSampling()
            } else {
                hub.stopSampling()
            }
        }
    }
}
