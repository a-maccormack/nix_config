{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    system.stateVersion = "25.11";

    # Networking
    networking = {
      hostName = "x1-carbon-g10";
      networkmanager.enable = true;
      firewall.enable = true;
    };

    # Bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.bluetooth.settings = {
      General = {
        FastConnectable = true;
      };
      Policy = {
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };

    # Disable btusb autosuspend to prevent BT adapter from sleeping mid-connection
    boot.extraModprobeConfig = ''
      options btusb enable_autosuspend=n
    '';

    # IPU6 - native module with HAL linkage fix
    hardware.ipu6-overlay.enable = true; # Fix icamerasrc-ipu6ep HAL linkage
    hardware.ipu6 = {
      enable = true;
      platform = "ipu6ep"; # Alder Lake (12th gen)
    };
    hardware.ipu6-custom.enable = false;
    services.blueman.enable = true;

    # Prevent aggressive BT audio sink suspension
    services.pipewire.wireplumber.extraConfig."50-bluez-rules" = {
      "monitor.bluez.rules" = [
        {
          matches = [ { "node.name" = "~bluez_output.*"; } ];
          actions.update-props."session.suspend-timeout-seconds" = 60;
        }
      ];
    };

    # Prevent WirePlumber from auto-switching BT headphones to HSP/HFP
    # when an app requests a microphone (keeps A2DP for high-quality audio)
    services.pipewire.wireplumber.extraConfig."51-bluez-no-autoswitch" = {
      "monitor.bluez.rules" = [
        {
          matches = [ { "device.name" = "~bluez_card.*"; } ];
          actions.update-props."bluez5.autoswitch-profile" = false;
        }
      ];
    };
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    # Localization
    time.timeZone = "America/Santiago";
    i18n.defaultLocale = "en_US.UTF-8";

    # User account
    users.users.mac = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "adbusers"
      ];
      shell = pkgs.zsh;
    };

    # Enable zsh system-wide
    programs.adb.enable = true;
    programs.zsh.enable = true;

    # Enable presets
    presets.system.bash.binbash = true;
    presets.system.boot.enable = true;
    presets.system.nix.flakes.enable = true;
    presets.system.nix.gc.enable = true;
    presets.desktop.ly.enable = true;
    presets.desktop.hyprland.enable = true;
    presets.desktop._1password.enable = true;
    presets.desktop.fingerprint.enable = true;
    presets.virtualisation.docker.enable = true;
    presets.virtualisation.tailscale.enable = true;
    presets.virtualisation.qemu.enable = true;

    # Enable nix-ld for running unpatched binaries (e.g. uv python)
    programs.nix-ld.enable = true;
    environment.localBinInPath = true;

    # Home-manager
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.mac =
        { pkgs, ... }:
        {
          imports = [
            ../../modules/home/import.nix
            ../../modules/shared/import.nix
          ];

          home.stateVersion = "25.11";

          # Enable home presets
          presets.home.apps.firefox.enable = true;
          presets.home.apps.neovim.enable = true;
          presets.home.shell.zsh.enable = true;
          presets.home.shell.tmux.enable = true;
          presets.home.desktop.hyprland.enable = true;
          presets.home.desktop.hypridle.fingerprint = true;
          presets.home.desktop.blueman.enable = true;

          # Enable shared CLI tools
          presets.shared.cli-tools.enable = true;
          presets.shared.cli-tools.rust.enableCrossAarch64 = true;

          # Enable shared apps
          presets.shared.apps.enable = true;

          # python3 wrapper using uv
          home.packages = [
            (pkgs.writeShellScriptBin "python3" ''
              exec uv run python3 "$@"
            '')
          ];
        };
    };
  };
}
