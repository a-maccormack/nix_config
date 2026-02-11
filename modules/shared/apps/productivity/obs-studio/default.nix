{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.productivity.obs-studio.enable =
    mkEnableOption "OBS Studio streaming/recording";

  config = mkIf config.presets.shared.apps.productivity.obs-studio.enable {
    home.packages = [ pkgs.obs-studio ];
  };
}
