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
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # PAM for hyprlock
    security.pam.services.hyprlock = {};

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
    ];
  };
}
