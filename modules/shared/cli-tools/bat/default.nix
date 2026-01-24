{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.bat.enable =
    mkEnableOption "bat - cat clone with syntax highlighting";

  config = mkIf config.presets.shared.cli-tools.bat.enable {
    programs.bat = {
      enable = true;
    };
  };
}
