{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.tree.enable = mkEnableOption "tree - directory listing";

  config = mkIf config.presets.shared.cli-tools.tree.enable {
    home.packages = [ pkgs.tree ];
  };
}
