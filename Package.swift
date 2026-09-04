// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Two editions come out of this one package. `MIKA_APPSTORE=1` drops Sparkle entirely —
// dependency, framework and call sites — because the Mac App Store rejects a bundle that
// carries its own updater. Without the variable nothing changes: the DMG build resolves
// exactly as before.
let isAppStore = ProcessInfo.processInfo.environment["MIKA_APPSTORE"] == "1"

let package = Package(
    name: "MikaScreenSnap",
    platforms: [.macOS(.v14)],
    dependencies: isAppStore ? [] : [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "MikaScreenSnap",
            dependencies: isAppStore ? [] : [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources",
            swiftSettings: isAppStore ? [.define("APPSTORE")] : [],
            linkerSettings: [
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("Vision"),
            ]
        ),
        .testTarget(
            name: "MikaScreenSnapTests",
            dependencies: ["MikaScreenSnap"],
            path: "Tests",
            swiftSettings: isAppStore ? [.define("APPSTORE")] : []
        )
    ]
)
