#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"

TMP="$ROOT/build/macos"
FRAMEWORK="$TMP/LoftyFFI.framework"
OUT="$TMP/audio_tags_lofty/LoftyFFI.xcframework"
RELEASE_DIR="$ROOT/build/release"

rm -rf "$TMP" "$OUT" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

cargo clean --manifest-path "$CRATE/Cargo.toml"

# Build
cargo build --release --target aarch64-apple-darwin \
  --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target x86_64-apple-darwin \
  --manifest-path "$CRATE/Cargo.toml"

mkdir -p "$TMP"

# Universal dylib
lipo -create \
  "$CRATE/target/aarch64-apple-darwin/release/liblofty_ffi.dylib" \
  "$CRATE/target/x86_64-apple-darwin/release/liblofty_ffi.dylib" \
  -output "$TMP/liblofty_ffi.dylib"

# Framework install name
install_name_tool \
  -id @rpath/LoftyFFI.framework/Versions/A/LoftyFFI \
  "$TMP/liblofty_ffi.dylib"

# Standard versioned macOS Framework Layout (with symlinks)
#  - zip -y below preserves these symlinks inside the GitHub Release zip
#  - If you are publishing to pub.dev: Package.swift uses URL+checksum, so the
#    symlinks are NOT re-staged by Flutter, keeping them intact.
mkdir -p "$FRAMEWORK/Versions/A/Resources"

cp "$TMP/liblofty_ffi.dylib" "$FRAMEWORK/Versions/A/LoftyFFI"

cat > "$FRAMEWORK/Versions/A/Resources/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LoftyFFI</string>
    <key>CFBundleIdentifier</key>
    <string>com.afalphy.loftyffi</string>
    <key>CFBundleName</key>
    <string>LoftyFFI</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>LSRequiresNativeExecution</key>
    <true/>
</dict>
</plist>
EOF

# Framework symlinks
ln -sf A "$FRAMEWORK/Versions/Current"
ln -sf Versions/Current/LoftyFFI "$FRAMEWORK/LoftyFFI"
ln -sf Versions/Current/Resources "$FRAMEWORK/Resources"

codesign --force --sign - "$FRAMEWORK/Versions/A/LoftyFFI"

# XCFramework
xcodebuild -create-xcframework \
  -framework "$FRAMEWORK" \
  -output "$OUT"

echo "Created xcframework: $OUT"

# --- GitHub Release asset (zip -y keeps symlinks intact)
VERSION=$(awk '/^version:/ {gsub(/"/,""); print $2}' "$ROOT/pubspec.yaml")
ZIP_NAME="LoftyFFI-macos-${VERSION}.zip"
ZIP_PATH="${RELEASE_DIR}/${ZIP_NAME}"
(cd "$(dirname "$OUT")" && /usr/bin/zip -q -y -r "$ZIP_PATH" "$(basename "$OUT")")

CHECKSUM=$(swift package compute-checksum "$ZIP_PATH")

echo ""
echo "=================================================================="
echo " Upload to GitHub Release: ${ZIP_NAME}"
echo " Artifact         : $ZIP_PATH"
echo " Checksum (SPM)    : $CHECKSUM"
echo " URL              : https://github.com/AfalpHy/audio_tags_lofty/releases/download/v${VERSION}/${ZIP_NAME}"
echo "=================================================================="
echo "$CHECKSUM" > "${RELEASE_DIR}/LoftyFFI-macos-${VERSION}.checksum"
echo "Done. Manually upload ${ZIP_NAME} to GitHub Release assets, then paste the"
echo "checksum into macos/audio_tags_lofty/Package.swift and podspec URL."
