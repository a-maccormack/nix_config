{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.productivity.gimp.enable = mkEnableOption "GIMP image editor";

  config = mkIf config.presets.shared.apps.productivity.gimp.enable {
    home.packages = [ pkgs.gimp ];
  };
}
