{ lib, config, ... }:

with lib;

{
  options.presets.virtualisation.docker.enable = mkEnableOption "Docker daemon";

  config = mkIf config.presets.virtualisation.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
    };

    # Docker loads br_netfilter which makes bridged IP packets traverse
    # iptables. NixOS's strict reverse-path filter then drops them because
    # the input interface (veth) doesn't match the route (bridge). Loose
    # mode only checks that a route back to the source exists.
    networking.firewall.checkReversePath = "loose";

    # Add user to docker group
    users.users.mac.extraGroups = [ "docker" ];
  };
}
