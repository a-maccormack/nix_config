{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.home.desktop.blueman.enable = mkEnableOption "Blueman Bluetooth Manager";

  config = mkIf config.presets.home.desktop.blueman.enable {
    # Only install blueman, don't run the applet (using waybar icon instead)
    home.packages = [ pkgs.blueman ];
  };
}
