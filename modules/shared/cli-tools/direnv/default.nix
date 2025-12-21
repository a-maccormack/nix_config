{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.direnv.enable = mkEnableOption "direnv environment switcher";

  config = mkIf config.presets.shared.cli-tools.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
