{ lib, config, ... }:

with lib;

let
  # Auto-discover all tool directories in cli-tools/
  toolNames = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./.)
  );

  # Generate enable statements for each tool
  enableTools = lib.genAttrs toolNames (_: {
    enable = true;
  });
in
{
  options.presets.shared.cli-tools.enable = mkEnableOption "all CLI tools in shared/cli-tools/";

  config = mkIf config.presets.shared.cli-tools.enable {
    presets.shared.cli-tools = enableTools;
  };
}
