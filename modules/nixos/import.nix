# Auto-discovery module loader
# Recursively finds and imports all default.nix files in this directory
# Credit: Inspired by @infinisil's NixOS configuration

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
}
