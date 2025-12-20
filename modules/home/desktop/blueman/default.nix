{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.home.desktop.blueman.enable = mkEnableOption "Blueman Bluetooth Manager";

  config = mkIf config.presets.home.desktop.blueman.enable {
    services.blueman-applet.enable = true;
  };
}
