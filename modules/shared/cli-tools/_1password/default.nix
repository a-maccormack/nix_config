{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools._1password.enable = mkEnableOption "1Password CLI";

  config = mkIf config.presets.shared.cli-tools._1password.enable {
    home.packages = [ pkgs._1password-cli ];
  };
}
