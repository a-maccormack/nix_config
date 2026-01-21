{ lib, config, ... }:

with lib;

let
  cfg = config.presets.shared.cli-tools.git;
in
{
  options.presets.shared.cli-tools.git = {
    enable = mkEnableOption "Git version control";
    useSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Use SSH instead of HTTPS for GitHub and enable commit signing";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      # SSH signing (only when useSSH is enabled)
      signing = mkIf cfg.useSSH {
        key = "/home/mac/.ssh/gh_sign_key";
        signByDefault = true;
      };

      # All settings via the new unified settings API
      settings = {
        user = {
          name = "Alister MacCormack";
          email = "78695941+a-maccormack@users.noreply.github.com";
        };

        # Use SSH instead of HTTPS for GitHub (only when useSSH is enabled)
        url = mkIf cfg.useSSH {
          "git@github.com:".insteadOf = "https://github.com/";
        };

        # Core settings
        core.editor = "nvim";

        # Default branch
        init.defaultBranch = "main";

        # GPG/SSH signing format (only when useSSH is enabled)
        gpg = mkIf cfg.useSSH {
          format = "ssh";
        };

        # Sign tags (only when useSSH is enabled)
        tag = mkIf cfg.useSSH {
          gpgSign = true;
        };
      };
    };
  };
}
