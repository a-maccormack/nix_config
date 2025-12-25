{ lib, config, ... }:

with lib;

{
  options.presets.desktop.ly.enable = mkEnableOption "Ly display manager";

  config = mkIf config.presets.desktop.ly.enable {
    services.displayManager.ly.enable = true;

    # Unlock gnome-keyring at login
    security.pam.services.ly.enableGnomeKeyring = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
