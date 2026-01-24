{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.tailscale.enable = mkEnableOption "tailscale VPN";

  config = mkIf config.presets.shared.cli-tools.tailscale.enable {
    home.packages = [ pkgs.tailscale ];
  };
}
