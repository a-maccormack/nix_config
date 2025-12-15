# Auto-discovery module loader for Home-Manager
# Recursively finds and imports all default.nix files in this directory

{ lib, config, pkgs, ... }:

let
  # Get directory contents
  getDir = path: builtins.readDir path;

  # Recursively collect all files
  files =
    let
      go = dir: prefix:
        let
          contents = getDir dir;
          process = name: type:
            if type == "directory" then
              go "${dir}/${name}" "${prefix}${name}/"
            else
              [ "${prefix}${name}" ];
        in
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs process contents));
    in
    go ./. "";

  # Filter for default.nix files (excluding this import.nix)
  defaultNixFiles = builtins.filter
    (f: builtins.match ".*default\\.nix" f != null && f != "import.nix")
    files;

  # Convert to import paths
  imports = map (f: ./. + "/${f}") defaultNixFiles;

in
{
  inherit imports;

  # Base home-manager config
  programs.home-manager.enable = true;
}
