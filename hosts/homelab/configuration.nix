{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    system.stateVersion = "25.11";

    # Networking
    networking = {
      hostName = "homelab";
      networkmanager.enable = true;
      firewall = {
        enable = true;
        allowedTCPPorts = [
          22 # SSH
          8096 # Jellyfin HTTP
          8920 # Jellyfin HTTPS
        ];
        allowedUDPPorts = [
          1900 # Jellyfin DLNA
          7359 # Jellyfin discovery
        ];
      };
    };

    # Localization
    time.timeZone = "America/Santiago";
    i18n.defaultLocale = "en_US.UTF-8";

    # User account
    users.users.mac = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
    };

    # Enable zsh system-wide
    programs.zsh.enable = true;

    # System presets
    presets.system.boot.enable = true;
    presets.system.nix.flakes.enable = true;
    presets.system.nix.gc.enable = true;

    # Server presets
    presets.server.initrd-ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzfXdMl23vgYXH4zu0mg+jehnbYP8avkUjaj9ZnOVNn homelab-unlock"
      ];
    };

    presets.server.openssh = {
      enable = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4YM0f32wjlu6CfNmxGjqyzlh73Y7uWp0SbjdZtB/7P homelab"
      ];
    };

    presets.server.wol.enable = true;

    presets.server.power-management = {
      enable = true;
      hddSpindownMinutes = 60;
      cpuGovernor = "powersave";
    };

    # Virtualisation
    presets.virtualisation.docker.enable = true;
    presets.virtualisation.tailscale.enable = true;

    # Docker Compose auto-start
    presets.server.docker-compose = {
      enable = true;
      projectDirectory = "/home/mac/docker-compose";
    };

    # Minimal home-manager for headless server
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.mac =
        { ... }:
        {
          imports = [
            ../../modules/home/import.nix
            ../../modules/shared/import.nix
          ];

          home.stateVersion = "25.11";

          # Shell with distinct server theme
          presets.home.shell.zsh-server.enable = true;

          # CLI tools for server
          presets.home.apps.neovim.enable = true;
          presets.shared.cli-tools.git.enable = true;
          presets.shared.cli-tools.htop.enable = true;
        };
    };
  };
}
