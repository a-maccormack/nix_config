{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules for ThinkCentre M910s
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "e1000e" # Intel NIC for initrd networking
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # NVMe encrypted root (manual unlock via SSH)
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/<NVME_LUKS_UUID>";
    preLVM = true;
  };

  # HDD encrypted data volume (auto-unlock via keyfile)
  # The keyfile must be copied into initrd via boot.initrd.secrets
  boot.initrd.luks.devices."cryptdata" = {
    device = "/dev/disk/by-uuid/<HDD_LUKS_UUID>";
    keyFile = "/etc/secrets/data-drive.key";
  };

  # Copy the keyfile into initrd so it's available before root is mounted
  boot.initrd.secrets = {
    "/etc/secrets/data-drive.key" = "/etc/secrets/data-drive.key";
  };

  # Filesystems
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<BOOT_UUID>";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/srv" = {
    device = "/dev/mapper/cryptdata";
    fsType = "ext4";
    options = [ "noatime" ]; # Reduce writes for HDD
  };

  # No swap
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
