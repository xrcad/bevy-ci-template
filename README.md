# bevy-ci-template

A minimal [Bevy 0.18](https://bevyengine.org/) project template with CI that builds a real
Android APK using [GameActivity](https://developer.android.com/games/agdk/game-activity)
(Android Game SDK).

## Supported Platforms

| Platform | ABI    | Status |
|----------|--------|--------|
| Linux (desktop) | x86-64 | ✅ |
| Android  | arm64-v8a | ✅ |

## Building

### Desktop (Linux)

```bash
cargo build --release
./target/release/bevy_ci_template
```

### Android Debug APK (arm64-v8a)

#### Prerequisites

- JDK 17
- Android SDK with NDK r27 (`ndk;27.2.12479018`)
- Rust stable (≥ 1.89) with the `aarch64-linux-android` target
- [`cargo-ndk`](https://github.com/bbqsrc/cargo-ndk)

```bash
rustup target add aarch64-linux-android
cargo install cargo-ndk
```

#### Build

```bash
# 1. Build the Rust shared library for arm64-v8a.
#    --no-default-features omits bevy/x11, which is Linux-only.
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.2.12479018
cargo ndk -t arm64-v8a -o android/app/src/main/jniLibs \
  build --lib --release --no-default-features

# 2. Assemble the debug APK.
cd android
./gradlew :app:assembleDebug
```

The APK is output to `android/app/build/outputs/apk/debug/app-debug.apk`.

#### Install on device

```bash
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

## CI

GitHub Actions runs two jobs on every push / PR:

- **build-linux** – installs X11/audio system libs and runs `cargo build --release`.
- **build-android** – installs SDK/NDK r27, builds the Rust cdylib with `cargo-ndk`
  (`--no-default-features`), runs `./gradlew :app:assembleDebug`, and uploads
  `app-debug.apk` as an artifact.
