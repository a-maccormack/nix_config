{ lib, config, ... }:

with lib;

{
  options.presets.home.desktop.hypridle.enable = mkEnableOption "Hypridle and Hyprlock";

  config = mkIf config.presets.home.desktop.hypridle.enable {
    # Hypridle (idle daemon)
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "hyprlock";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    # Hyprlock configuration (native home-manager module)
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
        };

        background = [
          {
            monitor = "";
            # Use wallpaper instead of screenshot (more reliable in VMs)
            path = "${config.home.homeDirectory}/.config/wallpapers/background.png";
            blur_passes = 5;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "250, 50";
            outline_thickness = 3;
            dots_size = 0.4;
            dots_spacing = 0.15;
            dots_center = true;
            dots_rounding = -1;
            outer_color = "rgb(89b4fa)";
            inner_color = "rgb(1e1e2e)";
            font_color = "rgb(cdd6f4)";
            fade_on_empty = true;
            fade_timeout = 1000;
            placeholder_text = "<i>Password...</i>";
            hide_input = false;
            check_color = "rgb(f9e2af)";
            fail_color = "rgb(f38ba8)";
            fail_text = "<i>Wrong password!</i>";
            capslock_color = "rgb(fab387)";
            position = "0, -20";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          # Time
          {
            monitor = "";
            text = "$TIME";
            font_size = 64;
            font_family = "monospace";
            color = "rgb(cdd6f4)";
            position = "0, 100";
            halign = "center";
            valign = "center";
          }
          # Date
          {
            monitor = "";
            text = ''cmd[update:60000] date +"%A, %B %d"'';
            font_size = 20;
            font_family = "monospace";
            color = "rgb(a6adc8)";
            position = "0, 40";
            halign = "center";
            valign = "center";
          }
          # Greeting
          {
            monitor = "";
            text = "Welcome back, $USER";
            font_size = 16;
            font_family = "monospace";
            color = "rgb(a6adc8)";
            position = "0, -80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    # Copy wallpaper to home directory
    home.file.".config/wallpapers/background.png".source = ../../../../assets/wallpapers/background.png;

    # Hyprpaper configuration
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${config.home.homeDirectory}/.config/wallpapers/background.png
      wallpaper = ,${config.home.homeDirectory}/.config/wallpapers/background.png
    '';
  };
}
