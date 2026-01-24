{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.development.antares.enable =
    mkEnableOption "Antares SQL database client";

  config = mkIf config.presets.shared.apps.development.antares.enable {
    home.packages = [ pkgs.antares ];

    # Link Antares icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/antares.png".source =
      "${pkgs.antares}/share/icon/antares.png";
  };
}
