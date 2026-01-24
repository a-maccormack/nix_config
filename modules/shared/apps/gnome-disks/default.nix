{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.gnome-disks.enable = mkEnableOption "gnome-disks - GNOME disk utility";

  config = mkIf config.presets.shared.apps.gnome-disks.enable {
    home.packages = [ pkgs.gnome-disk-utility ];
  };
}
