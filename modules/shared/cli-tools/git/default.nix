{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.git.enable = mkEnableOption "Git version control";

  config = mkIf config.presets.shared.cli-tools.git.enable {
    programs.git = {
      enable = true;
    };
  };
}
