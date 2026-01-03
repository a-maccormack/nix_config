{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.music.pavucontrol.enable = mkEnableOption "PulseAudio Volume Control";

  config = mkIf config.presets.shared.apps.music.pavucontrol.enable {
    home.packages = [ pkgs.pavucontrol ];
  };
}
