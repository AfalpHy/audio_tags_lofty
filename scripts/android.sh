#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Rust FFI crate directory
CRATE_DIR="$ROOT/rust/lofty_ffi"

# Android jniLibs output directory
OUT_DIR="$ROOT/android/src/main/jniLibs"

# Build
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cd "$CRATE_DIR"
cargo clean --manifest-path "$CRATE_DIR/Cargo.toml"

cargo ndk \
  -t arm64-v8a \
  -t armeabi-v7a \
  -t x86_64 \
  -o "$OUT_DIR" \
  build --release
