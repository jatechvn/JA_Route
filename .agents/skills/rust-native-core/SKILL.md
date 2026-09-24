---
name: rust-native-core
description: Guide for developing high-performance cross-platform Rust native compute cores across 5 platforms (Windows, Linux, macOS, Android, iOS) with Dart/Flutter FFI bindings.
---

# Rust Native Core — Cross-Platform Compute Engine

Guidelines for implementing a unified, cross-platform Rust core library compiled across 5 target operating systems and consumed via Dart FFI (`native_bridge.dart`).

---

## 1. Project Structure

```text
rust_core/
├── Cargo.toml
├── src/
│   └── lib.rs            # Exports public C-ABI functions via #[no_mangle] pub extern "C" fn
└── build_all.sh           # Multi-target cross-compilation script
```

### `Cargo.toml` Configuration
```toml
[lib]
crate-type = ["cdylib", "staticlib"]
```

---

## 2. Automated FFI via `flutter_rust_bridge`

Generate bidirectional, type-safe Dart ↔ Rust bindings automatically:
```bash
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen generate
```

---

## 3. Platform Cross-Compilation Matrix

| Platform | Target Triple | Output Artifact | Required Toolchain |
| :--- | :--- | :--- | :--- |
| **Windows** | `x86_64-pc-windows-msvc` | `core_x64.dll` | MSVC Build Tools |
| **macOS** | `x86_64-apple-darwin` / `aarch64-apple-darwin` | `libcore.dylib` | Xcode CLI Tools |
| **Linux** | `x86_64-unknown-linux-gnu` | `libcore.so` | GCC / build-essential |
| **Android** | `aarch64-linux-android` | `libcore.so` (into `jniLibs/`) | `cargo-ndk` + Android NDK |
| **iOS** | `aarch64-apple-ios` | `libcore.a` $\rightarrow$ `.xcframework` | Xcode, `cargo-lipo` |

### Compilation Commands
```bash
# Desktop Targets (Windows, macOS, Linux)
cargo build --release --target x86_64-pc-windows-msvc
cargo build --release --target x86_64-apple-darwin
cargo build --release --target x86_64-unknown-linux-gnu

# Android Target
cargo ndk -t arm64-v8a -t armeabi-v7a -o android/app/src/main/jniLibs build --release

# iOS Target (Static-link framework)
rustup target add aarch64-apple-ios
cargo build --release --target aarch64-apple-ios
xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release/libcore.a \
  -output RustCore.xcframework
```

---

## 4. API & Safety Guidelines

- Restrict FFI exports (`#[no_mangle] pub extern "C" fn`) to essential bridge endpoints. Keep internal implementations private.
- Never allow Rust `panic!` across FFI boundaries. Wrap execution with `catch_unwind` or return `Result` error codes.
- Always execute `cargo test` independently before integrating with the Dart UI layer.
