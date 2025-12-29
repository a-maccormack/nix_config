{ lib, config, ... }:

with lib;

{
  options.presets.virtualisation.tailscale.enable = mkEnableOption "Tailscale VPN";

  config = mkIf config.presets.virtualisation.tailscale.enable {
    services.tailscale.enable = true;
  };
}
