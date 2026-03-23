{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.development.scrcpy.enable =
    mkEnableOption "scrcpy Android screen mirroring";

  config = mkIf config.presets.shared.apps.development.scrcpy.enable {
    home.packages = [ pkgs.scrcpy ];
  };
}
