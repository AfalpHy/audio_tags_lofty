#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/lofty_ffi"
OUT="$ROOT/windows/lib"

echo "== Windows (MinGW) build =="
rm -f "$OUT/lofty_ffi.dll"
cargo clean --manifest-path "$CRATE/Cargo.toml"

cargo build --release \
  --target x86_64-pc-windows-gnu \
  --manifest-path "$CRATE/Cargo.toml"

mkdir -p "$OUT"
cp "$CRATE/target/x86_64-pc-windows-gnu/release/lofty_ffi.dll" \
   "$OUT/lofty_ffi.dll"
