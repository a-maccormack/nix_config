{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.ncdu.enable = mkEnableOption "ncdu - disk usage analyzer";

  config = mkIf config.presets.shared.cli-tools.ncdu.enable {
    home.packages = [ pkgs.ncdu ];
  };
}
