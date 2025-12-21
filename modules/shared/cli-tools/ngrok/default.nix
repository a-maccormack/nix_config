{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.ngrok.enable = mkEnableOption "ngrok tunneling";

  config = mkIf config.presets.shared.cli-tools.ngrok.enable {
    home.packages = [ pkgs.ngrok ];
  };
}
