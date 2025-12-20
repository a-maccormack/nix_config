{ lib, config, ... }:

with lib;

{
  options.presets.shared.cli-tools.git.enable = mkEnableOption "Git version control";

  config = mkIf config.presets.shared.cli-tools.git.enable {
    programs.git = {
      enable = true;

      # SSH signing
      signing = {
        key = "/home/mac/.ssh/gh_sign_key";
        signByDefault = true;
      };

      # All settings via the new unified settings API
      settings = {
        user = {
          name = "Alister MacCormack";
          email = "78695941+a-maccormack@users.noreply.github.com";
        };

        # Use SSH instead of HTTPS for GitHub
        url."git@github.com:".insteadOf = "https://github.com/";

        # Core settings
        core.editor = "nvim";

        # Default branch
        init.defaultBranch = "main";

        # GPG/SSH signing format
        gpg.format = "ssh";

        # Sign tags
        tag.gpgSign = true;
      };
    };
  };
}
