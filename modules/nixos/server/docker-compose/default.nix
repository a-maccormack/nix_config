{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.server.docker-compose = {
    enable = mkEnableOption "Docker Compose auto-start";

    projectDirectory = mkOption {
      type = types.path;
      description = "Path to docker-compose.yml directory";
    };
  };

  config = mkIf config.presets.server.docker-compose.enable {
    # Ensure docker is enabled
    virtualisation.docker.enable = true;

    # Install docker-compose
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    # Systemd service to manage compose stack
    systemd.services.docker-compose-media = {
      description = "Docker Compose Media Stack";
      after = [ "docker.service" "network-online.target" "srv.mount" ];
      wants = [ "docker.service" "network-online.target" ];
      requires = [ "srv.mount" ]; # Wait for HDD to be mounted
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = config.presets.server.docker-compose.projectDirectory;
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      };
    };
  };
}
