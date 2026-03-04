{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.shared.apps.messaging.slack.enable = mkEnableOption "Slack";

  config = mkIf config.presets.shared.apps.messaging.slack.enable {
    home.packages = [
      (pkgs.slack.overrideAttrs (old: {
        installPhase = (old.installPhase or "") + ''
          wrapProgram $out/bin/slack \
            --add-flags "--enable-features=WebRTCPipeWireCapturer"
        '';
      }))
    ];

    # Link Slack icon to hicolor theme so launchers can find it
    xdg.dataFile."icons/hicolor/512x512/apps/slack.png".source =
      "${pkgs.slack}/share/pixmaps/slack.png";
  };
}
