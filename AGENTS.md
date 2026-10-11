# Project notes

- Hyprland's normal Waybar startup and the `hyprland-displays` preset's `restart-waybar` startup must remain mutually exclusive. The workstation uses normal startup; `x1-carbon-g10` enables the display-management preset.
- Verify workstation changes with `nix build .#nixosConfigurations.workstation.config.system.build.toplevel --no-link` (builds without activating). Add `--option eval-cache false` when checking evaluation warnings so cached evaluations do not hide them.
- Inspect each host's startup commands with `nix eval --json .#nixosConfigurations.<host>.config.home-manager.users.mac.wayland.windowManager.hyprland.settings.exec-once`.
