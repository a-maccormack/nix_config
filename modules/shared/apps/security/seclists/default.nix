{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.security.seclists.enable = mkEnableOption "SecLists wordlists";

  config = mkIf config.presets.shared.apps.security.seclists.enable {
    home.packages = [ pkgs.seclists ];
  };
}
