// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MikaScreenSnap",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "MikaScreenSnap",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
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
