{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.desktop.fingerprint.enable = mkEnableOption "Fingerprint authentication (fprintd)";

  config = mkIf config.presets.desktop.fingerprint.enable {
    services.fprintd.enable = true;

    # Restart fprintd after suspend — the sensor loses its USB connection
    # during sleep and fprintd doesn't re-enumerate it automatically.
    powerManagement.resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl restart fprintd
    '';

    # Disable fprintd PAM globally (it defaults to true for all services
    # when fprintd is enabled, which causes blocking: the fingerprint prompt
    # must complete before password input is accepted).
    # Only enable it for sudo and polkit where sequential auth is acceptable.
    security.pam.services.sudo.fprintAuth = true;
    security.pam.services.polkit-1.fprintAuth = true;

    # Disable fprintd PAM for hyprlock (uses native concurrent fingerprint
    # support instead) and ly (password-only login since TTY can't do
    # concurrent auth).
    security.pam.services.hyprlock.fprintAuth = false;
    security.pam.services.ly.fprintAuth = false;

  };
}
