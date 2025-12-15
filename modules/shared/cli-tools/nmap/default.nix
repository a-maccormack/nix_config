{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.nmap.enable = mkEnableOption "nmap - network scanner";

  config = mkIf config.presets.shared.cli-tools.nmap.enable {
    home.packages = [ pkgs.nmap ];
  };
}
