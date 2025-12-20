{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.tmuxp.enable = mkEnableOption "tmuxp - tmux session manager";

  config = mkIf config.presets.shared.cli-tools.tmuxp.enable {
    home.packages = [ pkgs.tmuxp ];

    # Create the launcher script in ~/.local/bin
    home.file.".local/bin/launch-tmuxp".source = pkgs.writeShellScript "launch-tmuxp" ''
      CONFIG_DIR="$HOME/.config/tmuxp"

      # Check if fzf is available
      if ! command -v fzf &> /dev/null; then
        echo "fzf is required but not installed"
        exit 1
      fi

      # Check if config directory exists
      if [ ! -d "$CONFIG_DIR" ]; then
        echo "No tmuxp config directory found at $CONFIG_DIR"
        exit 1
      fi

      # List configs and select with fzf
      CONFIG=$(ls "$CONFIG_DIR" | sed 's/\.ya\?ml$//' | fzf --prompt='Choose tmuxp config: ')

      # Exit if no selection
      [ -z "$CONFIG" ] && exit 0

      # Find first available session slot and launch
      for i in $(seq 0 9); do
        tmux has-session -t "$i" 2>/dev/null || {
          tmuxp load -y -s "$i" "$CONFIG_DIR/$CONFIG.yaml" 2>/dev/null || \
          tmuxp load -y -s "$i" "$CONFIG_DIR/$CONFIG.yml"
          tmux switch-client -t "$i"
          break
        }
      done
    '';
  };
}
