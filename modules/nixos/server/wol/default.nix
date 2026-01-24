{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.server.wol = {
    enable = mkEnableOption "Wake-on-LAN support";

    interface = mkOption {
      type = types.str;
      default = "enp0s31f6"; # Common for ThinkCentre M910s
      description = "Network interface for WoL";
    };
  };

  config = mkIf config.presets.server.wol.enable {
    networking.interfaces.${config.presets.server.wol.interface}.wakeOnLan.enable = true;

    environment.systemPackages = with pkgs; [ ethtool ];
  };
}
