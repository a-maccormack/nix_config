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

      # Capture tmux pane now (while we're still in Claude's environment)
      PANE="$TMUX_PANE"

      # Send notification and focus terminal on click
      # Fully detach so Claude doesn't wait on open file descriptors
      (
        notify-send "Claude Code" "${message}" \
          --app-name="Claude Code" \
          --icon=${claudeIcon} \
          --action=default=Focus \
          --wait
        # If clicked (not dismissed/expired), focus kitty and switch to the right tmux session
        hyprctl dispatch focuswindow "class:kitty" 2>/dev/null || true
        if [ -n "$PANE" ]; then
          TARGET=$(tmux display-message -p -t "$PANE" '#{session_name}:#{window_index}')
          tmux switch-client -t "$TARGET" 2>/dev/null || true
          tmux select-pane -t "$PANE" 2>/dev/null || true
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
in
{
  options.presets.shared.cli-tools.claude.enable = mkEnableOption "claude code cli";

  config = mkIf config.presets.shared.cli-tools.claude.enable {
    home.packages = with pkgs; [
      claude-code
    ];

    home.file.".claude/settings.json".force = true;
    home.file.".claude/settings.json".text = builtins.toJSON {
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
