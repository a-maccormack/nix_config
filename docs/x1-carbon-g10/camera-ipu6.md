# IPU6 Camera — X1 Carbon Gen 10

## Hardware

- Intel IPU6EP (Alder Lake, 12th gen)
- OV2740 sensor
- v4l2loopback virtual device at `/dev/video34` (created by v4l2-relayd)

## Architecture

```
OV2740 sensor → icamerasrc (HAL) → v4l2-relayd → v4l2loopback → PipeWire → apps
```

v4l2loopback runs with `exclusive_caps=1`, meaning it advertises CAPTURE only when a writer (v4l2-relayd) is connected, and OUTPUT only when no writer is present.

## Known Issues

### WirePlumber reprobe script must use full wpctl path

The `ipu6-wireplumber-reprobe` user service runs a polling loop that checks whether WirePlumber has created a Video/Source node for the loopback device. It calls `wpctl status` to check.

**Problem:** `writeShellScript` produces a script with a minimal PATH (coreutils, findutils, grep, sed, systemd). `wpctl` is not in this PATH, so the check always fails, causing WirePlumber to restart every ~18 seconds in an infinite loop.

**Symptoms:**
- Bluetooth headphones connect then immediately disconnect, cycling forever
- Camera node appears briefly then disappears
- `journalctl --user -u ipu6-wireplumber-reprobe` shows continuous "restarting WirePlumber" messages

**Fix:** Use `${pkgs.wireplumber}/bin/wpctl` instead of bare `wpctl`. Also added a 5-attempt max guard so the script gives up instead of looping forever if the node genuinely can't be created.

### Camera flicker on Google Meet mute/unmute

When unmuting on Google Meet, PipeWire renegotiates the graph. The v4l2loopback node briefly goes idle. With the default `session.suspend-timeout-seconds` (usually 5-10s), WirePlumber suspends the node. With `exclusive_caps=1`, suspension closes the FD, flipping caps to OUTPUT-only, making WirePlumber think the camera disappeared.

**Fix:** Set `session.suspend-timeout-seconds = 86400` (24 hours) on the virtual camera node. v4l2-relayd runs continuously, so there's no resource cost.

```nix
# In 50-v4l2-rules
{
  matches = [{ "node.name" = "~v4l2_input.*virtual*"; }];
  actions.update-props."session.suspend-timeout-seconds" = 86400;
}
```

**Note:** `node.pause-on-idle` does not exist in WirePlumber. Setting timeout to 0 may mean "suspend immediately" in some versions. 86400 is safe across all versions.

### Firefox crashes when rapidly switching cameras

Rapidly toggling between USB webcam and IPU6 laptop camera on Google Meet causes Firefox to crash with `mozalloc_abort`. This is a Firefox bug in PipeWire camera portal handling — the device node disappears mid-stream and Firefox hits an internal assertion.

**Crash signature:** `MozCrashReason: Redirecting call to abort() to mozalloc_abort`

**Status:** Upstream Firefox bug. No NixOS-side workaround. Avoid rapidly switching camera devices during active calls.

### HAL init takes ~35 seconds

The icamerasrc HAL takes ~35s to initialize on cold start. The watchdog timer has a 90s grace period on boot to account for this. Do not reduce `OnBootSec` below this.
