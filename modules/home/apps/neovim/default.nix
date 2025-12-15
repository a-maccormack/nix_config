{ lib, config, ... }:

with lib;

{
  options.presets.home.apps.neovim.enable = mkEnableOption "Neovim editor";

  config = mkIf config.presets.home.apps.neovim.enable {
    programs.neovim = {
      enable = true;
    };
  };
}
