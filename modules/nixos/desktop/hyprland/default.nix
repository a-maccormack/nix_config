{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.desktop.hyprland.enable = mkEnableOption "Hyprland window manager";

  config = mkIf config.presets.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # XDG Portal for file dialogs, screen sharing
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    };

    # dconf for GTK/libadwaita settings
    programs.dconf.enable = true;

    # PAM for hyprlock (with keyring unlock)
    security.pam.services.hyprlock.enableGnomeKeyring = true;

    # Keyring for secrets (gh, ssh-agent, etc.)
    services.gnome.gnome-keyring.enable = true;

    # Lid close behavior - suspend (hypridle handles locking via before_sleep_cmd)
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];

    # System packages for Hyprland
    environment.systemPackages = with pkgs; [
      # Wayland utilities
      wl-clipboard
      wdisplays
      xdg-utils
      # Icons
      hicolor-icon-theme
      # Hyprland ecosystem
      hyprpicker
      hypridle
      hyprlock
      hyprpaper
      # Desktop tools
      waybar
      fuzzel
      swaynotificationcenter
      # Terminal
      kitty
      # Screenshot
      grim
      slurp
      satty
      # Audio/brightness control
      brightnessctl
      pamixer
      swayosd
    ];
  };
}
