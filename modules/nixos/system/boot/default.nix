{ lib, config, ... }:

with lib;

{
  options.presets.system.boot.enable = mkEnableOption "systemd-boot bootloader";

  config = mkIf config.presets.system.boot.enable {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
