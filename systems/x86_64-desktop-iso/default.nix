{
  pkgs,
  modulesPath,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  config = {
    # Custom ISO label
    image.fileName = lib.mkForce "nixos-desktop-installer.iso";
    isoImage.volumeID = lib.mkForce "NIXOS_DESKTOP";

    # Flakes support
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Tools needed for installation
    environment.systemPackages = with pkgs; [
      neovim
      git
      parted
      gptfdisk
      cryptsetup
      dosfstools
      e2fsprogs
      (writeShellScriptBin "install-desktop" ''
        set -e

        # Colors for output
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color

        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   NixOS Desktop Installer''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""
        echo "This installer will set up:"
        echo "  - NVMe drive with LUKS encryption"
        echo "  - EFI boot partition"
        echo "  - Full desktop environment (Hyprland + NVIDIA)"
        echo ""

        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
          echo -e "''${RED}Please run as root (sudo install-desktop)''${NC}"
          exit 1
        fi

        # Detect NVMe drive
        DISK=""
        if [ -b /dev/nvme0n1 ]; then
          DISK="/dev/nvme0n1"
        fi

        echo -e "''${CYAN}Detected drives:''${NC}"
        lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
        echo ""

        if [ -z "$DISK" ]; then
          read -p "Enter target drive (e.g., /dev/nvme0n1): " DISK
        else
          echo -e "NVMe: ''${GREEN}$DISK''${NC}"
          read -p "Use this drive? (y/n): " CONFIRM_DISK
          if [ "$CONFIRM_DISK" != "y" ]; then
            read -p "Enter target drive: " DISK
          fi
        fi

        # Validate device exists
        if [ ! -b "$DISK" ]; then
          echo -e "''${RED}Device $DISK not found!''${NC}"
          exit 1
        fi

        echo ""
        echo -e "''${YELLOW}WARNING: This will ERASE ALL DATA on $DISK''${NC}"
        read -p "Type 'yes' to continue: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
          echo "Aborted."
          exit 1
        fi

        # Determine partition names
        if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
          BOOT_PART="''${DISK}p1"
          ROOT_PART="''${DISK}p2"
        else
          BOOT_PART="''${DISK}1"
          ROOT_PART="''${DISK}2"
        fi

        echo ""
        echo -e "''${GREEN}[1/7] Partitioning $DISK...''${NC}"
        parted -s "$DISK" -- mklabel gpt
        parted -s "$DISK" -- mkpart ESP fat32 1MiB 1GiB
        parted -s "$DISK" -- set 1 esp on
        parted -s "$DISK" -- mkpart primary 1GiB 100%

        sleep 2  # Wait for partitions to appear

        echo -e "''${GREEN}[2/7] Setting up LUKS encryption...''${NC}"
        echo -e "''${YELLOW}You will be prompted to enter a passphrase.''${NC}"
        cryptsetup luksFormat --type luks2 "$ROOT_PART"

        echo ""
        echo -e "''${GREEN}[3/7] Opening LUKS container...''${NC}"
        cryptsetup open "$ROOT_PART" cryptroot

        echo -e "''${GREEN}[4/7] Formatting and mounting...''${NC}"
        mkfs.fat -F 32 -n BOOT "$BOOT_PART"
        mkfs.ext4 -L nixos /dev/mapper/cryptroot

        mount /dev/mapper/cryptroot /mnt
        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot

        echo -e "''${GREEN}[5/7] Cloning NixOS configuration...''${NC}"
        CONFIG_DIR="/mnt/home/mac/Dev/nix_config"
        mkdir -p /mnt/home/mac/Dev
        git clone https://github.com/a-maccormack/nix_config.git "$CONFIG_DIR"

        echo -e "''${GREEN}[6/7] Auto-detecting hardware configuration...''${NC}"
        mkdir -p "$CONFIG_DIR/hosts/workstation"
        nixos-generate-config --root /mnt --show-hardware-config > "$CONFIG_DIR/hosts/workstation/hardware-configuration.nix"
        echo -e "''${CYAN}Hardware configuration written (commit this back to your repo after install).''${NC}"

        echo ""
        echo -e "''${GREEN}[7/7] Installing NixOS (this may take a while)...''${NC}"
        nixos-install --flake "$CONFIG_DIR#workstation" --no-root-passwd

        # Fix ownership
        chown -R 1000:100 /mnt/home/mac

        echo ""
        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   Installation Complete!''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""

        echo -e "''${GREEN}Setting passwords...''${NC}"
        nixos-enter --root /mnt -c 'passwd root'
        nixos-enter --root /mnt -c 'passwd mac'

        echo ""
        echo -e "''${YELLOW}Next steps:''${NC}"
        echo "  1. Reboot into your new system"
        echo "  2. Set up Tailscale: sudo tailscale up --ssh"
        echo "  3. Commit the generated hardware-configuration.nix back to git"
        echo ""
      '')
    ];

    # Welcome message
    services.getty.helpLine = lib.mkForce ''

      NixOS Desktop Installer
      =======================

      Automated install (recommended):
        sudo install-desktop

      This will:
        - Partition and LUKS-encrypt your NVMe drive
        - Auto-detect hardware configuration
        - Install NixOS with the workstation desktop config

      Manual installation:
        1. Partition your disk (1GiB EFI + rest for root)
        2. cryptsetup luksFormat --type luks2 /dev/<root-partition>
        3. cryptsetup open /dev/<root-partition> cryptroot
        4. mkfs.fat -F 32 /dev/<boot-partition> && mkfs.ext4 /dev/mapper/cryptroot
        5. mount /dev/mapper/cryptroot /mnt && mkdir -p /mnt/boot && mount /dev/<boot-partition> /mnt/boot
        6. git clone https://github.com/a-maccormack/nix_config.git /mnt/home/mac/Dev/nix_config
        7. nixos-generate-config --root /mnt --show-hardware-config > /mnt/home/mac/Dev/nix_config/hosts/workstation/hardware-configuration.nix
        8. nixos-install --flake /mnt/home/mac/Dev/nix_config#workstation

    '';
  };
}
