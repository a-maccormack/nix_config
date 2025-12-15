{ lib, config, ... }:

with lib;

{
  options.presets.virtualisation.docker.enable = mkEnableOption "Docker daemon";

  config = mkIf config.presets.virtualisation.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
    };

    # Add user to docker group
    users.users.mac.extraGroups = [ "docker" ];
  };
}
