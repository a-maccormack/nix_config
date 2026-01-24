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
  options.presets.shared.apps.messaging.enable = mkEnableOption "all messaging apps";

  config = mkIf config.presets.shared.apps.messaging.enable {
    presets.shared.apps.messaging = enableApps;
  };
}
