// AboutWindow.swift
// MikaScreenSnap
//
// About window showing app icon, version, and branding.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class AboutWindowController {
    private var window: NSWindow?

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        NSApp.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Mika+ScreenSnap"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App Icon
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 128, height: 128)
            } else {
                Image(systemName: "camera.viewfinder")
                    .resizable()
                    .frame(width: 128, height: 128)
                    .foregroundStyle(Color.MikaPlus.tealPrimary)
            }

            // App name
            Text("Mika+ScreenSnap")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            // Version
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)

            // Ecosystem tagline
            Text("Part of the Mika+ ecosystem")
                .font(.system(size: 12).italic())
                .foregroundStyle(Color.MikaPlus.tealLight)

            // Divider
            Rectangle()
                .fill(Color.MikaPlus.tealPrimary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 40)

            // Footer
            Text("Built with \u{2665} in Luxembourg")
                .font(.system(size: 11))
                .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.6))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.MikaPlus.darkBgDeep, Color.MikaPlus.darkBg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
