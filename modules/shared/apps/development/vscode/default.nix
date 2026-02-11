{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.development.vscode.enable = mkEnableOption "Visual Studio Code";

  config = mkIf config.presets.shared.apps.development.vscode.enable {
    programs.vscode = {
      enable = true;
      userSettings = {
        "extensions.autoUpdate" = true;
      };
    };

    # Link VSCode icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/vscode.png".source =
      "${pkgs.vscode}/share/pixmaps/vscode.png";
  };
}
