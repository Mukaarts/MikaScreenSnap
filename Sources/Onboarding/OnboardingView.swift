// OnboardingView.swift
// MikaScreenSnap
//
// SwiftUI container for onboarding flow with paged navigation.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct OnboardingView: View {
    let preferences: AppPreferences
    let launchAtLoginManager: LaunchAtLoginManager
    let onDismiss: () -> Void

    @State private var currentPage = 0

    private var needsPermission: Bool {
        !CGPreflightScreenCaptureAccess()
    }

    /// The App Store build adds a save-location step; the direct build writes to
    /// ~/Pictures without asking and does not need one.
    private var needsSaveLocation: Bool {
        #if APPSTORE
        return SaveLocationStore.isSandboxed && preferences.saveLocationBookmark == nil
        #else
        return false
        #endif
    }

    private var pageCount: Int {
        2 + (needsPermission ? 1 : 0) + (needsSaveLocation ? 1 : 0)
    }

    /// Page index of each step, so adding one does not mean renumbering the rest by hand.
    private var permissionPage: Int { 1 }
    private var saveLocationPage: Int { needsPermission ? 2 : 1 }
    private var shortcutsPage: Int { saveLocationPage + (needsSaveLocation ? 1 : 0) }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                WelcomeScreen {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                if needsPermission {
                    PermissionScreen(preferences: preferences) {
                        withAnimation { currentPage = saveLocationPage }
                    }
                    .tag(permissionPage)
                }

                #if APPSTORE
                if needsSaveLocation {
                    SaveLocationScreen(preferences: preferences) {
                        withAnimation { currentPage = shortcutsPage }
                    }
                    .tag(saveLocationPage)
                }
                #endif

                ShortcutsScreen(
                    launchAtLoginManager: launchAtLoginManager,
                    preferences: preferences,
                    onDismiss: onDismiss
                )
                .tag(shortcutsPage)
            }
            .tabViewStyle(.automatic)

            // Dot indicators
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.MikaPlus.tealPrimary : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)
        }
        .frame(width: 480, height: 560)
        .background(
            LinearGradient(
                colors: [Color.MikaPlus.darkBgDeep, Color.MikaPlus.darkBg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }
}
