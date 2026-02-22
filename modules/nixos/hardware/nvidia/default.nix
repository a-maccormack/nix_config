{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.hardware.nvidia.enable = mkEnableOption "NVIDIA GPU support";

  config = mkIf config.presets.hardware.nvidia.enable {
    # NVIDIA driver
    services.xserver.videoDrivers = [ "nvidia" ];

    # Graphics (OpenGL / Vulkan)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      open = true; # Ampere (RTX 30xx) fully supported
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false; # Desktop - no power management
    };

    # NVIDIA modules in initrd for early KMS
    boot.initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    boot.kernelParams = [ "nvidia-drm.modeset=1" ];

    # Session variables for Hyprland + NVIDIA
    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
