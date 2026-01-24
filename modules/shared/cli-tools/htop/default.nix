{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.cli-tools.htop.enable = mkEnableOption "htop - interactive process viewer";

  config = mkIf config.presets.shared.cli-tools.htop.enable {
    programs.htop = {
      enable = true;
    };
  };
}
