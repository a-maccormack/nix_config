{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.curl.enable = mkEnableOption "curl - command line URL tool";

  config = mkIf config.presets.shared.cli-tools.curl.enable {
    home.packages = [ pkgs.curl ];
  };
}
