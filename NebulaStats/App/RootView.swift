import StoreKit
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard, performance, network, display

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: "Dashboard"
        case .performance: "Performance"
        case .network: "Network"
        case .display: "Display"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .performance: "chart.xyaxis.line"
        case .network: "wifi"
        case .display: "iphone"
        }
    }

    /// Network is the one cyan-tinted tab; the rest glow violet.
    var activeTint: Color {
        self == .network ? Theme.cyan : Theme.violet
    }
    var activeLabelTint: Color {
        self == .network ? Theme.cyanBright : Theme.violetBright
    }
}

/// App root: onboarding on first launch, then a floating tab bar on iPhone
/// or a sidebar split view on iPad.
struct RootView: View {
    @Environment(StatsHub.self) private var hub
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    // Initial tab can be preset via `defaults write … initialTab network`,
    // which lets scripts screenshot any tab without UI automation.
    @State private var selectedTab: AppTab =
        AppTab(rawValue: UserDefaults.standard.string(forKey: "initialTab") ?? "") ?? .dashboard
    @State private var showsSettings = false

    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView { hasOnboarded = true }
            } else if horizontalSizeClass == .regular {
                splitLayout
            } else {
                phoneLayout
            }
        }
        .onChange(of: hub.reviewPrompt.shouldAsk) { _, shouldAsk in
            guard shouldAsk else { return }
            Task {
                // Let the moment that earned the prompt settle first.
                try? await Task.sleep(for: .seconds(2))
                requestReview()
                hub.reviewPrompt.didAsk()
            }
        }
    }

    // MARK: - Shared screen content

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(selectedTab: $selectedTab, openSettings: { showsSettings = true })
        case .performance:
            PerformanceView()
        case .network:
            NetworkView()
        case .display:
            DisplayDeviceView()
        }
    }

    // MARK: - iPhone

    private var phoneLayout: some View {
        ZStack(alignment: .bottom) {
            NebulaBackground()
            screen(for: selectedTab)
            floatingTabBar
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView().environment(hub)
        }
    }

    private var floatingTabBar: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                let isActive = tab == selectedTab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(isActive ? tab.activeTint : Theme.tabInactive)
                            .shadow(color: isActive ? tab.activeTint.opacity(0.8) : .clear, radius: 2.5)
                        Text(tab.label.uppercased())
                            .font(.sans(8.5, isActive ? .semibold : .medium))
                            .kerning(1)
                            .foregroundStyle(isActive ? tab.activeLabelTint : Theme.tabInactive)
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.05))
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - iPad

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationBarHidden(true)
                .navigationSplitViewColumnWidth(250)
        } detail: {
            ZStack {
                NebulaBackground()
                screen(for: selectedTab)
            }
            .navigationBarHidden(true)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showsSettings) {
            SettingsView().environment(hub)
        }
    }

    private var sidebar: some View {
        ZStack {
            Color(hex: 0x0A0A1A, opacity: 0.5).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    AppLogo(size: 30)
                    Text("Nebula Stats")
                        .font(.sans(17, .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.bottom, 18)

                ForEach(AppTab.allCases) { tab in
                    sidebarRow(tab)
                }

                Spacer()

                Button {
                    showsSettings = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                        Text("Settings")
                            .font(.sans(13))
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .background(NebulaBackground())
    }

    private func sidebarRow(_ tab: AppTab) -> some View {
        let isActive = tab == selectedTab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(isActive ? Theme.violetBright : Theme.textSecondary)
                    .shadow(color: isActive ? Theme.violetBright.opacity(0.8) : .clear, radius: 2.5)
                Text(tab.label)
                    .font(.sans(14, isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color(hex: 0xEDE9FE) : Color(hex: 0xA8ABCB))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? Theme.violet.opacity(0.14) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isActive ? Theme.violet.opacity(0.30) : .clear, lineWidth: 1)
            )
        }
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
