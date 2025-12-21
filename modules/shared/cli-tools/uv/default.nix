{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.uv.enable = mkEnableOption "uv Python package manager";

  config = mkIf config.presets.shared.cli-tools.uv.enable {
    home.packages = [ pkgs.uv ];
  };
}
