{ lib, config, ... }:

with lib;

{
  options.presets.home.desktop.fuzzel.enable = mkEnableOption "Fuzzel application launcher";

  config = mkIf config.presets.home.desktop.fuzzel.enable {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "kitty";
          layer = "overlay";
          width = 40;
          font = "monospace:size=12";
        };
        colors = {
          background = "1e1e2edd";
          text = "cdd6f4ff";
          match = "89b4faff";
          selection = "585b70ff";
          selection-text = "cdd6f4ff";
        };
        border = {
          width = 2;
          radius = 10;
        };
      };
    };
  };
}
