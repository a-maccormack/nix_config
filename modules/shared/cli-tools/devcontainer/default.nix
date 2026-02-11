{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.devcontainer.enable = mkEnableOption "Dev Containers CLI";

  config = mkIf config.presets.shared.cli-tools.devcontainer.enable {
    home.packages = [ pkgs.devcontainer ];
  };
}
