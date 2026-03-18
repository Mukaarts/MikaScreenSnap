// PreferencesContainerView.swift
// MikaScreenSnap
//
// Root SwiftUI view — native macOS System Settings layout.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct PreferencesContainerView: View {
    let preferences: AppPreferences
    let launchAtLoginManager: LaunchAtLoginManager
    let sparkleUpdater: SparkleUpdater
    let historyManager: ScreenshotHistoryManager
    let hotkeyManager: HotkeyManager
    let onShowOnboarding: () -> Void

    @State private var selectedTab: PreferencesTab = .general

    var body: some View {
        NavigationSplitView {
            List(PreferencesTab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            ScrollView {
                detailContent
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 640, height: 460)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general:
            GeneralTabView(preferences: preferences)
        case .shortcuts:
            ShortcutsTabView(hotkeyManager: hotkeyManager)
        case .annotation:
            AnnotationTabView(preferences: preferences)
        case .advanced:
            AdvancedTabView(
                preferences: preferences,
                launchAtLoginManager: launchAtLoginManager,
                sparkleUpdater: sparkleUpdater,
                historyManager: historyManager,
                hotkeyManager: hotkeyManager,
                onShowOnboarding: onShowOnboarding
            )
        }
    }
}
