# bevy-ci-template

A minimal [Bevy](https://bevyengine.org/) app template with CI/CD workflows for desktop (Linux), web (WebAssembly via GitHub Pages), and Android.

## Features

- **Bevy 0.18.0** – pinned to the current stable release.
- **Rust stable** (latest) via `rust-toolchain.toml`.
- **GitHub Actions**:
  - `pages.yml` – builds for `wasm32-unknown-unknown`, runs `wasm-bindgen`, and deploys to **GitHub Pages**.
  - `ci.yml` – builds a Linux release binary and scaffolds an Android APK using `cargo-apk`.

## Project structure

```
.
├── .cargo/config.toml       # Linker and wasm optimizations
├── .github/workflows/
│   ├── ci.yml               # Linux & Android CI
│   └── pages.yml            # GitHub Pages deployment
├── assets/                  # Game assets (add your files here)
├── src/main.rs              # Minimal Bevy app
├── web/index.html           # Browser entry point
├── Cargo.toml
└── rust-toolchain.toml      # Pins Rust to the stable channel
```

## Local development

### Desktop

```sh
# Install system dependencies (Ubuntu/Debian)
sudo apt-get install libudev-dev libwayland-dev libxkbcommon-dev lld

cargo run
```

### Web (local preview)

```sh
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli

cargo build --release --target wasm32-unknown-unknown

CRATE=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name' | tr '-' '_')
mkdir -p dist
wasm-bindgen --out-dir dist --target web target/wasm32-unknown-unknown/release/${CRATE}.wasm
mv dist/${CRATE}.js dist/app.js
cp -r web/. dist/
cp -r assets dist/assets

# Serve dist/ with any static file server, e.g.:
npx serve dist
```

## Enabling GitHub Pages

1. Go to **Settings → Pages** in your repository.
2. Under *Build and deployment*, set **Source** to **GitHub Actions**.
3. Push to `main` (or run the `pages` workflow manually via *Actions → Deploy to GitHub Pages → Run workflow*).
4. The deployed URL will appear in the workflow summary once the `deploy` job completes.

## Android notes

The Android job in `ci.yml` is a best-effort scaffold that installs the NDK and `cargo-apk`.
It uses `continue-on-error: true` so failures there do not block other jobs.
A valid Android signing configuration is required for a production-ready APK.
