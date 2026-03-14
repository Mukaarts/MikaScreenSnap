import AppKit
import SwiftUI

@MainActor
final class PreviewWindowController: NSObject {
    private var panel: NSPanel?
    private var dismissTimer: Timer?
    private var trackingArea: NSTrackingArea?
    private let image: NSImage

    init(image: NSImage) {
        self.image = image
        super.init()
    }

    func showWindow(_ sender: Any?) {
        let contentView = PreviewContentView(
            image: image,
            onSave: { [weak self] in
                MainActor.assumeIsolated {
                    self?.saveToDesktop()
                }
            },
            onCopy: { [weak self] in
                MainActor.assumeIsolated {
                    self?.copyToClipboard()
                }
            },
            onClose: { [weak self] in
                MainActor.assumeIsolated {
                    self?.dismiss()
                }
            }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 220)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 220),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.title = "Screenshot"
        panel.isReleasedWhenClosed = false

        // Position bottom-right
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - panel.frame.width - 20
            let y = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Slide-in animation
        let finalOrigin = panel.frame.origin
        panel.setFrameOrigin(NSPoint(x: finalOrigin.x + 50, y: finalOrigin.y))
        panel.alphaValue = 0

        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(finalOrigin)
            panel.animator().alphaValue = 1
        }

        self.panel = panel

        // Auto-dismiss after 5 seconds
        startDismissTimer()

        // Track mouse to pause auto-dismiss
        let tracking = NSTrackingArea(
            rect: hostingView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        hostingView.addTrackingArea(tracking)
        self.trackingArea = tracking
    }

    @objc func mouseEntered(with event: NSEvent) {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    @objc func mouseExited(with event: NSEvent) {
        startDismissTimer()
    }

    private func startDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.dismiss()
            }
        }
    }

    private func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let panel else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                panel.orderOut(nil)
                self?.panel = nil
            }
        })
    }

    private func saveToDesktop() {
        let url = ClipboardManager.saveToDesktop(image)
        if let url {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }

    private func copyToClipboard() {
        ClipboardManager.copyToClipboard(image)
    }
}

struct PreviewContentView: View {
    let image: NSImage
    let onSave: () -> Void
    let onCopy: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 140)
                .cornerRadius(6)
                .onTapGesture {
                    openInPreview()
                }
                .help("Click to open in Preview")

            HStack(spacing: 10) {
                Button(action: onSave) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }

                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Spacer()

                Button(action: onClose) {
                    Label("Close", systemImage: "xmark")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
    }

    private func openInPreview() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MikaSnap_preview.png")
        if ClipboardManager.saveToFile(image, url: tempURL) {
            NSWorkspace.shared.open(tempURL)
        }
    }
}
