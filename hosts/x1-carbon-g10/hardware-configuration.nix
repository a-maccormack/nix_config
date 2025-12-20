# PLACEHOLDER - Regenerate on actual hardware with: nixos-generate-config --root /mnt
# This file will be replaced with the actual hardware configuration
# after running the installer on the ThinkPad X1 Carbon Gen 10.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot - will be updated by nixos-generate-config
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # LUKS encryption - update device UUID after partitioning
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-UPDATE-THIS-UUID";
  };

  # Filesystems - update UUIDs after partitioning
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-UPDATE-THIS-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-UPDATE-THIS-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  # Intel CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
