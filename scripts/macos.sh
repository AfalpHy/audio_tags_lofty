#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/macos/liblofty_ffi.dylib"

echo "== macOS build =="
rm -f "$OUT"
cargo clean --manifest-path "$CRATE/Cargo.toml"

cargo build --release --target aarch64-apple-darwin --manifest-path "$CRATE/Cargo.toml"
cargo build --release --target x86_64-apple-darwin  --manifest-path "$CRATE/Cargo.toml"

lipo -create \
  "$CRATE/target/aarch64-apple-darwin/release/liblofty_ffi.dylib" \
  "$CRATE/target/x86_64-apple-darwin/release/liblofty_ffi.dylib" \
  -output "$OUT"

install_name_tool -id @rpath/liblofty_ffi.dylib "$OUT"
install_name_tool -add_rpath @loader_path "$OUT"

codesign --force --sign - "$OUT"
