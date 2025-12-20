{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.fd.enable = mkEnableOption "fd - fast find alternative";

  config = mkIf config.presets.shared.cli-tools.fd.enable {
    home.packages = [ pkgs.fd ];
  };
}
