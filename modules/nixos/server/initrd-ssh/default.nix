{ lib, config, ... }:

with lib;

{
  options.presets.server.initrd-ssh = {
    enable = mkEnableOption "SSH in initrd for remote LUKS unlock";

    port = mkOption {
      type = types.port;
      default = 2222;
      description = "SSH port for initrd (use different port than normal SSH)";
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH public keys authorized for initrd unlock";
    };

    hostKeys = mkOption {
      type = types.listOf types.path;
      default = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      description = "SSH host key paths for initrd";
    };
  };

  config = mkIf config.presets.server.initrd-ssh.enable {
    boot.initrd = {
      availableKernelModules = [ "e1000e" ]; # Intel NIC for ThinkCentre

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = config.presets.server.initrd-ssh.port;
          authorizedKeys = config.presets.server.initrd-ssh.authorizedKeys;
          hostKeys = config.presets.server.initrd-ssh.hostKeys;
        };
      };

      systemd.users.root.shell = "/bin/cryptsetup-askpass";
    };
  };
}
