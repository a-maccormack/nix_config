{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.claude.enable = mkEnableOption "claude code cli";

  config = mkIf config.presets.shared.cli-tools.claude.enable {
    home.packages = with pkgs; [
      claude-code
    ];
  };
}
