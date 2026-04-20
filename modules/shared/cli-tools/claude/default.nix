{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  claudeIcon = ../../../../assets/icons/claude-color.svg;
  mkClaudeNotifyScript =
    { name, message }:
    pkgs.writeShellScript name ''
      # Read stdin (required by Claude hooks)
      cat > /dev/null

      # Silent no-op on non-desktop systems
      command -v notify-send > /dev/null 2>&1 || exit 0

      # Capture tmux context now (while we're still in Claude's environment)
      PANE="$TMUX_PANE"
      if [ -n "$PANE" ]; then
        TARGET=$(tmux display-message -p -t "$PANE" '#{session_name}:#{window_index}')
        CLIENT_TTY=$(tmux display-message -p '#{client_tty}')
      fi

      # Send notification and focus terminal on click
      # Fully detach so Claude doesn't wait on open file descriptors
      (
        STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/claude-focus-target"
        FIFO=$(mktemp -u)
        mkfifo "$FIFO"

        # Send notification; --print-id writes ID to FIFO, --wait blocks until interaction
        notify-send "Claude Code" "${message}" \
          --app-name="Claude Code" \
          --icon=${claudeIcon} \
          --action=default=Focus \
          --print-id \
          --wait > "$FIFO" 2>/dev/null &
        NPID=$!

        # Read notification ID immediately via FIFO (blocks until written)
        exec 3<"$FIFO"
        read -r NOTIF_ID <&3

        # Persist state for keybinding-based focus (SUPER+O)
        printf '%s\n%s\n%s\n%s\n' "$PANE" "$TARGET" "$NOTIF_ID" "$CLIENT_TTY" > "$STATE_FILE"

        # Wait for notification to be clicked or dismissed
        wait $NPID
        read -r ACTION <&3 2>/dev/null || true
        exec 3<&-
        rm -f "$FIFO"

        # Only focus if the notification action was clicked (not dismissed/expired)
        if [ "$ACTION" = "default" ]; then
          hyprctl dispatch focuswindow "class:kitty" 2>/dev/null || true
          if [ -n "$PANE" ]; then
            tmux switch-client -t "$TARGET" 2>/dev/null || true
            tmux select-pane -t "$PANE" 2>/dev/null || true
          fi
        fi
      ) </dev/null >/dev/null 2>&1 &
    '';
  notifyScript = mkClaudeNotifyScript {
    name = "claude-notify";
    message = "Needs your attention";
  };
  stopScript = mkClaudeNotifyScript {
    name = "claude-stop";
    message = "Finished responding";
  };
  claudeFocusScript = pkgs.writeShellScriptBin "claude-focus" ''
    STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/claude-focus-target"
    [ -f "$STATE_FILE" ] || exit 0

    { read -r PANE; read -r TARGET; read -r NOTIF_ID; read -r CLIENT_TTY; } < "$STATE_FILE"

    # Dismiss the specific Claude notification via freedesktop dbus
    if [ -n "$NOTIF_ID" ]; then
      dbus-send --session --type=method_call \
        --dest=org.freedesktop.Notifications \
        /org/freedesktop/Notifications \
        org.freedesktop.Notifications.CloseNotification \
        "uint32:$NOTIF_ID" 2>/dev/null || true
    fi

    hyprctl dispatch focuswindow "class:kitty" 2>/dev/null || true
    if [ -n "$PANE" ]; then
      tmux switch-client -c "$CLIENT_TTY" -t "$TARGET" 2>/dev/null || true
      tmux select-pane -t "$PANE" 2>/dev/null || true
    fi
  '';
in
{
  options.presets.shared.cli-tools.claude.enable = mkEnableOption "claude code cli";

  config = mkIf config.presets.shared.cli-tools.claude.enable {
    home.packages = with pkgs; [
      claude-code
      claudeFocusScript
    ];

    home.file.".claude/settings.json".force = true;
    home.file.".claude/settings.json".text = builtins.toJSON {
      effortLevel = "high";
      hooks = {
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = toString notifyScript;
              }
            ];
          }
        ];
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = toString stopScript;
              }
            ];
          }
        ];
      };
      attribution = {
        commit = "";
        pr = "";
      };
    };
  };
}
