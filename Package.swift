// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MikaScreenSnap",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MikaScreenSnap",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("Vision"),
            ]
        )
    ]
)
