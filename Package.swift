// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "CustomColorPanelKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "CustomColorPanelKit",
            targets: ["CustomColorPanelKit"]
        )
    ],
    targets: [
        .target(
            name: "CustomColorPanelKit",
            resources: [
                .process("Shaders")
            ]
        )
    ]
)
