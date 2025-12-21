{ config, lib, pkgs, ... }:

{
  options.hardware.ipu6-overlay.enable = lib.mkEnableOption "Fix icamerasrc-ipu6ep HAL linkage";

  config = lib.mkIf config.hardware.ipu6-overlay.enable {
    nixpkgs.overlays = [
      (final: prev: {
        gst_all_1 = prev.gst_all_1 // {
          # Override icamerasrc-ipu6ep to link against correct HAL
          icamerasrc-ipu6ep = prev.gst_all_1.icamerasrc-ipu6ep.override {
            ipu6-camera-hal = final.ipu6ep-camera-hal;
          };
        };
      })
    ];

    # HAL requires /run/camera for AIQD cache files
    systemd.tmpfiles.rules = [
      "d /run/camera 0755 root root -"
    ];

    # Fix: Native module uses "icamerasrc" without device-name, causing wrong sensor detection.
    # X1 Carbon Gen10 has ov2740 sensor - must specify device-name to load correct tuning.
    services.v4l2-relayd.instances.ipu6.input.pipeline = lib.mkForce "icamerasrc device-name=ov2740-uf";
  };
}
