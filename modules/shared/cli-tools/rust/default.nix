{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.presets.shared.cli-tools.rust;
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
in
{
  options.presets.shared.cli-tools.rust = {
    enable = mkEnableOption "Rust toolchain";
    enableCrossAarch64 = mkEnableOption "aarch64 cross-compilation support";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        rustup
      ]
      ++ lib.optionals cfg.enableCrossAarch64 [
        crossPkgs.stdenv.cc
      ];

    home.sessionVariables = mkIf cfg.enableCrossAarch64 {
      CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${crossPkgs.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
    };
  };
}
