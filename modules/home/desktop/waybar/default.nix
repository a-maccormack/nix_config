{ lib, config, ... }:

with lib;

{
  options.presets.home.desktop.waybar.enable = mkEnableOption "Waybar status bar";

  config = mkIf config.presets.home.desktop.waybar.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" "wlr/taskbar" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

          "hyprland/workspaces" = {
            format = "{id}";
            on-click = "activate";
          };

          "wlr/taskbar" = {
            format = "{icon}";
            icon-size = 18;
            icon-theme = "hicolor";
            tooltip-format = "{title}";
            on-click = "activate";
            on-click-middle = "close";
          };

          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%Y-%m-%d}";
            tooltip-format = "<tt>{calendar}</tt>";
          };

          cpu = {
            format = "CPU {usage}%";
            interval = 2;
          };

          memory = {
            format = "MEM {}%";
            interval = 2;
          };

          network = {
            format-wifi = "WiFi ({signalStrength}%)";
            format-ethernet = "ETH";
            format-disconnected = "Disconnected";
          };

          pulseaudio = {
            format = "VOL {volume}%";
            format-muted = "MUTED";
            on-click = "pavucontrol";
          };

          tray = {
            spacing = 10;
          };
        };
      };
      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 13px;
        }

        window#waybar {
          background-color: rgba(26, 27, 38, 0.9);
          color: #cdd6f4;
        }

        #workspaces button {
          padding: 0 5px;
          color: #cdd6f4;
          background: transparent;
          border-radius: 5px;
        }

        #workspaces button.active {
          background-color: #89b4fa;
          color: #1e1e2e;
        }

        #taskbar button {
          padding: 0 5px;
          background: transparent;
        }

        #taskbar button.active {
          background-color: rgba(137, 180, 250, 0.3);
          border-radius: 5px;
        }

        #clock, #cpu, #memory, #network, #pulseaudio, #tray {
          padding: 0 10px;
        }
      '';
    };
  };
}
