{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
{
  options.presets.shared.cli-tools.devin-cli.enable = mkEnableOption "devin-cli";

  config = mkIf config.presets.shared.cli-tools.devin-cli.enable {
    home.packages = [ pkgs.devin-cli ];

    home.activation.devinAttribution = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.writeShellScript "devin-attribution" ''
        set -euo pipefail
        config_dir=${lib.escapeShellArg "${config.xdg.configHome}/devin"}
        mkdir -p "$config_dir"
        config_file="$config_dir/config.json"
        source=/dev/null
        if [ -f "$config_file" ]; then
          source="$config_file"
        fi
        temp=$(mktemp "$config_dir/config.json.XXXXXX")
        trap 'rm -f "$temp"' EXIT
        ${pkgs.jq}/bin/jq -s '(.[0] // {}) + {attribution: false}' "$source" > "$temp"
        mv "$temp" "$config_file"
      ''}
    '';
  };
}
