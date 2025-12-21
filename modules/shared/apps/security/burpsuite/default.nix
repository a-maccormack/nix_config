{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.security.burpsuite.enable = mkEnableOption "Burp Suite web security testing";

  config = mkIf config.presets.shared.apps.security.burpsuite.enable {
    home.packages = [ pkgs.burpsuite ];

    # Link Burp Suite icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/burpsuite.png".source =
      "${pkgs.burpsuite}/share/pixmaps/burpsuite.png";
  };
}
