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
    image.fileName = lib.mkForce "nixos-vm-installer.iso";
    isoImage.volumeID = lib.mkForce "NIXOS_VM";

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
      (writeShellScriptBin "install-vm" ''
        set -e

        # Colors for output
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        NC='\033[0m' # No Color

        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   NixOS VM Automated Installer''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""

        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
          echo -e "''${RED}Please run as root (sudo install-vm)''${NC}"
          exit 1
        fi

        # Detect disk (usually /dev/vda or /dev/sda in VMs)
        DISK=""
        if [ -b /dev/vda ]; then
          DISK="/dev/vda"
        elif [ -b /dev/sda ]; then
          DISK="/dev/sda"
        else
          echo -e "''${YELLOW}Available disks:''${NC}"
          lsblk -d -o NAME,SIZE,TYPE | grep disk
          echo ""
          read -p "Enter disk to install to (e.g., /dev/sda): " DISK
        fi

        echo -e "''${YELLOW}WARNING: This will ERASE ALL DATA on $DISK''${NC}"
        read -p "Are you sure? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
          echo "Aborted."
          exit 1
        fi

        echo ""
        echo -e "''${GREEN}[1/6] Partitioning disk...''${NC}"
        # Create GPT partition table with:
        # - 512MB EFI partition
        # - Rest for root
        parted -s "$DISK" -- mklabel gpt
        parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
        parted -s "$DISK" -- set 1 esp on
        parted -s "$DISK" -- mkpart primary 512MiB 100%

        # Determine partition names (handle both /dev/vda1 and /dev/sda1 style)
        if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
          BOOT_PART="''${DISK}p1"
          ROOT_PART="''${DISK}p2"
        else
          BOOT_PART="''${DISK}1"
          ROOT_PART="''${DISK}2"
        fi

        sleep 1  # Wait for partitions to appear

        echo -e "''${GREEN}[2/6] Formatting partitions...''${NC}"
        mkfs.fat -F 32 -n BOOT "$BOOT_PART"
        mkfs.ext4 -L nixos "$ROOT_PART"

        echo -e "''${GREEN}[3/6] Mounting filesystems...''${NC}"
        mount "$ROOT_PART" /mnt
        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot

        echo -e "''${GREEN}[4/6] Cloning NixOS configuration...''${NC}"
        CONFIG_DIR="/mnt/home/mac/Dev/nix_config"
        mkdir -p /mnt/home/mac/Dev
        git clone https://github.com/a-maccormack/nix_config.git "$CONFIG_DIR"

        echo -e "''${GREEN}[5/6] Generating hardware configuration...''${NC}"
        nixos-generate-config --root /mnt --show-hardware-config > "$CONFIG_DIR/hosts/vm/hardware-configuration.nix"
        echo -e "''${YELLOW}Note: hardware-configuration.nix updated but not staged in git''${NC}"

        echo -e "''${GREEN}[6/6] Installing NixOS...''${NC}"
        nixos-install --flake "$CONFIG_DIR#vm" --no-root-passwd

        # Fix ownership after install (will be owned by root otherwise)
        chown -R 1000:100 /mnt/home/mac

        echo ""
        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   Installation Complete!''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Set root password: nixos-enter --root /mnt -c 'passwd root'"
        echo "  2. Set user password: nixos-enter --root /mnt -c 'passwd mac'"
        echo "  3. Reboot: reboot"
        echo ""
      '')

      (writeShellScriptBin "install-vm-interactive" ''
        set -e

        # Colors
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        NC='\033[0m'

        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   NixOS VM Interactive Installer''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""

        if [ "$EUID" -ne 0 ]; then
          echo "Please run as root (sudo install-vm-interactive)"
          exit 1
        fi

        echo "This installer will guide you through:"
        echo "  1. Disk selection and partitioning"
        echo "  2. Optional LUKS encryption"
        echo "  3. NixOS installation with your VM config"
        echo ""

        # Show available disks
        echo -e "''${YELLOW}Available disks:''${NC}"
        lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
        echo ""

        read -p "Enter disk to install to (e.g., vda, sda): " DISK_NAME
        DISK="/dev/$DISK_NAME"

        if [ ! -b "$DISK" ]; then
          echo "Disk $DISK not found!"
          exit 1
        fi

        echo ""
        read -p "Enable LUKS encryption? (y/n): " USE_LUKS

        echo ""
        echo -e "''${YELLOW}WARNING: This will ERASE ALL DATA on $DISK''${NC}"
        read -p "Type 'yes' to continue: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
          echo "Aborted."
          exit 1
        fi

        echo ""
        echo -e "''${GREEN}Partitioning $DISK...''${NC}"
        parted -s "$DISK" -- mklabel gpt
        parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
        parted -s "$DISK" -- set 1 esp on
        parted -s "$DISK" -- mkpart primary 512MiB 100%

        # Partition names
        if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
          BOOT_PART="''${DISK}p1"
          ROOT_PART="''${DISK}p2"
        else
          BOOT_PART="''${DISK}1"
          ROOT_PART="''${DISK}2"
        fi

        sleep 1

        echo -e "''${GREEN}Formatting boot partition...''${NC}"
        mkfs.fat -F 32 -n BOOT "$BOOT_PART"

        if [ "$USE_LUKS" = "y" ] || [ "$USE_LUKS" = "Y" ]; then
          echo -e "''${GREEN}Setting up LUKS encryption...''${NC}"
          cryptsetup luksFormat "$ROOT_PART"
          cryptsetup luksOpen "$ROOT_PART" cryptroot
          mkfs.ext4 -L nixos /dev/mapper/cryptroot
          mount /dev/mapper/cryptroot /mnt
        else
          echo -e "''${GREEN}Formatting root partition...''${NC}"
          mkfs.ext4 -L nixos "$ROOT_PART"
          mount "$ROOT_PART" /mnt
        fi

        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot

        echo -e "''${GREEN}Cloning configuration...''${NC}"
        CONFIG_DIR="/mnt/home/mac/Dev/nix_config"
        mkdir -p /mnt/home/mac/Dev
        git clone https://github.com/a-maccormack/nix_config.git "$CONFIG_DIR"

        echo -e "''${GREEN}Generating hardware configuration...''${NC}"
        nixos-generate-config --root /mnt --show-hardware-config > "$CONFIG_DIR/hosts/vm/hardware-configuration.nix"
        echo -e "''${YELLOW}Note: hardware-configuration.nix updated but not staged in git''${NC}"

        echo -e "''${GREEN}Installing NixOS (this may take a while)...''${NC}"
        nixos-install --flake "$CONFIG_DIR#vm" --no-root-passwd

        # Fix ownership after install (will be owned by root otherwise)
        chown -R 1000:100 /mnt/home/mac

        echo ""
        echo -e "''${GREEN}Setting passwords...''${NC}"
        nixos-enter --root /mnt -c 'passwd root'
        nixos-enter --root /mnt -c 'passwd mac'

        echo ""
        echo -e "''${GREEN}Installation complete! You can now reboot.''${NC}"
      '')
    ];

    # Welcome message
    services.getty.helpLine = lib.mkForce ''

      NixOS VM Installer
      ==================

      Quick install (auto-detects disk):
        sudo install-vm

      Interactive install (with LUKS option):
        sudo install-vm-interactive

      Manual installation:
        1. Partition your disk
        2. Mount to /mnt (and /mnt/boot)
        3. mkdir -p /mnt/home/mac/Dev
        4. git clone https://github.com/a-maccormack/nix_config.git /mnt/home/mac/Dev/nix_config
        5. nixos-generate-config --root /mnt --show-hardware-config > /mnt/home/mac/Dev/nix_config/hosts/vm/hardware-configuration.nix
        6. nixos-install --flake /mnt/home/mac/Dev/nix_config#vm
        7. chown -R 1000:100 /mnt/home/mac

    '';
  };
}
