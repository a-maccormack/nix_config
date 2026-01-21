{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.nautilus.enable = mkEnableOption "nautilus - GNOME file manager";

  config = mkIf config.presets.shared.apps.nautilus.enable {
    home.packages = [ pkgs.nautilus pkgs.gvfs pkgs.file-roller ];
  };
}
