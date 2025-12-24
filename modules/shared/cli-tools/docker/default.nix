{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.docker.enable = mkEnableOption "docker CLI tools";

  config = mkIf config.presets.shared.cli-tools.docker.enable {
    home.packages = with pkgs; [
      docker-compose
    ];
  };
}
