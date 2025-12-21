{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.aws.enable = mkEnableOption "AWS CLI";

  config = mkIf config.presets.shared.cli-tools.aws.enable {
    home.packages = [ pkgs.awscli2 ];
  };
}
