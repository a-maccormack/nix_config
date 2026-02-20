{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.home.desktop.swaync.enable = mkEnableOption "SwayNC notification daemon";

  config = mkIf config.presets.home.desktop.swaync.enable {
    home.packages = [ pkgs.libnotify ];

    services.swaync = {
      enable = true;
      style = ''
        .notification-content .image {
          border-radius: 0;
          -gtk-icon-style: regular;
        }
      '';
      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        hide-on-action = true;
        timeout = 10;
        timeout-low = 5;
        timeout-critical = 0;
        scripts = {
          spotify-focus = {
            exec = "hyprctl dispatch focuswindow class:Spotify";
            app-name = "Spotify";
            run-on = "action";
          };
        };
      };
    };
  };
}
