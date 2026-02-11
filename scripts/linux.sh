#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/linux/lib"

echo "== Linux build =="
rm -rf "$OUT"
cargo clean --manifest-path "$CRATE/Cargo.toml"

cargo build --release --manifest-path "$CRATE/Cargo.toml"

mkdir -p "$OUT"
cp "$CRATE/target/release/liblofty_ffi.so" \
   "$OUT/liblofty_ffi.so"
