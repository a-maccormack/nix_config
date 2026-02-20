{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.home.desktop.hyprland.enable = mkEnableOption "Hyprland home-manager configuration";

  config = mkIf config.presets.home.desktop.hyprland.enable {
    # Enable related desktop modules
    presets.home.desktop.waybar.enable = true;
    presets.home.desktop.fuzzel.enable = true;
    presets.home.desktop.hypridle.enable = true;
    presets.home.desktop.swaync.enable = true;

    # Cursor theme - standard arrow cursor
    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
    };

    # Dark mode preference
    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };

    # SwayOSD service for volume/brightness OSD
    systemd.user.services.swayosd = {
      Unit = {
        Description = "SwayOSD volume/brightness OSD";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };

    # SSH agent (for git, devcontainers, etc.)
    services.ssh-agent.enable = true;

    # Session variables for Wayland
    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      GDK_BACKEND = "wayland,x11";
      MOZ_ENABLE_WAYLAND = "1";
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
    };

    # Hyprland configuration
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "fuzzel";

        monitor = [
          "eDP-1,2880x1800@90,auto,1.5" # Laptop display
          "Virtual-1,1920x1200@60,auto,1" # QEMU/KVM VM display
          ",preferred,auto,auto" # Fallback for any other display
        ];

        env = [
          "XCURSOR_THEME,Adwaita"
          "XCURSOR_SIZE,24"
        ];

        cursor = {
          default_monitor = "";
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
          no_focus_fallback = true;
        };

        decoration = {
          rounding = 5;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "snappy, 0.25, 1, 0.5, 1"
            "smoothOut, 0.36, 0, 0.66, -0.56"
          ];
          animation = [
            "windows, 1, 3, snappy, slide"
            "windowsOut, 1, 3, smoothOut, slide"
            "border, 1, 4, snappy"
            "fade, 1, 3, snappy"
            "workspaces, 1, 3, snappy, slidevert"
          ];
        };

        dwindle = {
          pseudotile = true;
        };

        input = {
          kb_layout = "us,es";
          kb_variant = "intl,";
          kb_options = "grp:win_space_toggle";
          follow_mouse = 1;
          repeat_rate = 50;
          repeat_delay = 300;
          touchpad = {
            natural_scroll = true;
          };
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        bind = [
          "$mod, T, exec, $terminal"
          "$mod, D, exec, $menu"
          "$mod, Q, killactive,"
          "$mod, M, exit,"
          "$mod, E, exec, nautilus"
          "$mod, V, togglefloating,"
          "$mod, F, fullscreen,"
          # "$mod, P, pseudo,"
          "$mod, S, togglesplit,"

          # Switch keyboard layout (US intl / Spanish)
          "$mod, I, exec, hyprctl switchxkblayout all next"

          # Move focus with vim keys
          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, k, movefocus, u"
          "$mod, j, movefocus, d"

          # Move windows
          "$mod SHIFT, h, movewindow, l"
          "$mod SHIFT, l, movewindow, r"
          "$mod SHIFT, k, movewindow, u"
          "$mod SHIFT, j, movewindow, d"

          # Switch workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          # Move active window to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Scroll through workspaces
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # Screenshot (opens Satty for annotation)
          "$mod, P, exec, grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy"
          "$mod SHIFT, P, exec, grim - | satty -f - --copy-command wl-copy"

          # Lock screen
          "$mod, Escape, exec, WLR_RENDERER_ALLOW_SOFTWARE=1 hyprlock"

          # Enter move mode
          "$mod, a, submap, move"

          # Enter resize mode
          "$mod, r, submap, resize"
        ];

        # Repeat binds for volume/brightness (hold key to repeat)
        binde = [
          # Volume
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
          # Brightness
          ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
          ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
        ];

        # Non-repeat binds for mute toggles
        bindl = [
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        exec-once = [
          "waybar"
          "hyprpaper"
          "hypridle"
        ];
      };

      extraConfig = ''
        # Move mode submap
        submap = move
        bind = , h, movewindow, l
        bind = , l, movewindow, r
        bind = , k, movewindow, u
        bind = , j, movewindow, d
        bind = , Escape, submap, reset
        bind = , Return, submap, reset
        submap = reset

        # Resize mode submap
        submap = resize
        binde = , h, resizeactive, -20 0
        binde = , l, resizeactive, 20 0
        binde = , k, resizeactive, 0 -20
        binde = , j, resizeactive, 0 20
        bind = , Escape, submap, reset
        bind = , Return, submap, reset
        submap = reset
      '';
    };
  };
}
