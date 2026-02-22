{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.bun.enable =
    mkEnableOption "Bun JavaScript runtime and package manager";

  config = mkIf config.presets.shared.cli-tools.bun.enable {
    home.packages = [ pkgs.bun ];
  };
}
