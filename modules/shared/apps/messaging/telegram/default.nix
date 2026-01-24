{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.messaging.telegram.enable = mkEnableOption "Telegram";

  config = mkIf config.presets.shared.apps.messaging.telegram.enable {
    home.packages = [ pkgs.telegram-desktop ];
  };
}
