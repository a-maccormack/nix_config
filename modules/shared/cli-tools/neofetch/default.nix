{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.neofetch.enable = mkEnableOption "neofetch - system info script";

  config = mkIf config.presets.shared.cli-tools.neofetch.enable {
    home.packages = [ pkgs.neofetch ];
  };
}
