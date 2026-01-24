{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.virtualisation.qemu.enable = mkEnableOption "QEMU/KVM with virt-manager";

  config = mkIf config.presets.virtualisation.qemu.enable {
    # Enable libvirtd daemon
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true; # TPM emulation
      };
    };

    # Spice USB redirection
    virtualisation.spiceUSBRedirection.enable = true;

    # virt-manager GUI
    programs.virt-manager.enable = true;

    # Add user to libvirtd group
    users.users.mac.extraGroups = [ "libvirtd" ];

    # Useful packages
    environment.systemPackages = with pkgs; [
      spice-gtk # Spice client with clipboard sharing
      virt-viewer # Alternative VM viewer
    ];
  };
}
