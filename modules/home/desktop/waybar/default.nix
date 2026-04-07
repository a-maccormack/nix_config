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
          modules-right = [
            "hyprland/language"
            "pulseaudio"
            "pulseaudio#mic"
            "bluetooth"
            "network"
            "battery"
            "cpu"
            "memory"
            "tray"
          ];

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰚥 {capacity}%";
            format-alt = "{icon} {time} ({capacity}%)";
            format-icons = [
              "󰂎"
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
          };

          "hyprland/workspaces" = {
            format = "{id}";
            on-click = "activate";
          };

          clock = {
            interval = 1;
            format = "{:%a %d %b %H:%M}";
            format-alt = "{:%H:%M:%S (%V/52)}";
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
            format-wifi = "{icon}";
            format-ethernet = "󰈀";
            format-disconnected = "󰤭";
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
          };

          bluetooth = {
            format = "󰂯";
            format-connected = "󰂱";
            format-disabled = "󰂲";
            format-off = "󰂲";
            tooltip-format = "{controller_alias}\t{controller_address}";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            on-click = "blueman-manager";
          };

          pulseaudio = {
            format = "{icon}";
            format-muted = "󰝟";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            tooltip-format = "Volume: {volume}%";
            on-click = "pavucontrol";
          };

          "pulseaudio#mic" = {
            format = "{format_source}";
            format-source = "󰍬";
            format-source-muted = "󰍭";
            tooltip-format = "Mic: {source_volume}%";
            on-click = "pavucontrol";
          };

          "hyprland/language" = {
            format = "󰌌 {}";
            format-en = "US";
            format-es = "ES";
          };

          tray = {
            spacing = 10;
          };
        };
      };
      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 16px;
        }

        window#waybar {
          background-color: transparent;
          color: #cdd6f4;
        }

        #workspaces {
          background-color: rgba(26, 27, 38, 0.9);
          border-radius: 10px;
          padding: 0 4px;
          margin: 4px 0 0 6px;
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

        #clock {
          background-color: rgba(26, 27, 38, 0.9);
          border-radius: 10px;
          padding: 0 14px;
          margin: 4px 0 0 0;
        }

        .modules-right {
          background-color: rgba(26, 27, 38, 0.9);
          border-radius: 10px;
          margin: 4px 6px 0 0;
        }

        #language, #pulseaudio, #bluetooth, #network, #battery, #cpu, #memory, #tray {
          background-color: transparent;
          padding: 0 10px;
        }

        #language {
          padding-left: 14px;
        }

        #tray {
          padding-right: 14px;
        }

        #memory {
          padding-right: 14px;
        }

        #battery.charging, #battery.plugged {
          color: #a6e3a1;
        }

        #battery.warning:not(.charging) {
          color: #f9e2af;
        }

        #battery.critical:not(.charging) {
          color: #f38ba8;
          animation: blink 0.5s linear infinite alternate;
        }

        @keyframes blink {
          to { color: #1e1e2e; }
        }
      '';
    };
  };
}
