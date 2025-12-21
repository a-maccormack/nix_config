{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.apps.productivity.obsidian.enable = mkEnableOption "Obsidian note-taking";

  config = mkIf config.presets.shared.apps.productivity.obsidian.enable {
    home.packages = [ pkgs.obsidian ];

    # Link Obsidian icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/obsidian.png".source =
      "${pkgs.obsidian}/share/pixmaps/obsidian.png";
  };
}
