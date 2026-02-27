# ──────────────────────────────────────────────────────────────────────────────
# TEMPLATE INSTRUCTIONS
# After forking this template, update every location marked "TEMPLATE:" below:
#   1. `binaryName` — must match the [[bin]] name in your Cargo.toml.
#   2. `description` — replace with a description of your game/app.
#   3. The named package key in `packages` output (currently "bevy_ci_template").
#
# To lock flake inputs for reproducible builds, run:
#   nix flake update
# and commit the generated flake.lock.
# ──────────────────────────────────────────────────────────────────────────────
{
  # TEMPLATE: replace this description with your project name / description.
  description = "Bevy CI template – Wayland-first NixOS packaging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, rust-overlay, crane }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };

      # TEMPLATE: set this to the [[bin]] name in your Cargo.toml.
      binaryName = "bevy_ci_template";

      # Use the same stable Rust channel as the host toolchain.
      rustToolchain = pkgs.rust-bin.stable.latest.default;
      craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

      # Runtime libraries Bevy needs on Wayland / Vulkan.
      # These are injected into LD_LIBRARY_PATH via wrapProgram so the binary
      # works on NixOS without any manual configuration.
      runtimeLibs = with pkgs; [
        vulkan-loader
        wayland
        libxkbcommon
      ];

      # Build-time system dependencies.
      buildInputs = with pkgs; [
        alsa-lib       # audio
        udev           # gamepad / input
        libxkbcommon   # keyboard layout (Wayland)
        wayland        # Wayland windowing
        vulkan-loader  # Vulkan ICD loader
      ];

      nativeBuildInputs = with pkgs; [
        pkg-config
        makeWrapper
      ];

      # Shared arguments for both the deps-only and the final build steps.
      commonArgs = {
        src = craneLib.cleanCargoSource ./.;
        strictDeps = true;
        doCheck = false; # tests require a display server

        inherit buildInputs nativeBuildInputs;

        # Wayland-first: disable the default X11 feature, enable Wayland backend.
        # TEMPLATE: keep "--bin <name>" in sync with `binaryName` above.
        cargoExtraArgs = "--no-default-features --features wayland";
      };

      # Pre-build dependency artifacts for faster incremental nix builds.
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      bevyApp = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts;

        cargoExtraArgs = commonArgs.cargoExtraArgs + " --bin ${binaryName}";

        # Wrap the installed binary so Wayland / Vulkan libraries are found at
        # runtime on NixOS (where /usr/lib does not exist).
        postInstall = ''
          wrapProgram "$out/bin/${binaryName}" \
            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}
        '';
      });
    in
    {
      packages.${system} = {
        # TEMPLATE: rename this key to your package/binary name.
        bevy_ci_template = bevyApp;
        default = bevyApp;
      };

      apps.${system} = {
        # TEMPLATE: rename this key to your binary name.
        bevy_ci_template = {
          type = "app";
          program = "${bevyApp}/bin/${binaryName}";
        };
        default = {
          type = "app";
          program = "${bevyApp}/bin/${binaryName}";
        };
      };
    };
}
