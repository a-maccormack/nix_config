{ lib, config, pkgs, ... }:

with lib;

{
  options.presets.system.bash.binbash = mkEnableOption "/bin/bash symlink for script compatibility";

  config = mkIf config.presets.system.bash.binbash {
    system.activationScripts.binbash = ''
      ln -sfn ${pkgs.bash}/bin/bash /bin/bash
    '';
  };
}
