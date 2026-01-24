{ lib, config, ... }:

with lib;

let
  appNames = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./.)
  );
  enableApps = lib.genAttrs appNames (_: {
    enable = true;
  });
in
{
  options.presets.shared.apps.development.enable = mkEnableOption "all development apps";

  config = mkIf config.presets.shared.apps.development.enable {
    presets.shared.apps.development = enableApps;
  };
}
