{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.development.gedit.enable = mkEnableOption "gedit - GNOME text editor";

  config = mkIf config.presets.shared.apps.development.gedit.enable {
    home.packages = [ pkgs.gedit ];
  };
}
