{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.shared.cli-tools.ansible.enable = mkEnableOption "Ansible automation";

  config = mkIf config.presets.shared.cli-tools.ansible.enable {
    home.packages = with pkgs; [
      ansible
      ansible-lint
    ];
  };
}
