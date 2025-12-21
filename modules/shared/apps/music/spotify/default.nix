{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.music.spotify.enable = mkEnableOption "Spotify";

  config = mkIf config.presets.shared.apps.music.spotify.enable {
    home.packages = [ pkgs.spotify ];
  };
}
