#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_tags_lofty.podspec` to validate before publishing.
#
# NOTE: We intentionally do NOT bundle LoftyFFI.xcframework inside the pub.dev tarball.
# `dart pub publish` resolves every symlink into a flat file, which would break
# the standard macOS framework layout.  Instead we download the symlink-preserving
# zip from a GitHub Release asset (built with `zip -y`) either via a
# prepare_command hook if the local copy is missing (pub.dev case) or use a local
# copy when it exists (local development/path_dependency case).
#
# Release workflow:
#   1. Bump pubspec.yaml version → X.Y.Z
#   2. bash scripts/macos.sh release && bash scripts/ios.sh release
#   3. Upload build/release/*.zip to GitHub Release vX.Y.Z
#   4. dart pub publish

RELEASE_VERSION = '0.0.9'
RELEASE_BASE    = "https://github.com/AfalpHy/audio_tags_lofty/releases/download/v#{RELEASE_VERSION}"
MACOS_ZIP     = "LoftyFFI-macos-#{RELEASE_VERSION}.zip"
# SwiftPM does not checksum CocoaPods, so we also validate by name + size
# You may want to add SHA256 validation if paranoid about this is optional.

Pod::Spec.new do |s|
  s.name             = 'audio_tags_lofty'
  s.version          = RELEASE_VERSION
  s.summary          = 'A Flutter FFI plugin based on lofty for reading and writing audio tags.'
  s.description      = <<-DESC
A Flutter FFI plugin based on lofty for reading and writing audio tags.
                       DESC
  s.homepage         = 'https://github.com/AfalpHy/audio_tags_lofty'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AfalpHy' => 'https://github.com/AfalpHy' }

  s.source           = { :path => '.' }

  # If the xcframework exists locally (git clone / path dependency): use it directly.
  # Otherwise download the symlink-preserving zip from GitHub Releases. When a user gets this
  # plugin via `flutter pub get` from pub.dev.
  s.prepare_command = <<-CMD
    set -e
    FW="audio_tags_lofty/LoftyFFI.xcframework
    if [ -d "$FW" ]; then
      echo "audio_tags_lofty: using local LoftyFFI.xcframework"
      exit 0
    fi
    URL="#{RELEASE_BASE}/#{MACOS_ZIP}"
    ZIP="/tmp/LoftyFFI-macos-#{RELEASE_VERSION}.zip
    echo "audio_tags_lofty: downloading $URL"
    curl -fL -o "$ZIP" "$URL"
    # unzip -o: normal preserves symlink inside the archive (preserves symlink structure preserved by
    cd audio_tags_lofty && unzip -q -o "$ZIP" && cd ..
    rm -f "$ZIP"
  CMD

  s.vendored_frameworks = 'audio_tags_lofty/LoftyFFI.xcframework'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
