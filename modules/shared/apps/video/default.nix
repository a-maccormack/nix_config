{ lib, config, ... }:

with lib;

let
  appNames = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory")
      (builtins.readDir ./.)
  );
  enableApps = lib.genAttrs appNames (_: { enable = true; });
in
{
  options.presets.shared.apps.video.enable =
    mkEnableOption "all video apps";

  config = mkIf config.presets.shared.apps.video.enable {
    presets.shared.apps.video = enableApps;
  };
}
