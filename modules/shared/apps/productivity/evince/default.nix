{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.productivity.evince.enable = mkEnableOption "Evince PDF viewer";

  config = mkIf config.presets.shared.apps.productivity.evince.enable {
    home.packages = [ pkgs.evince ];
  };
}
