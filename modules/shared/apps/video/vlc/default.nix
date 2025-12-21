{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.video.vlc.enable = mkEnableOption "VLC media player";

  config = mkIf config.presets.shared.apps.video.vlc.enable {
    home.packages = [ pkgs.vlc ];
  };
}
