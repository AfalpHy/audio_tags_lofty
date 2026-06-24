// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "audio_tags_lofty",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "audio_tags_lofty",
            targets: ["audio_tags_lofty"]
        )
    ],
    targets: [
        .target(
            name: "audio_tags_lofty",
            dependencies: ["LoftyFFI"],
            path: "Sources" 
        ),
        .binaryTarget(
            name: "LoftyFFI",
            path: "LoftyFFI.xcframework"
        )
    ]
)