{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.nodejs.enable = mkEnableOption "Node.js runtime";

  config = mkIf config.presets.shared.cli-tools.nodejs.enable {
    home.packages = [ pkgs.nodejs_24 ];
  };
}
