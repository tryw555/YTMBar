// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YTMBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "YTMBar", targets: ["YTMBar"]),
        .executable(name: "YTMBarWidgetExtension", targets: ["YTMBarWidgetExtension"])
    ],
    targets: [
        .target(
            name: "YTMBarShared",
            path: "Sources/YTMBarShared"
        ),
        .executableTarget(
            name: "YTMBar",
            dependencies: ["YTMBarShared"],
            path: "Sources/YTMBar"
        ),
        .executableTarget(
            name: "YTMBarWidgetExtension",
            dependencies: ["YTMBarShared"],
            path: "Widgets/YTMBarWidget",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageModes: [.v5]
)
