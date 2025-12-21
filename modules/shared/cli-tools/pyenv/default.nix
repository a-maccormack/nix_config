{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.pyenv.enable = mkEnableOption "pyenv Python version manager";

  config = mkIf config.presets.shared.cli-tools.pyenv.enable {
    programs.pyenv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };
}
