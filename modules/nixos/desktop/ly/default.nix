{ lib, config, ... }:

with lib;

{
  options.presets.desktop.ly.enable = mkEnableOption "Ly display manager";

  config = mkIf config.presets.desktop.ly.enable {
    services.displayManager.ly.enable = true;
  };
}
