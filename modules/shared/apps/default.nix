{ lib, config, ... }:

with lib;

let
  categoryNames = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./.)
  );
  enableCategories = lib.genAttrs categoryNames (_: {
    enable = true;
  });
in
{
  options.presets.shared.apps.enable = mkEnableOption "all apps in shared/apps/";

  config = mkIf config.presets.shared.apps.enable {
    presets.shared.apps = enableCategories;
  };
}
