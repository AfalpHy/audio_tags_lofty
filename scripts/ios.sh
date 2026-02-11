#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/ios/LoftyFFI.xcframework"
TMP="$ROOT/ios/.tmp"

echo "== iOS build =="
rm -rf "$OUT" "$TMP"
cargo clean --manifest-path "$CRATE/Cargo.toml"

# Build device + simulator targets
cargo build --release --target aarch64-apple-ios       --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target aarch64-apple-ios-sim   --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target x86_64-apple-ios        --manifest-path "$CRATE/Cargo.toml"

mkdir -p "$TMP"

# Merge simulator libs into a single one with the SAME name as the device lib
lipo -create \
  "$CRATE/target/aarch64-apple-ios-sim/release/liblofty_ffi.a" \
  "$CRATE/target/x86_64-apple-ios/release/liblofty_ffi.a" \
  -output "$TMP/liblofty_ffi.a"   # <--- renamed to match device lib

# Create XCFramework with consistent library names
xcodebuild -create-xcframework \
  -library "$CRATE/target/aarch64-apple-ios/release/liblofty_ffi.a" \
  -library "$TMP/liblofty_ffi.a" \
  -output "$OUT"

rm -rf "$TMP"
