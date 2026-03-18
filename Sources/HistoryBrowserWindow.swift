// HistoryBrowserWindow.swift
// MikaScreenSnap
//
// Screenshot history browser window with grid view, search, and context menus.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class HistoryBrowserWindowController {
    private var window: NSWindow?
    private let historyManager: ScreenshotHistoryManager
    private weak var appState: AppState?

    init(historyManager: ScreenshotHistoryManager, appState: AppState) {
        self.historyManager = historyManager
        self.appState = appState
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        historyManager.loadHistory()

        let contentView = HistoryBrowserView(
            historyManager: historyManager,
            onOpenInEditor: { [weak self] url in self?.openInEditor(url) },
            onPin: { [weak self] url in self?.pinImage(url) },
            onRevealInFinder: { url in NSWorkspace.shared.activateFileViewerSelecting([url]) },
            onCopy: { url in
                guard let image = NSImage(contentsOf: url) else { return }
                ClipboardManager.copyToClipboard(image)
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screenshot History"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.minSize = NSSize(width: 500, height: 400)

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }

    private func openInEditor(_ url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        let controller = AnnotationEditorWindowController(image: image)
        controller.showWindow(nil)
        appState?.annotationEditorController = controller
    }

    private func pinImage(_ url: URL) {
        guard let image = NSImage(contentsOf: url), let appState else { return }
        let panel = PinnedScreenshotPanel(image: image, appState: appState)
        panel.makeKeyAndOrderFront(nil)
        appState.pinnedPanels.append(panel)
    }
}

// MARK: - SwiftUI Views

struct HistoryBrowserView: View {
    let historyManager: ScreenshotHistoryManager
    let onOpenInEditor: (URL) -> Void
    let onPin: (URL) -> Void
    let onRevealInFinder: (URL) -> Void
    let onCopy: (URL) -> Void

    @State private var searchText = ""
    @State private var selectedItem: HistoryItem?

    private var filteredItems: [HistoryItem] {
        if searchText.isEmpty { return historyManager.items }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return historyManager.items.filter { item in
            let dateStr = formatter.string(from: item.date)
            return dateStr.localizedCaseInsensitiveContains(searchText)
                || item.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by date or filename...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()

            Divider()

            if filteredItems.isEmpty {
                ContentUnavailableView("No Screenshots", systemImage: "photo.on.rectangle.angled", description: Text("Take a screenshot to see it here."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                        ForEach(filteredItems) { item in
                            HistoryItemView(item: item)
                                .onTapGesture {
                                    onOpenInEditor(item.url)
                                }
                                .contextMenu {
                                    Button("Open in Editor") { onOpenInEditor(item.url) }
                                    Button("Copy") { onCopy(item.url) }
                                    Button("Pin to Screen") { onPin(item.url) }
                                    Button("Show in Finder") { onRevealInFinder(item.url) }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        historyManager.deleteItem(item)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct HistoryItemView: View {
    let item: HistoryItem

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: item.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(Self.dateFormatter.string(from: item.date))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(item.pixelWidth) \u{00D7} \(item.pixelHeight)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
