# Bluetooth — X1 Carbon Gen 10

## Hardware

- Intel AX211 Bluetooth adapter (btusb driver)
- Tested with: Bose QC45

## Known Issues

### BT adapter auto-suspend drops connections

The Linux kernel enables USB autosuspend by default for btusb (~2s timeout). The adapter suspends, dropping active connections, then wakes and reconnects in a loop.

**Fix:** Disable btusb autosuspend via kernel module parameter:

```nix
boot.extraModprobeConfig = ''
  options btusb enable_autosuspend=n
'';
```

**Verify:** `cat /sys/module/btusb/parameters/enable_autosuspend` → `N`

### WirePlumber suspends BT audio sinks too aggressively

WirePlumber's default suspend timeout can cause BT audio nodes to be suspended during brief pauses (e.g. switching tabs), dropping the A2DP transport.

**Fix:** WirePlumber rule with 60s suspend timeout for BT output nodes:

```nix
services.pipewire.wireplumber.extraConfig."50-bluez-rules" = {
  "monitor.bluez.rules" = [{
    matches = [{ "node.name" = "~bluez_output.*"; }];
    actions.update-props."session.suspend-timeout-seconds" = 60;
  }];
};
```

### bluez main.conf section placement

`ReconnectAttempts` and `ReconnectIntervals` belong under `[Policy]`, not `[General]`. Placing them under `[General]` produces `Unknown key` warnings and the settings are ignored. bluez 5.84 valid sections:

```ini
[General]
FastConnectable=true

[Policy]
ReconnectAttempts=7
ReconnectIntervals=1,2,4,8,16,32,64
```
