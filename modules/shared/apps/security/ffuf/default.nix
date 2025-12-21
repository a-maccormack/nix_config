{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.security.ffuf.enable = mkEnableOption "ffuf web fuzzer";

  config = mkIf config.presets.shared.apps.security.ffuf.enable {
    home.packages = [ pkgs.ffuf ];
  };
}
