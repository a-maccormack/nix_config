{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.gcloud.enable = mkEnableOption "Google Cloud CLI";

  config = mkIf config.presets.shared.cli-tools.gcloud.enable {
    home.packages = [ pkgs.google-cloud-sdk ];
  };
}
