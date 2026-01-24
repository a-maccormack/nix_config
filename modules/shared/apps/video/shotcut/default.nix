{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.video.shotcut.enable = mkEnableOption "Shotcut video editor";

  config = mkIf config.presets.shared.apps.video.shotcut.enable {
    home.packages = [ pkgs.shotcut ];
  };
}
