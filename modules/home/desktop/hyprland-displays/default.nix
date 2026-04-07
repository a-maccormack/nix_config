{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.presets.home.desktop.hyprland-displays;

  # Quick mirror toggle using Hyprland's native mirror keyword
  hyprland-mirror = pkgs.writeShellScriptBin "hyprland-mirror" ''
    set -euo pipefail

    notify() {
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Displays" "$1"
    }

    # Find external monitors (not eDP-1)
    externals=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name != "eDP-1") | .name')

    if [ -z "$externals" ]; then
      notify "No external display connected"
      exit 0
    fi

    external=$(echo "$externals" | head -n1)

    # Check if already mirroring (mirror field is non-empty)
    is_mirroring=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r \
      --arg name "$external" \
      '.[] | select(.name == $name) | .mirrorOf')

    if [ -n "$is_mirroring" ] && [ "$is_mirroring" != "" ]; then
      # Stop mirroring — restore normal extend layout
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "$external,preferred,auto,auto"
      notify "Mirror off — extending to $external"
    else
      # Start mirroring internal display
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "$external,preferred,auto,auto,mirror,eDP-1"
      notify "Mirroring eDP-1 → $external"
    fi
  '';
in
{
  options.presets.home.desktop.hyprland-displays.enable =
    mkEnableOption "nwg-displays and mirror toggle for Hyprland";

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.nwg-displays
      hyprland-mirror
    ];
  };
}
