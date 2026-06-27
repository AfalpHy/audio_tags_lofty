#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"

TMP="$ROOT/build/macos"
FRAMEWORK="$TMP/LoftyFFI.framework"
OUT="$ROOT/macos/LoftyFFI.xcframework"

rm -rf "$TMP" "$OUT"

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

# Standard macOS Framework Layout
mkdir -p "$FRAMEWORK/Versions/A/Resources"

cp "$TMP/liblofty_ffi.dylib" \
   "$FRAMEWORK/Versions/A/LoftyFFI"

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

codesign --force --sign - "$FRAMEWORK"

# XCFramework
xcodebuild -create-xcframework \
  -framework "$FRAMEWORK" \
  -output "$OUT"

echo "Created $OUT"