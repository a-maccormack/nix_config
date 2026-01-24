{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.presets.server.power-management;
  # Convert minutes to hdparm's spindown value (units of 5 seconds, max 20 minutes via standard values)
  # For longer times, use hdparm -S with value 241-251 (30min increments from 30min to 5.5hrs)
  # 60 minutes = 242 (30min + 1*30min)
  spindownValue =
    if cfg.hddSpindownMinutes <= 20 then
      toString (cfg.hddSpindownMinutes * 60 / 5) # 0-240: units of 5 seconds
    else if cfg.hddSpindownMinutes <= 330 then
      toString (241 + ((cfg.hddSpindownMinutes - 30) / 30)) # 241-251: 30min to 5.5hrs
    else
      "253"; # 253 = vendor-defined timeout
in
{
  options.presets.server.power-management = {
    enable = mkEnableOption "Server power management";

    hddSpindownMinutes = mkOption {
      type = types.int;
      default = 60;
      description = "Minutes of inactivity before HDD spindown";
    };

    cpuGovernor = mkOption {
      type = types.str;
      default = "powersave";
      description = "CPU frequency governor";
    };

    hddDevice = mkOption {
      type = types.str;
      default = "/dev/sda";
      description = "HDD device path for spindown configuration";
    };
  };

  config = mkIf cfg.enable {
    # CPU governor
    powerManagement.cpuFreqGovernor = cfg.cpuGovernor;

    # HDD spindown using hdparm via udev rule
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sda", RUN+="${pkgs.hdparm}/bin/hdparm -S ${spindownValue} /dev/sda"
    '';

    # Disable auto-suspend (manual only)
    services.logind.settings.Login = {
      IdleAction = "ignore";
      IdleActionSec = 0;
    };

    # Tools for manual power management
    environment.systemPackages = with pkgs; [
      hdparm
      smartmontools
    ];
  };
}
