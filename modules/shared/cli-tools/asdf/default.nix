{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.asdf.enable = mkEnableOption "asdf version manager";

  config = mkIf config.presets.shared.cli-tools.asdf.enable {
    home.packages = [ pkgs.asdf-vm ];

    programs.zsh.initContent = ''
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
    '';

    programs.bash.initExtra = ''
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
    '';
  };
}
