// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "CustomColorPanelKit",
    platforms: [.macOS(.v26)],
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
                .process("Shaders/Metal"),
                .process("Resources")
            ]
        )
    ]
)
