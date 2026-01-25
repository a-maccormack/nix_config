{
  lib,
  config,
  pkgs,
  ...
}:

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
        plugins = [
          "git"
          "sudo"
          "docker"
          "docker-compose"
        ];
      };

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];

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

      initContent = lib.mkOrder 550 ''
        # Powerlevel10k classic style configuration (must be set before theme loads)
        POWERLEVEL9K_MODE='nerdfont-complete'

        # Left prompt: server icon + directory + git
        POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(custom_server dir vcs)
        POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time)

        # Custom server icon segment
        POWERLEVEL9K_CUSTOM_SERVER="echo -n '󰒋'"
        POWERLEVEL9K_CUSTOM_SERVER_BACKGROUND='blue'
        POWERLEVEL9K_CUSTOM_SERVER_FOREGROUND='white'

        # Classic style settings
        POWERLEVEL9K_PROMPT_ON_NEWLINE=false
        POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

        # Directory settings
        POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
        POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"

        # Git settings
        POWERLEVEL9K_VCS_GIT_GITHUB_ICON=""
      '';
    };
  };
}
