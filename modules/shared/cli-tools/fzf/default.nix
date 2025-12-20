{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.fzf.enable = mkEnableOption "fzf - fuzzy finder";

  config = mkIf config.presets.shared.cli-tools.fzf.enable {
    programs.fzf = {
      enable = true;
      # No shell keybindings - just install the binary
      enableZshIntegration = false;
      enableBashIntegration = false;
    };
  };
}
