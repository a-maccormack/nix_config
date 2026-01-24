{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Use custom drivers package for kernel module
  customDrivers = pkgs.callPackage ./pkgs/drivers.nix {
    kernel = config.boot.kernelPackages.kernel;
  };

  # Use the correct ipu6ep HAL
  halPkg = pkgs.ipu6ep-camera-hal;

  # Build custom icamerasrc linked against the correct ipu6ep HAL
  icamerasrcPkg = pkgs.callPackage ./pkgs/icamerasrc.nix {
    intel-ipu6-camera-hal = halPkg;
    inherit (pkgs) gst_all_1 libdrm libva;
  };
in
{
  options.hardware.ipu6-custom.enable = lib.mkEnableOption "Custom IPU6 stack with v4l2loopback";

  config = lib.mkIf config.hardware.ipu6-custom.enable {
    # Allow unfree firmware
    nixpkgs.config.allowUnfree = true;

    # 1. Kernel Modules (v4l2loopback is managed by v4l2-relayd service)
    boot.extraModulePackages = [
      customDrivers
    ];

    boot.kernelModules = [
      "intel-ipu6"
      "intel-ipu6-isys"
      "intel-ipu6-psys"
    ];

    # 2. Firmware - use nixpkgs
    hardware.ipu6.enable = false; # We manage this manually
    hardware.firmware = [ pkgs.ipu6-camera-bins ];

    # 3. Userspace / HAL
    environment.systemPackages = [
      halPkg
      icamerasrcPkg
      pkgs.v4l-utils
      pkgs.v4l2-relayd
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      # Test script
      (pkgs.writeShellScriptBin "ipu6-test" ''
        export GST_PLUGIN_SYSTEM_PATH_1_0=${icamerasrcPkg}/lib/gstreamer-1.0:$GST_PLUGIN_SYSTEM_PATH_1_0
        gst-launch-1.0 icamerasrc ! video/x-raw,format=NV12,width=1280,height=720 ! videoconvert ! autovideosink
      '')
    ];

    # 4. v4l2-relayd: On-demand camera activation
    # Uses official NixOS module - camera only activates when an app opens the device
    services.v4l2-relayd.instances.ipu6 = {
      enable = true;
      cardLabel = "Intel MIPI Camera";

      input = {
        pipeline = "icamerasrc device-name=ov2740-uf";
        format = "NV12";
        width = 1280;
        height = 720;
        framerate = 30;
      };

      output.format = "YUY2";

      extraPackages = [
        icamerasrcPkg
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
      ];
    };

    # 5. Udev rules for IPU6 devices
    services.udev.extraRules = ''
      # IPU6 PSYS device - allow video group access
      KERNEL=="ipu-psys[0-9]*", GROUP="video", MODE="0660"
    '';

    # 6. Create /run/camera directory for HAL
    systemd.tmpfiles.rules = [
      "d /run/camera 0755 root root -"
    ];

    # 7. Ensure v4l2-relayd service handles cleanup gracefully
    systemd.services.v4l2-relayd-ipu6 = {
      # Wait for tmpfiles to create /run/camera
      after = [ "systemd-tmpfiles-setup.service" ];
      requires = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        # Increase restart delay to avoid rapid cycling when device is busy
        RestartSec = lib.mkForce 3;
        # Override post-stop to handle "device busy" gracefully
        # The default script fails if Firefox still holds the device
        ExecStopPost = lib.mkForce (
          pkgs.writeShellScript "v4l2-relayd-ipu6-post-stop" ''
            if [ -f "$V4L2_DEVICE_FILE" ]; then
              DEVICE=$(cat "$V4L2_DEVICE_FILE")
              # Try to delete, retry up to 5 times with 1s delay
              for i in 1 2 3 4 5; do
                if ${config.boot.kernelPackages.v4l2loopback.bin}/bin/v4l2loopback-ctl delete "$DEVICE" 2>/dev/null; then
                  break
                fi
                sleep 1
              done
              rm -rf "$(dirname "$V4L2_DEVICE_FILE")"
            fi
          ''
        );
      };
    };

    # 8. GStreamer Environment
    environment.sessionVariables = {
      GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
        icamerasrcPkg
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gstreamer.out
      ];
    };
  };
}
