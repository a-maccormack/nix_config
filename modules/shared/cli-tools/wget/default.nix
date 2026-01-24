{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.wget.enable = mkEnableOption "wget - network downloader";

  config = mkIf config.presets.shared.cli-tools.wget.enable {
    home.packages = [ pkgs.wget ];
  };
}
