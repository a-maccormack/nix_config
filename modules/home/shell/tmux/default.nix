{ lib, config, ... }:

with lib;

{
  options.presets.home.shell.tmux.enable = mkEnableOption "Tmux terminal multiplexer";

  config = mkIf config.presets.home.shell.tmux.enable {
    programs.tmux = {
      enable = true;
      extraConfig = ''
        # 256-color support
        set-option -g default-terminal "tmux-256color"
        set -as terminal-overrides ",tmux-256color:RGB"

        set-option -g set-clipboard on

        setw -g mode-keys vi
        set -s escape-time 0

        # Pane navigation with Alt + Shift + Vim keys
        bind -n M-h select-pane -L  # Alt+h
        bind -n M-j select-pane -D  # Alt+j
        bind -n M-k select-pane -U  # Alt+k
        bind -n M-l select-pane -R  # Alt+l

        # Enable mouse
        set -g mouse on
        bind -n M-c copy-mode

        # Split pane to the right with Ctrl+Alt+R (inherit cwd)
        bind -n C-M-r split-window -h -c "#{pane_current_path}"

        # Split pane down with Ctrl+Alt+D (inherit cwd)
        bind -n C-M-d split-window -v -c "#{pane_current_path}"

        # Zoom into pane
        bind -n M-f resize-pane -Z

        # Alt + number to switch to session N if it exists
        bind -n M-0 switch-client -t 0
        bind -n M-1 switch-client -t 1
        bind -n M-2 switch-client -t 2
        bind -n M-3 switch-client -t 3
        bind -n M-4 switch-client -t 4
        bind -n M-5 switch-client -t 5
        bind -n M-6 switch-client -t 6
        bind -n M-7 switch-client -t 7
        bind -n M-8 switch-client -t 8
        bind -n M-9 switch-client -t 9

        # Create a new session in the first free slot (1-9)
        bind -n M-n run-shell '
          for i in $(seq 1 9); do
            tmux has-session -t "$i" 2>/dev/null || {
              tmux new-session -d -s "$i"
              tmux switch-client -t "$i"
              break
            }
          done
        '

        # Alt + s -> Choose and switch session
        bind-key -n M-s choose-session

        # Alt + Shift + S -> Choose and switch, then kill current session
        bind-key -n M-S choose-session -Z "run-shell 'tmux switch-client -t %% && tmux kill-session -t #{session_name}'"

        # Preset binding
        bind -n M-p display-popup -E "~/scripts/launch_tmuxp_indexed.sh"
      '';
    };
  };
}
