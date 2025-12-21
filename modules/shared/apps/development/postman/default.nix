{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.development.postman.enable = mkEnableOption "Postman API client";

  config = mkIf config.presets.shared.apps.development.postman.enable {
    home.packages = [ pkgs.postman ];

    # Link Postman icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/postman.png".source =
      "${pkgs.postman}/share/pixmaps/postman.png";
  };
}
