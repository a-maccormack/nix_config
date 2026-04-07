{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.presets.home.desktop.hyprland-displays;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";
  notify = "${pkgs.libnotify}/bin/notify-send";
  fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
  wl-mirror = "${pkgs.wl-mirror}/bin/wl-mirror";

  restart-waybar = pkgs.writeShellScriptBin "restart-waybar" ''
    # GTK3 doesn't reliably detect monitors present at compositor start.
    # Cycling external monitors (disable → re-enable) forces GDK to see
    # them as fresh wl_output events. Delays are required to avoid GTK
    # double-registering outputs which causes duplicate bars.
    pkill -9 -x waybar 2>/dev/null
    while pgrep -x waybar >/dev/null 2>&1; do sleep 0.1; done

    for mon in $(${hyprctl} monitors -j | ${jq} -r '.[].name' | grep -v eDP); do
      ${hyprctl} keyword monitor "$mon,disable" >/dev/null 2>&1
    done
    sleep 1
    for mon in $(${hyprctl} monitors all -j | ${jq} -r '.[] | select(.disabled == true) | .name'); do
      ${hyprctl} keyword monitor "$mon,preferred,auto,auto" >/dev/null 2>&1
    done
    sleep 2

    waybar &disown
  '';

  hyprland-mirror = pkgs.writeShellScriptBin "hyprland-mirror" ''
    set -euo pipefail

    notify() { ${notify} -t 3000 "Displays" "$1"; }

    INTERNAL="eDP-1"

    # Toggle off if wl-mirror is running
    if pkill -x wl-mirror 2>/dev/null; then
      notify "Mirror off"
      exit 0
    fi

    # Get external monitors
    mapfile -t EXTERNALS < <(${hyprctl} monitors -j | ${jq} -r \
      --arg int "$INTERNAL" '.[] | select(.name != $int) | .name')

    if [ ''${#EXTERNALS[@]} -eq 0 ]; then
      notify "No external display connected"
      exit 0
    fi

    # If multiple externals, let the user pick
    if [ ''${#EXTERNALS[@]} -gt 1 ]; then
      EXTERNAL=$(printf '%s\n' "''${EXTERNALS[@]}" | ${fuzzel} --dmenu --prompt "Mirror to: ")
      [ -z "$EXTERNAL" ] && exit 0
    else
      EXTERNAL="''${EXTERNALS[0]}"
    fi

    notify "Mirroring $INTERNAL → $EXTERNAL"
    ${hyprctl} dispatch exec "[monitor:$EXTERNAL fullscreen]" "${wl-mirror} $INTERNAL" >/dev/null
  '';
in
{
  options.presets.home.desktop.hyprland-displays.enable =
    mkEnableOption "Display management for Hyprland";

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.wdisplays
      pkgs.wl-mirror
      hyprland-mirror
      restart-waybar
    ];

    wayland.windowManager.hyprland.settings = {
      # Start waybar via restart-waybar (handles GTK3 multi-monitor bug)
      exec-once = [ "restart-waybar" ];
    };
  };
}
