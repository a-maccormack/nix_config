{ lib, ... }:

{
  # Shorthand for creating options
  mkOpt = type: default: description:
    lib.mkOption { inherit type default description; };

  mkOpt' = type: default:
    lib.mkOption { inherit type default; };

  # Quick enable/disable helpers
  enabled = { enable = true; };
  disabled = { enable = false; };
}
