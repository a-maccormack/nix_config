{ lib, config, ... }:

with lib;

{
  options.presets.home.apps.firefox.enable = mkEnableOption "Firefox browser";

  config = mkIf config.presets.home.apps.firefox.enable {
    programs.firefox = {
      enable = true;
    };
  };
}
