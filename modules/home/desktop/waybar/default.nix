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
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "";
              default = "";
              empty = "";
            };
            window-rewrite-default = "";
            window-rewrite = {
              "class<kitty>" = "";
              "class<firefox>" = "";
              "class<chromium>" = "";
              "class<google-chrome>" = "";
              "class<nautilus>" = "";
              "class<code>" = "󰨞";
              "class<spotify>" = "";
              "class<discord>" = "";
              "class<slack>" = "";
              "class<telegram>" = "";
            };
            on-click = "activate";
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

        #clock, #cpu, #memory, #network, #pulseaudio, #tray {
          padding: 0 10px;
        }
      '';
    };
  };
}
