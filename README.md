# Element's build of the Matrix Rust SDK for Swift

This repository provides a cutdown Swift Package for distributing releases of the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk) for use by Element. The DDement fork also builds watchOS-capable artifacts for the companion Apple Watch app. The official components provide documentation and support more Apple platforms. These can be found here: https://github.com/matrix-org/matrix-rust-components-swift/

Note: The versioning used for this package does not correspond in any way with the official package.

## Releasing

Whenever a new release of the underlying components is available, we need to tag a new release in this repo to make them available to Swift components. This is done with the [release script](Tools/Release/README.md) found in the Tools directory.

## watchOS artifacts

The watchOS artifact flow requires a sibling checkout of `matrix-org/matrix-rust-sdk` at a revision that includes `cargo xtask swift build-framework --tier3-targets` support from matrix-rust-sdk PR #5872.

```sh
git clone https://github.com/matrix-org/matrix-rust-sdk ../matrix-rust-sdk
./Tools/build_xcframework_watchos.sh
```

The script pins the nightly compiler through `rust-toolchain.toml`, installs `rust-src`, builds the iOS and watchOS targets, and writes `generated/MatrixSDKFFI.xcframework`. The generated framework must contain these Rust targets:

- `aarch64-apple-ios`
- `aarch64-apple-ios-sim`
- `x86_64-apple-ios`
- `aarch64-apple-watchos`
- `arm64_32-apple-watchos`
- `aarch64-apple-watchos-sim`
- `x86_64-apple-watchos-sim`

Tag pushes matching `*+watchos.*` run `.github/workflows/build-watchos.yml`, zip the xcframework, and upload the zip plus SHA256 as workflow artifacts. Publishing a package release still requires updating `Package.swift` with the final release URL, checksum, and `.watchOS(.v10)` platform declaration.
