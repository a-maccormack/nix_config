{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.productivity.google-chrome.enable = mkEnableOption "Google Chrome Browser";

  config = mkIf config.presets.shared.apps.productivity.google-chrome.enable {
    home.packages = [ pkgs.google-chrome ];
  };
}


