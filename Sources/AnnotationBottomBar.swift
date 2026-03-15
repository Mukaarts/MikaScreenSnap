// AnnotationBottomBar.swift
// MikaScreenSnap
//
// Bottom status/action bar for the annotation editor: zoom, dimensions, copy/save/pin/discard.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct AnnotationBottomBarView: View {
    let store: AnnotationStore
    let imageWidth: Int
    let imageHeight: Int
    let onCopy: () -> Void
    let onSave: () -> Void
    let onSaveAs: () -> Void
    let onDiscard: () -> Void
    var onPin: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Left — Zoom and dimensions

            Text("\(Int(store.zoomLevel * 100))%")
                .font(.system(.caption, design: .monospaced))

            Divider().frame(height: 16)

            Text("\(imageWidth) \u{00D7} \(imageHeight)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

            // MARK: Right — Action buttons

            if let onPin {
                Button { onPin() } label: {
                    Label("Pin", systemImage: "pin")
                }
            }

            Button { onCopy() } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c")

            Button { onSave() } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s")

            Button { onSaveAs() } label: {
                Label("Save As", systemImage: "square.and.arrow.down.on.square")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button(role: .destructive) { onDiscard() } label: {
                Label("Discard", systemImage: "trash")
            }
        }
        .buttonStyle(.borderless)
        .tint(Color.MikaPlus.tealPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(height: 32)
        .background(.ultraThinMaterial)
    }
}
