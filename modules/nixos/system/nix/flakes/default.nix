{ lib, config, ... }:

with lib;

{
  options.presets.system.nix.flakes.enable = mkEnableOption "Nix flakes and new CLI";

  config = mkIf config.presets.system.nix.flakes.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    nixpkgs.config.allowUnfree = true;
  };
}
