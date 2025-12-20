{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.ripgrep.enable = mkEnableOption "ripgrep - fast grep alternative";

  config = mkIf config.presets.shared.cli-tools.ripgrep.enable {
    home.packages = [ pkgs.ripgrep ];
  };
}
