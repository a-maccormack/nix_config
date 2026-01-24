{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.security.nuclei.enable = mkEnableOption "Nuclei vulnerability scanner";

  config = mkIf config.presets.shared.apps.security.nuclei.enable {
    home.packages = [ pkgs.nuclei ];
  };
}
