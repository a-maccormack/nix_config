{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.kitty.enable = mkEnableOption "Kitty terminal";

  config = mkIf config.presets.shared.cli-tools.kitty.enable {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = "monospace";
        font_size = 12;
        enable_audio_bell = false;
        window_padding_width = 5;
        background_opacity = "0.85";
        confirm_os_window_close = 0;
      };
    };
  };
}
