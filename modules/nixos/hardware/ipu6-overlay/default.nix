{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hardware.ipu6-overlay.enable = lib.mkEnableOption "Fix icamerasrc-ipu6ep HAL linkage";

  config = lib.mkIf config.hardware.ipu6-overlay.enable {
    # v4l2loopback module options (apply to all dynamically-created devices):
    # - devices=0: no devices at boot; v4l2-relayd creates one via v4l2loopback-ctl add.
    # - exclusive_caps=1: loopback advertises only CAPTURE when writer is connected,
    #   only OUTPUT when no writer. Required for PipeWire's SPA V4L2 adapter to
    #   properly read frames (without it, PipeWire reads zeros).
    # - max_buffers=8: headroom so v4l2sink doesn't block instantly when a reader
    #   opens the device but hasn't consumed yet. At 720p YUY2 (~1.8 MB/frame),
    #   8 buffers ≈ 14 MB.
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=0 exclusive_caps=1 max_buffers=8
    '';

    # WirePlumber: clean up camera device list
    services.pipewire.wireplumber.extraConfig = {
      # Disable libcamera monitor — prevents it from competing with icamerasrc for the OV2740 sensor
      "50-disable-libcamera" = {
        "wireplumber.profiles" = {
          main = {
            "monitor.libcamera" = "disabled";
          };
        };
      };
      # All monitor.v4l2.rules MUST live in a single config file because
      # WirePlumber replaces (not merges) arrays when loading multiple files.
      "50-v4l2-rules" = {
        "monitor.v4l2.rules" = [
          # Hide raw IPU6 V4L2 devices (unusable raw Bayer data)
          {
            matches = [
              { "device.name" = "~v4l2_device.pci-0000_00_05*"; }
            ];
            actions = {
              update-props = {
                "device.disabled" = true;
              };
            };
          }
          # Hide raw IPU6 nodes
          {
            matches = [
              { "node.name" = "~v4l2_input.pci-0000_00_05*"; }
            ];
            actions = {
              update-props = {
                "node.disabled" = true;
              };
            };
          }
          # Keep the loopback Source node available for a while after the last
          # consumer disconnects. Prevents the device FD from being closed
          # too quickly during camera toggle (off → on), which with
          # exclusive_caps would briefly flip caps back to OUTPUT-only.
          {
            matches = [
              { "node.name" = "~v4l2_input.*virtual*"; }
            ];
            actions = {
              update-props = {
                "session.suspend-timeout-seconds" = 10;
              };
            };
          }
        ];
      };
    };

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

    # =========================================================================
    # INPUT PIPELINE
    # =========================================================================
    # - buffer-count=8: more HAL buffers for headroom (default: 6).
    # - queue + leaky=downstream: absorbs downstream stalls by dropping incoming
    #   frames instead of blocking icamerasrc. When v4l2sink blocks (reader
    #   connected but not consuming), the leaky queue keeps icamerasrc running
    #   so the HAL never enters an unrecoverable state.
    # - No GStreamer watchdog: the watchdog was killing the pipeline during HAL
    #   init (~35 s) because its 30 s timeout fired before the first frame.
    #   Recovery from true HAL failures is handled by the external systemd
    #   health-check timer instead.
    #
    # device-name=ov2740-uf: X1 Carbon Gen10 sensor; without this, icamerasrc
    # picks the wrong sensor tuning.
    services.v4l2-relayd.instances.ipu6.input.pipeline =
      lib.mkForce "icamerasrc device-name=ov2740-uf buffer-count=8 ! queue max-size-buffers=10 max-size-time=500000000 leaky=downstream";

    # Output NV12 instead of YUY2 (the default). icamerasrc already produces
    # NV12 so this skips a redundant format conversion. More importantly,
    # Firefox's PipeWire camera portal can negotiate NV12 but not YUY2.
    services.v4l2-relayd.instances.ipu6.output.format = "NV12";

    # =========================================================================
    # SYSTEMD HARDENING: Resource guarantees for camera service
    # =========================================================================
    systemd.services.v4l2-relayd-ipu6.unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 120;
    };

    systemd.services.v4l2-relayd-ipu6.serviceConfig = {
      # Restart delay: HAL needs time to release the OV2740 sensor.
      # 5s avoids "device busy" on restart after crash.
      RestartSec = 5;

      # Post-stop runs v4l2loopback-ctl delete, which fails with exit 16
      # when PipeWire still holds the device open. Treat this as success so
      # the service doesn't enter "failed" state and can restart cleanly.
      SuccessExitStatus = "0 16";

      # CPU: Realtime FIFO scheduling (runs before all normal processes)
      CPUSchedulingPolicy = "fifo";
      CPUSchedulingPriority = 50; # Mid-range RT (leaves room for audio at 70-90)
      CPUWeight = 1000; # 10x normal CPU share (cgroups fallback)

      # I/O: Priority access to camera device
      IOSchedulingClass = "realtime";
      IOSchedulingPriority = 4;
      IOWeight = 1000;

      # Memory: Protect from OOM and swapping
      OOMScoreAdjust = -500;
      MemoryLow = "64M";
      MemoryMin = "32M";

      # Realtime limits: Allow RT scheduling
      LimitRTPRIO = 99;
      LimitRTTIME = "infinity";
    };

    # =========================================================================
    # EXTERNAL HEALTH-CHECK: Catches HAL failures the pipeline can't self-detect
    # =========================================================================
    # Reads the device path that v4l2-relayd wrote during pre-start, then tries
    # to pull a single frame. Failure means icamerasrc died or the sensor is
    # unreachable — restart the service to re-init the HAL.
    systemd.services.v4l2-relayd-ipu6-watchdog = {
      description = "Health check for IPU6 camera pipeline";
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          let
            script = pkgs.writeShellScript "ipu6-watchdog" ''
              if ! systemctl is-active --quiet v4l2-relayd-ipu6; then
                echo "v4l2-relayd-ipu6 is not active, skipping health check"
                exit 0
              fi

              # Use the device file written by v4l2-relayd pre-start
              DEVICE_FILE="/run/v4l2-relayd-ipu6/device"
              if [ ! -f "$DEVICE_FILE" ]; then
                echo "No device file at $DEVICE_FILE — restarting v4l2-relayd-ipu6"
                systemctl restart v4l2-relayd-ipu6
                exit 0
              fi

              DEVICE="$(cat "$DEVICE_FILE")"
              if [ ! -e "$DEVICE" ]; then
                echo "Device $DEVICE does not exist — restarting v4l2-relayd-ipu6"
                systemctl restart v4l2-relayd-ipu6
                exit 0
              fi

              echo "Checking loopback device: $DEVICE"

              # Try reading a single frame with 10s timeout.
              # This briefly opens the loopback as a reader; v4l2sink will queue
              # a frame into it. With max_buffers=8 there is enough headroom
              # for this probe not to stall the pipeline.
              if ! timeout 10 ${pkgs.v4l-utils}/bin/v4l2-ctl --device="$DEVICE" --stream-mmap --stream-count=1 2>/dev/null; then
                echo "No frames flowing on $DEVICE — restarting v4l2-relayd-ipu6"
                systemctl restart v4l2-relayd-ipu6
                exit 0
              fi

              echo "Pipeline healthy: frames flowing on $DEVICE"
            '';
          in
          "${script}";
      };
    };

    systemd.timers.v4l2-relayd-ipu6-watchdog = {
      description = "Periodic health check for IPU6 camera pipeline";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "90s"; # Grace period: HAL init takes ~35s
        OnUnitActiveSec = "60s"; # Check every 60s (was 30s — less aggressive)
        AccuracySec = "5s";
      };
    };

    # =========================================================================
    # WIREPLUMBER RE-PROBE
    # =========================================================================
    # With exclusive_caps=1, WirePlumber's initial probe sees OUTPUT-only
    # (v4l2-relayd hasn't opened the device yet) and never creates a
    # PipeWire Video/Source node. Firefox needs this node via the Camera
    # portal.
    #
    # This service polls every 5 s. When the loopback shows CAPTURE but
    # no PipeWire Video/Source node exists, it restarts WirePlumber so it
    # re-probes and creates the node. Handles both boot and v4l2-relayd
    # restarts.
    systemd.user.services.ipu6-wireplumber-reprobe = {
      description = "Ensure PipeWire Video/Source exists for IPU6 loopback";
      wantedBy = [ "wireplumber.service" ];
      after = [ "wireplumber.service" ];
      serviceConfig = {
        ExecStart =
          let
            script = pkgs.writeShellScript "ipu6-wireplumber-reprobe" ''
              DEVICE_FILE="/run/v4l2-relayd-ipu6/device"

              while true; do
                sleep 5

                # Skip if no device file yet
                if [ ! -f "$DEVICE_FILE" ]; then
                  continue
                fi

                DEVICE="$(cat "$DEVICE_FILE")"

                # Skip if device doesn't exist
                if [ ! -e "$DEVICE" ]; then
                  continue
                fi

                # Skip if device doesn't show CAPTURE (writer not connected)
                if ! ${pkgs.v4l-utils}/bin/v4l2-ctl --device="$DEVICE" --all 2>/dev/null | grep -q "Video Capture"; then
                  continue
                fi

                # Check if a Video/Source node already exists
                if wpctl status 2>/dev/null | grep -q "Video/Source\|v4l2_input.*virtual"; then
                  continue
                fi

                echo "CAPTURE available on $DEVICE but no Video/Source node — restarting WirePlumber"
                sleep 3  # let v4l2-relayd pipeline fully stabilize
                systemctl --user restart wireplumber
                sleep 10  # avoid rapid restart loops
              done
            '';
          in
          "${script}";
        Restart = "always";
        RestartSec = 5;
      };
    };

    # Suspend/resume: cleanly stop before sleep, restart after wake.
    # Stopping before suspend prevents HAL corruption from being frozen mid-operation.
    powerManagement.powerDownCommands = ''
      ${pkgs.systemd}/bin/systemctl stop v4l2-relayd-ipu6
    '';
    powerManagement.resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl start v4l2-relayd-ipu6
    '';
  };
}
