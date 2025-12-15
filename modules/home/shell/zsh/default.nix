{ lib, config, ... }:

with lib;

{
  options.presets.home.shell.zsh.enable = mkEnableOption "Zsh shell with Oh-My-Zsh";

  config = mkIf config.presets.home.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "sudo" ];
      };

      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake .#vm";
      };
    };
  };
}
