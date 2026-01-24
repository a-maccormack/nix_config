{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.gh.enable = mkEnableOption "GitHub CLI";

  config = mkIf config.presets.shared.cli-tools.gh.enable {
    home.packages = [ pkgs.gh ];
  };
}
