{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.gemini.enable = mkEnableOption "google gemini cli";

  config = mkIf config.presets.shared.cli-tools.gemini.enable {
    home.packages = with pkgs; [
      gemini-cli
    ];
  };
}
