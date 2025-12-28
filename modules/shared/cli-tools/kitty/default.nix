{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.kitty.enable = mkEnableOption "Kitty terminal";

  config = mkIf config.presets.shared.cli-tools.kitty.enable {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = "monospace";
        font_size = 16;
        enable_audio_bell = false;
        window_padding_width = 5;
        background_opacity = "0.85";
        confirm_os_window_close = 0;
        cursor_shape = "block";

        # Enable remote control for clipboard image paste workaround
        allow_remote_control = "socket-only";
        listen_on = "unix:$XDG_RUNTIME_DIR/kitty-socket";
      };
      keybindings = {
        # Override Ctrl+V to handle clipboard images (saves to temp file, pastes path)
        "ctrl+v" = "launch --type=background --allow-remote-control --keep-focus ${pkgs.writeShellScript "clip2path" ''
          set -e
          if [ -n "$WAYLAND_DISPLAY" ]; then
            types=$(${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null || echo "")
            if grep -q '^image/' <<<"$types"; then
              ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
              file="/tmp/clip_$(date +%s).''${ext}"
              ${pkgs.wl-clipboard}/bin/wl-paste > "$file"
              printf '%q' "$file" | kitty @ send-text --stdin
            else
              ${pkgs.wl-clipboard}/bin/wl-paste --no-newline | kitty @ send-text --stdin
            fi
          elif [ -n "$DISPLAY" ]; then
            types=$(${pkgs.xclip}/bin/xclip -selection clipboard -t TARGETS -o 2>/dev/null || echo "")
            if grep -q '^image/' <<<"$types"; then
              ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
              file="/tmp/clip_$(date +%s).''${ext}"
              ${pkgs.xclip}/bin/xclip -selection clipboard -t "image/''${ext}" -o > "$file"
              printf '%q' "$file" | kitty @ send-text --stdin
            else
              ${pkgs.xclip}/bin/xclip -selection clipboard -o | kitty @ send-text --stdin
            fi
          fi
        ''}";
      };
    };
  };
}
