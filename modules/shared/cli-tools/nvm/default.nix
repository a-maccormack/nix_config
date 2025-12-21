{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.nvm.enable = mkEnableOption "nvm Node version manager";

  config = mkIf config.presets.shared.cli-tools.nvm.enable {
    programs.nvm = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };
}
