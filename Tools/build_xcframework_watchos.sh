#!/usr/bin/env bash

set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${MATRIX_RUST_SDK_DIR:-"$(cd "$PACKAGE_DIR/.." && pwd)/matrix-rust-sdk"}"
OUTPUT_DIR="${OUTPUT_DIR:-"$PACKAGE_DIR/generated"}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-16.0}"
WATCHOS_DEPLOYMENT_TARGET="${WATCHOS_DEPLOYMENT_TARGET:-10.0}"
NIGHTLY_TOOLCHAIN="${NIGHTLY_TOOLCHAIN:-nightly-2025-11-15}"

if [[ ! -d "$SDK_DIR" ]]; then
    echo "matrix-rust-sdk checkout not found at: $SDK_DIR" >&2
    echo "Set MATRIX_RUST_SDK_DIR to a checkout containing the watchOS xtask support." >&2
    exit 1
fi

if ! command -v rustup >/dev/null 2>&1; then
    echo "rustup is required to build the watchOS xcframework." >&2
    exit 1
fi

rustup toolchain install "$NIGHTLY_TOOLCHAIN" --component rust-src
rustup target add --toolchain stable \
    aarch64-apple-ios \
    aarch64-apple-ios-sim \
    x86_64-apple-ios

pushd "$SDK_DIR" >/dev/null

if ! cargo xtask swift build-framework --help | grep -q -- "--tier3-targets"; then
    echo "matrix-rust-sdk checkout does not expose xtask swift --tier3-targets." >&2
    echo "Use an SDK revision that includes matrix-org/matrix-rust-sdk#5872." >&2
    exit 1
fi

unset SDKROOT

cargo xtask swift build-framework \
    --release \
    --sequentially \
    --tier3-targets \
    --ios-deployment-target "$IOS_DEPLOYMENT_TARGET" \
    --watchos-deployment-target "$WATCHOS_DEPLOYMENT_TARGET" \
    --target aarch64-apple-ios \
    --target aarch64-apple-ios-sim \
    --target x86_64-apple-ios \
    --target aarch64-apple-watchos \
    --target arm64_32-apple-watchos \
    --target aarch64-apple-watchos-sim \
    --target x86_64-apple-watchos-sim

popd >/dev/null

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
rsync -a "$SDK_DIR/bindings/apple/generated/MatrixSDKFFI.xcframework" "$OUTPUT_DIR/"

plutil -p "$OUTPUT_DIR/MatrixSDKFFI.xcframework/Info.plist" | grep -E 'watchos|watchsimulator' >/dev/null

echo "Generated $OUTPUT_DIR/MatrixSDKFFI.xcframework"
