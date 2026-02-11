#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/android/src/main/jniLibs"

TARGETS=(
  aarch64-linux-android
  armv7-linux-androideabi
  x86_64-linux-android
)

ABIS=(
  arm64-v8a
  armeabi-v7a
  x86_64
)

echo "== Android build =="
rm -rf "$OUT"
cargo clean --manifest-path "$CRATE/Cargo.toml"

for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  abi="${ABIS[$i]}"

  cargo build --release --target "$target" --manifest-path "$CRATE/Cargo.toml"

  mkdir -p "$OUT/$abi"
  cp "$CRATE/target/$target/release/liblofty_ffi.so" \
     "$OUT/$abi/liblofty_ffi.so"
done
