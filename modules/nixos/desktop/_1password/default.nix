{ lib, config, ... }:

with lib;

{
  options.presets.desktop._1password.enable = mkEnableOption "1Password with CLI integration";

  config = mkIf config.presets.desktop._1password.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "mac" ];
    };
  };
}
