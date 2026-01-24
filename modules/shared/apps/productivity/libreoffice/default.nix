{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.productivity.libreoffice.enable = mkEnableOption "LibreOffice suite";

  config = mkIf config.presets.shared.apps.productivity.libreoffice.enable {
    home.packages = [ pkgs.libreoffice ];
  };
}
