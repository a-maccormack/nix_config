{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.home.apps.firefox.enable = mkEnableOption "Firefox browser";

  config = mkIf config.presets.home.apps.firefox.enable {
    programs.firefox.enable = true;

    # Override Firefox desktop entry to launch profile manager
    xdg.desktopEntries.firefox = {
      name = "Firefox";
      genericName = "Web Browser";
      exec = "firefox --ProfileManager";
      icon = "firefox";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };
}
