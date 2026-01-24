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
      hostName = "x1-carbon-g10";
      networkmanager.enable = true;
      firewall.enable = true;
    };

    # Bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    # IPU6 - native module with HAL linkage fix
    hardware.ipu6-overlay.enable = true; # Fix icamerasrc-ipu6ep HAL linkage
    hardware.ipu6 = {
      enable = true;
      platform = "ipu6ep"; # Alder Lake (12th gen)
    };
    hardware.ipu6-custom.enable = false;
    services.blueman.enable = true;
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    # Localization
    time.timeZone = "America/Santiago";
    i18n.defaultLocale = "en_US.UTF-8";

    # User account
    users.users.mac = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };

    # Enable zsh system-wide
    programs.zsh.enable = true;

    # Enable presets
    presets.system.bash.binbash = true;
    presets.system.boot.enable = true;
    presets.system.nix.flakes.enable = true;
    presets.system.nix.gc.enable = true;
    presets.desktop.ly.enable = true;
    presets.desktop.hyprland.enable = true;
    presets.desktop._1password.enable = true;
    presets.virtualisation.docker.enable = true;
    presets.virtualisation.tailscale.enable = true;
    presets.virtualisation.qemu.enable = true;

    # Enable nix-ld for running unpatched binaries (e.g. uv python)
    programs.nix-ld.enable = true;
    environment.localBinInPath = true;

    # Home-manager
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.mac =
        { pkgs, ... }:
        {
          imports = [
            ../../modules/home/import.nix
            ../../modules/shared/import.nix
          ];

          home.stateVersion = "25.11";

          # Enable home presets
          presets.home.apps.firefox.enable = true;
          presets.home.apps.neovim.enable = true;
          presets.home.shell.zsh.enable = true;
          presets.home.shell.tmux.enable = true;
          presets.home.desktop.hyprland.enable = true;
          presets.home.desktop.blueman.enable = true;

          # Enable shared CLI tools
          presets.shared.cli-tools.enable = true;

          # Enable shared apps
          presets.shared.apps.enable = true;
        };
    };
  };
}
