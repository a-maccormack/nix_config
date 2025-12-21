{ config, lib, pkgs, ... }:

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

    # 1. Kernel Modules
    boot.extraModulePackages = [
      customDrivers
      config.boot.kernelPackages.v4l2loopback
    ];

    boot.kernelModules = [
      "intel-ipu6"
      "intel-ipu6-isys"
      "intel-ipu6-psys"
      "v4l2loopback"
    ];

    boot.extraModprobeConfig = ''
      options v4l2loopback video_nr=32 card_label="Intel MIPI Camera" max_buffers=2
    '';

    # 2. Firmware - use nixpkgs
    hardware.ipu6.enable = false;  # We manage this manually
    hardware.firmware = [ pkgs.ipu6-camera-bins ];

    # 3. Userspace / HAL
    environment.systemPackages = [
      halPkg
      icamerasrcPkg
      pkgs.v4l-utils
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

    # 4. Systemd Service for Loopback
    # Note: v4l2loopback creates /dev/video32 (after IPU6's video0-31)
    systemd.services.ipu6-loopback = {
      description = "IPU6 Camera to V4L2 Loopback";
      after = [ "sys-subsystem-video-devices-video32.device" ];
      wants = [ "sys-subsystem-video-devices-video32.device" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        export GST_PLUGIN_SYSTEM_PATH_1_0=${icamerasrcPkg}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gstreamer.out}/lib/gstreamer-1.0

        # Set the v4l2loopback output format before starting the pipeline
        ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/video32 --set-fmt-video=width=1280,height=720,pixelformat=YUYV

        # Wait for camera sensor to initialize
        sleep 2

        ${pkgs.gst_all_1.gstreamer}/bin/gst-launch-1.0 -v \
          icamerasrc device-name=ov2740-uf ! \
          video/x-raw,format=NV12,width=1280,height=720 ! \
          videoconvert ! \
          video/x-raw,format=YUY2 ! \
          v4l2sink device=/dev/video32
      '';
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
        User = "root";
      };
    };

    # 5. Udev rules for IPU6 devices
    services.udev.extraRules = ''
      # IPU6 PSYS device - allow video group access
      KERNEL=="ipu-psys[0-9]*", GROUP="video", MODE="0660"
    '';

    # 6. GStreamer Environment
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
