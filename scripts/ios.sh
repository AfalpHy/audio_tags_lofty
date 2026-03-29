#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/ios/LoftyFFI.xcframework"
TMP="$ROOT/ios/.tmp"

echo "== iOS dynamic framework build =="

rm -rf "$OUT" "$TMP"
mkdir -p "$TMP"

cargo clean --manifest-path "$CRATE/Cargo.toml"

# ---- Build (with correct install_name) ----
export RUSTFLAGS="-C link-arg=-Wl,-install_name,@rpath/LoftyFFI.framework/LoftyFFI"

# Build for iOS targets (dynamic)
cargo build --release --target aarch64-apple-ios       --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target aarch64-apple-ios-sim   --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target x86_64-apple-ios        --manifest-path "$CRATE/Cargo.toml"

# Paths to dylibs
DEVICE_LIB="$CRATE/target/aarch64-apple-ios/release/liblofty_ffi.dylib"
SIM_ARM_LIB="$CRATE/target/aarch64-apple-ios-sim/release/liblofty_ffi.dylib"
SIM_X86_LIB="$CRATE/target/x86_64-apple-ios/release/liblofty_ffi.dylib"

# Merge simulator dylibs
lipo -create "$SIM_ARM_LIB" "$SIM_X86_LIB" -output "$TMP/liblofty_ffi_sim.dylib"

# ---- Create framework folders ----

create_framework() {
  local LIB_PATH=$1
  local OUT_DIR=$2

  mkdir -p "$OUT_DIR/LoftyFFI.framework"

  # Binary (must be named same as framework)
  cp "$LIB_PATH" "$OUT_DIR/LoftyFFI.framework/LoftyFFI"

  # Minimal Info.plist
  cat > "$OUT_DIR/LoftyFFI.framework/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>LoftyFFI</string>
  <key>CFBundleIdentifier</key>
  <string>com.afalphy.loftyffi</string>
  <key>CFBundleName</key>
  <string>LoftyFFI</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
EOF
}

# Create frameworks
create_framework "$DEVICE_LIB" "$TMP/ios-arm64"
create_framework "$TMP/liblofty_ffi_sim.dylib" "$TMP/ios-simulator"

# ---- Create XCFramework ----

xcodebuild -create-xcframework \
  -framework "$TMP/ios-arm64/LoftyFFI.framework" \
  -framework "$TMP/ios-simulator/LoftyFFI.framework" \
  -output "$OUT"

rm -rf "$TMP"

echo "Built $OUT"