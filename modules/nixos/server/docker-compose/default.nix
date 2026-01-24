{
  lib,
  config,
  pkgs,
  ...
}:

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

    # Install docker-compose and curl (for init script)
    environment.systemPackages = with pkgs; [
      docker-compose
      curl
    ];

    # Systemd service to manage compose stack
    systemd.services.docker-compose-media = {
      description = "Docker Compose Media Stack";
      after = [
        "docker.service"
        "network-online.target"
        "srv.mount"
      ];
      wants = [
        "docker.service"
        "network-online.target"
      ];
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

    # Auto-configure media stack on first boot
    systemd.services.media-stack-init = {
      description = "Initialize Media Stack Connections";
      after = [ "docker-compose-media.service" ];
      wants = [ "docker-compose-media.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        curl
        bash
        gnugrep
        coreutils
      ];

      environment = {
        CONFIG_PATH = "/srv/config";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.presets.server.docker-compose.projectDirectory}/init-media-stack.sh";
      };

      unitConfig = {
        # Only run if not already initialized
        ConditionPathExists = "!/srv/config/.media-stack-initialized";
      };
    };
  };
}
