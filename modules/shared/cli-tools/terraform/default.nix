{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.terraform.enable =
    mkEnableOption "Terraform infrastructure as code";

  config = mkIf config.presets.shared.cli-tools.terraform.enable {
    home.packages = with pkgs; [
      terraform
      terraform-ls
    ];
  };
}
