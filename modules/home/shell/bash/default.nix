{ lib, config, ... }:

with lib;

{
  options.presets.home.shell.bash.enable = mkEnableOption "Bash shell configuration";

  config = mkIf config.presets.home.shell.bash.enable {
    programs.bash = {
      enable = true;
      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake .#vm";
      };
    };
  };
}
