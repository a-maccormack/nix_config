{ lib, config, ... }:

with lib;

{
  options.presets.system.nix.gc = {
    enable = mkEnableOption "automatic Nix garbage collection";

    dates = mkOption {
      type = types.str;
      default = "weekly";
      description = "How often to run garbage collection";
    };

    olderThan = mkOption {
      type = types.str;
      default = "7d";
      description = "Delete generations older than this";
    };
  };

  config = mkIf config.presets.system.nix.gc.enable {
    nix.gc = {
      automatic = true;
      dates = config.presets.system.nix.gc.dates;
      options = "--delete-older-than ${config.presets.system.nix.gc.olderThan}";
    };
  };
}
