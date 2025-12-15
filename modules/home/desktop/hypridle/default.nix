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

    # Hyprlock configuration
    xdg.configFile."hypr/hyprlock.conf".text = ''
      background {
        monitor =
        path = screenshot
        blur_passes = 3
        blur_size = 8
      }

      input-field {
        monitor =
        size = 200, 50
        outline_thickness = 3
        dots_size = 0.33
        dots_spacing = 0.15
        dots_center = true
        outer_color = rgb(89b4fa)
        inner_color = rgb(1e1e2e)
        font_color = rgb(cdd6f4)
        fade_on_empty = true
        placeholder_text = <i>Password...</i>
        hide_input = false
        position = 0, -20
        halign = center
        valign = center
      }

      label {
        monitor =
        text = $TIME
        font_size = 64
        font_family = monospace
        color = rgb(cdd6f4)
        position = 0, 80
        halign = center
        valign = center
      }
    '';

    # Copy wallpaper to home directory
    home.file.".config/wallpapers/background.png".source = ../../../../assets/wallpapers/background.png;

    # Hyprpaper configuration
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ~/.config/wallpapers/background.png
      wallpaper = ,~/.config/wallpapers/background.png
    '';
  };
}
