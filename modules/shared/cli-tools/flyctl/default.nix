{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.flyctl.enable = mkEnableOption "Fly.io CLI";

  config = mkIf config.presets.shared.cli-tools.flyctl.enable {
    home.packages = [ pkgs.flyctl ];
  };
}
