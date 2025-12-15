{ lib, pkgs, config, inputs, ... }:

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
      hostName = "vm";
      networkmanager.enable = true;
      firewall.enable = true;
    };

    # Localization
    time.timeZone = "America/Santiago";
    i18n.defaultLocale = "en_US.UTF-8";

    # User account
    users.users.mac = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
    };

    # Enable zsh system-wide
    programs.zsh.enable = true;

    # Base packages
    environment.systemPackages = with pkgs; [
      vim
      git
      curl
      wget
      htop
      tree
    ];

    # Enable presets
    presets.system.boot.enable = true;
    presets.system.nix.flakes.enable = true;
    presets.system.nix.gc.enable = true;
    presets.desktop.sddm.enable = true;
    presets.desktop.hyprland.enable = true;

    # Home-manager
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.mac = { pkgs, ... }: {
        imports = [ ../../modules/home/import.nix ];

        home.stateVersion = "25.11";

        # Enable home presets
        presets.home.apps.firefox.enable = true;
        presets.home.shell.zsh.enable = true;
        presets.home.desktop.hyprland.enable = true;
        presets.home.desktop.kitty.enable = true;
        presets.home.desktop.waybar.enable = true;
        presets.home.desktop.fuzzel.enable = true;
        presets.home.desktop.hypridle.enable = true;
      };
    };
  };
}
