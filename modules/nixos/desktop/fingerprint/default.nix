{ lib, config, ... }:

with lib;

{
  options.presets.desktop.fingerprint.enable = mkEnableOption "Fingerprint authentication (fprintd)";

  config = mkIf config.presets.desktop.fingerprint.enable {
    services.fprintd.enable = true;

    # Allow fingerprint auth for sudo, polkit (1Password), and lock screens
    security.pam.services.sudo.fprintAuth = true;
    security.pam.services.polkit-1.fprintAuth = true;
    security.pam.services.hyprlock.fprintAuth = true;
    security.pam.services.ly.fprintAuth = true;
    security.pam.services.login.fprintAuth = true;
  };
}
