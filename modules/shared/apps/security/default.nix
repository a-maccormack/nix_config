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
  options.presets.shared.apps.security.enable = mkEnableOption "all security apps";

  config = mkIf config.presets.shared.apps.security.enable {
    presets.shared.apps.security = enableApps;
  };
}
