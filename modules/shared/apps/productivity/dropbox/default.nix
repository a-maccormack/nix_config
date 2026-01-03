{ lib, config, ... }:

with lib;

{
  options.presets.shared.apps.productivity.dropbox.enable = mkEnableOption "Dropbox cloud storage";

  config = mkIf config.presets.shared.apps.productivity.dropbox.enable {
    services.dropbox = {
      enable = true;
      path = "${config.home.homeDirectory}/Dropbox";
    };
  };
}
