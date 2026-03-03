# bevy-ci-template

A minimal [Bevy 0.18](https://bevyengine.org/) project template with CI that builds:

- A **Linux** desktop binary
- A **WASM/WebGPU** build deployed to **GitHub Pages**
- An **Android arm64-v8a debug APK** using [GameActivity](https://developer.android.com/games/agdk/game-activity)

The app displays the official **Bevy 3D Shapes** demo scene — a collection of rotating 3D primitives with a UV debug texture. On WASM the canvas stretches to fill the browser viewport and resizes dynamically with the window.

## Supported Platforms

| Platform | Target | Backend | Status |
|----------|--------|---------|--------|
| Linux (desktop) | x86-64 | Vulkan/GL | ✅ |
| Browser | wasm32 | WebGPU | ✅ |
| Android | arm64-v8a | Vulkan | ✅ |

## Building

### Desktop (Linux)

```bash
cargo build --release
./target/release/bevy_ci_template
```

### WASM / WebGPU

#### Prerequisites

- Rust stable with the `wasm32-unknown-unknown` target
- [`wasm-bindgen-cli`](https://rustwasm.github.io/wasm-bindgen/) (version must match Cargo.lock)

```bash
rustup target add wasm32-unknown-unknown
# pin to exact version from lockfile:
version=$(cargo metadata --format-version 1 \
  | jq --raw-output '.packages[] | select(.name=="wasm-bindgen") | .version')
cargo install wasm-bindgen-cli --version "$version"
```

#### Build & serve

```bash
cargo build --release \
  --target wasm32-unknown-unknown \
  --no-default-features \
  --features wasm \
  --bin bevy_ci_template

wasm-bindgen \
  --no-typescript \
  --out-name bevy_game \
  --out-dir wasm-out \
  --target web \
  target/wasm32-unknown-unknown/release/bevy_ci_template.wasm

cp wasm/index.html wasm-out/
# then serve wasm-out/ with any static HTTP server, e.g.:
python3 -m http.server --directory wasm-out
```

Open `http://localhost:8000` in a WebGPU-capable browser (Chrome 113+ / Edge 113+).

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
# 1. Build the Rust shared library.
#    --no-default-features drops bevy/x11; --features android adds GameActivity.
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.2.12479018
cargo ndk -t arm64-v8a -o android/app/src/main/jniLibs \
  build --lib --release --no-default-features --features android

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

GitHub Actions runs three jobs on every push/PR:

| Job | Artifact |
|-----|----------|
| **build-linux** | `bevy_ci_template-linux-x86_64` binary |
| **build-wasm** | `bevy_ci_template-wasm` (JS + WASM bundle) |
| **build-android** | `app-debug.apk` |

On push to `main`, **deploy-pages** additionally deploys the WASM build to GitHub Pages.
