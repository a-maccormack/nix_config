{ lib, config, ... }:

with lib;

{
  options.presets.server.openssh = {
    enable = mkEnableOption "OpenSSH server for headless access";

    port = mkOption {
      type = types.port;
      default = 22;
      description = "SSH port";
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH public keys for user access";
    };
  };

  config = mkIf config.presets.server.openssh.enable {
    services.openssh = {
      enable = true;
      ports = [ config.presets.server.openssh.port ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users.mac.openssh.authorizedKeys.keys = config.presets.server.openssh.authorizedKeys;
  };
}
