// AnnotationTabView.swift
// MikaScreenSnap
//
// Annotation preferences: default tool, color, stroke, behavior.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct AnnotationTabView: View {
    let preferences: AppPreferences

    private let availableTools: [DrawingToolType] = DrawingToolType.allCases.filter {
        $0 != .select && $0 != .measure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Annotation")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 0) {
                Text("Defaults")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label("Default tool", systemImage: "pencil.tip.crop.circle")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { preferences.defaultAnnotationTool },
                                set: { preferences.defaultAnnotationTool = $0 }
                            )) {
                                ForEach(availableTools, id: \.self) { tool in
                                    Label(tool.label, systemImage: tool.systemImage)
                                        .tag(tool.rawValue)
                                }
                            }
                            .frame(width: 150)
                        }

                        Divider()

                        settingsRow {
                            Label("Default color", systemImage: "paintpalette")
                            Spacer()
                            ColorPicker("", selection: Binding(
                                get: { Color(nsColor: preferences.defaultStrokeNSColor) },
                                set: { preferences.defaultStrokeNSColor = NSColor($0) }
                            ))
                            .labelsHidden()
                        }

                        Divider()

                        settingsRow {
                            Label("Stroke width", systemImage: "lineweight")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { preferences.defaultStrokeWidth },
                                set: { preferences.defaultStrokeWidth = $0 }
                            )) {
                                Text("Thin").tag(CGFloat(2.0))
                                Text("Medium").tag(CGFloat(4.0))
                                Text("Thick").tag(CGFloat(6.0))
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Behavior")
                    .font(.headline)
                    .padding(.bottom, 6)

                GroupBox {
                    VStack(spacing: 0) {
                        settingsRow {
                            Label {
                                Toggle("Remember last used tool", isOn: Binding(
                                    get: { preferences.rememberLastTool },
                                    set: { preferences.rememberLastTool = $0 }
                                ))
                            } icon: {
                                Image(systemName: "arrow.uturn.backward.circle")
                            }
                        }

                        Divider()

                        settingsRow {
                            Label {
                                Toggle("Show toolbar labels", isOn: Binding(
                                    get: { preferences.showToolbarLabels },
                                    set: { preferences.showToolbarLabels = $0 }
                                ))
                            } icon: {
                                Image(systemName: "tag")
                            }
                        }
                    }
                }
            }
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
