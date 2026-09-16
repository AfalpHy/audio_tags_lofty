// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "audio_tags_lofty",
    platforms: [.macOS("10.15")],
    products: [
        .library(name: "audio-tags-lofty", targets: ["audio_tags_lofty"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "audio_tags_lofty",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "LoftyFFI",
            ]
        ),
        .binaryTarget(
            name: "LoftyFFI",
            path: "LoftyFFI.xcframework"
        ),
    ]
)
