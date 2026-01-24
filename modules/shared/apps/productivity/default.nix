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
  options.presets.shared.apps.productivity.enable = mkEnableOption "all productivity apps";

  config = mkIf config.presets.shared.apps.productivity.enable {
    presets.shared.apps.productivity = enableApps;
  };
}
