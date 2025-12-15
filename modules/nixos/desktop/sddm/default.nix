{ lib, config, ... }:

with lib;

{
  options.presets.desktop.sddm.enable = mkEnableOption "SDDM display manager with Wayland";

  config = mkIf config.presets.desktop.sddm.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
