{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.ffmpeg.enable = mkEnableOption "FFmpeg media toolkit";

  config = mkIf config.presets.shared.cli-tools.ffmpeg.enable {
    home.packages = [ pkgs.ffmpeg ];
  };
}
