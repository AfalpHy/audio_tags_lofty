// swift-tools-version: 5.9
import PackageDescription

// ---------------------------------------------------------------------------
// NOTE: This Package.swift uses URL+checksum binaryTarget instead of a local
// path.  This is required because `dart pub publish` TARS ALL SYMLINKS INTO
// FLAT FILES, which would break the standard macOS framework layout.
//
// The LoftyFFI.xcframework zip (with symlinks intact via `zip -y`) is hosted
// as a GitHub Release asset and downloaded by SwiftPM / CocoaPods at
// resolution time, which preserves the framework structure correctly.
//
// Release workflow (when bumping pubspec.yaml version → NEW_VERSION):
//   1. bash scripts/macos.sh release    # 构建 + 打包 zip + 输出 checksum
//   2. 在 GitHub 上创建 vNEW_VERSION release，上传 build/release/*.zip
//   3. 把本文件和 podspec 中的 VERSION / URL / CHECKSUM 更新为新值
//   4. dart pub publish                 # 这个 tarball 里不含 xcframework
// ---------------------------------------------------------------------------

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
            url: "https://github.com/AfalpHy/audio_tags_lofty/releases/download/v0.0.8/LoftyFFI-macos-0.0.9.zip",
            checksum: "7f922be5ca91f27634257bfe3a9f72f418b8f363d82f72e985f47ba5af97f1fe"
        ),
    ]
)
