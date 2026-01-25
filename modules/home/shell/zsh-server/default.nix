{ lib, config, ... }:

with lib;

{
  options.presets.home.shell.zsh-server.enable =
    mkEnableOption "Zsh shell for servers (distinct theme)";

  config = mkIf config.presets.home.shell.zsh-server.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [
          "git"
          "sudo"
          "docker"
          "docker-compose"
        ];
      };

      shellAliases = {
        # NixOS
        rebuild = "sudo nixos-rebuild switch --flake /home/mac/docker-compose#homelab";

        # Docker shortcuts
        dc = "docker compose";
        dps = "docker ps";
        dlogs = "docker compose logs -f";

        # Quick status
        status = "sudo systemctl status";
        logs = "sudo journalctl -fu";
      };

      initContent = ''
        # Server indicator in prompt
        export PROMPT="[homelab] $PROMPT"
      '';
    };
  };
}
