{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.vim.enable = mkEnableOption "Vim text editor";

  config = mkIf config.presets.shared.cli-tools.vim.enable {
    home.packages = [ pkgs.vim ];
  };
}
