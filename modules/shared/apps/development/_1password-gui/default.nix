{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.development._1password-gui.enable =
    mkEnableOption "1Password desktop app";

  config = mkIf config.presets.shared.apps.development._1password-gui.enable {
    home.packages = [ pkgs._1password-gui ];
  };
}
