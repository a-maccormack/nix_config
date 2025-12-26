{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.jq.enable = mkEnableOption "jq";

  config = mkIf config.presets.shared.cli-tools.jq.enable {
    programs.jq = {
      enable = true;
    };
  };
}
