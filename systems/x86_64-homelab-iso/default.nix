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
    image.fileName = lib.mkForce "nixos-homelab-installer.iso";
    isoImage.volumeID = lib.mkForce "NIXOS_HOMELAB";

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
      (writeShellScriptBin "install-homelab" ''
        set -e

        # Colors for output
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color

        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   NixOS Homelab Server Installer''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        echo ""
        echo "This installer will set up:"
        echo "  - NVMe drive with LUKS encryption (OS)"
        echo "  - HDD with LUKS encryption (Data)"
        echo "  - initrd SSH for remote LUKS unlock"
        echo "  - HDD auto-unlock via keyfile"
        echo ""

        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
          echo -e "''${RED}Please run as root (sudo install-homelab)''${NC}"
          exit 1
        fi

        # Detect drives
        NVME=""
        HDD=""

        if [ -b /dev/nvme0n1 ]; then
          NVME="/dev/nvme0n1"
        fi

        # Find first non-NVMe disk (likely the HDD)
        for disk in /dev/sda /dev/sdb /dev/vda; do
          if [ -b "$disk" ]; then
            HDD="$disk"
            break
          fi
        done

        echo -e "''${CYAN}Detected drives:''${NC}"
        lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
        echo ""

        if [ -z "$NVME" ]; then
          read -p "Enter NVMe device (e.g., /dev/nvme0n1): " NVME
        else
          echo -e "NVMe: ''${GREEN}$NVME''${NC}"
          read -p "Use this NVMe? (y/n): " CONFIRM_NVME
          if [ "$CONFIRM_NVME" != "y" ]; then
            read -p "Enter NVMe device: " NVME
          fi
        fi

        if [ -z "$HDD" ]; then
          read -p "Enter HDD device (e.g., /dev/sda): " HDD
        else
          echo -e "HDD: ''${GREEN}$HDD''${NC}"
          read -p "Use this HDD? (y/n): " CONFIRM_HDD
          if [ "$CONFIRM_HDD" != "y" ]; then
            read -p "Enter HDD device: " HDD
          fi
        fi

        # Validate devices exist
        if [ ! -b "$NVME" ]; then
          echo -e "''${RED}NVMe device $NVME not found!''${NC}"
          exit 1
        fi
        if [ ! -b "$HDD" ]; then
          echo -e "''${RED}HDD device $HDD not found!''${NC}"
          exit 1
        fi

        echo ""
        echo -e "''${YELLOW}WARNING: This will ERASE ALL DATA on:''${NC}"
        echo -e "  - $NVME (NVMe - will contain OS)"
        echo -e "  - $HDD (HDD - will contain data)"
        echo ""
        read -p "Type 'yes' to continue: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
          echo "Aborted."
          exit 1
        fi

        # Determine partition names
        if [[ "$NVME" == *"nvme"* ]]; then
          NVME_BOOT="''${NVME}p1"
          NVME_ROOT="''${NVME}p2"
        else
          NVME_BOOT="''${NVME}1"
          NVME_ROOT="''${NVME}2"
        fi
        HDD_DATA="''${HDD}1"

        echo ""
        echo -e "''${GREEN}[1/12] Partitioning NVMe ($NVME)...''${NC}"
        parted -s "$NVME" -- mklabel gpt
        parted -s "$NVME" -- mkpart ESP fat32 1MiB 1GiB
        parted -s "$NVME" -- set 1 esp on
        parted -s "$NVME" -- mkpart primary 1GiB 100%

        echo -e "''${GREEN}[2/12] Partitioning HDD ($HDD)...''${NC}"
        parted -s "$HDD" -- mklabel gpt
        parted -s "$HDD" -- mkpart primary 1MiB 100%

        sleep 2  # Wait for partitions to appear

        echo -e "''${GREEN}[3/12] Formatting boot partition...''${NC}"
        mkfs.fat -F 32 -n BOOT "$NVME_BOOT"

        echo ""
        echo -e "''${GREEN}[4/12] Setting up LUKS encryption on NVMe...''${NC}"
        echo -e "''${YELLOW}You will be prompted to enter a passphrase.''${NC}"
        echo -e "''${YELLOW}Remember this passphrase - you'll need it for remote unlock!''${NC}"
        cryptsetup luksFormat --type luks2 "$NVME_ROOT"

        echo ""
        echo -e "''${GREEN}[5/12] Setting up LUKS encryption on HDD...''${NC}"
        echo -e "''${YELLOW}Use the SAME passphrase as the NVMe.''${NC}"
        cryptsetup luksFormat --type luks2 "$HDD_DATA"

        echo -e "''${GREEN}[6/12] Opening LUKS containers...''${NC}"
        echo "Opening NVMe..."
        cryptsetup open "$NVME_ROOT" cryptroot
        echo "Opening HDD..."
        cryptsetup open "$HDD_DATA" cryptdata

        echo -e "''${GREEN}[7/12] Formatting encrypted volumes...''${NC}"
        mkfs.ext4 -L nixos /dev/mapper/cryptroot
        mkfs.ext4 -L data /dev/mapper/cryptdata

        echo -e "''${GREEN}[8/12] Mounting filesystems...''${NC}"
        mount /dev/mapper/cryptroot /mnt
        mkdir -p /mnt/boot /mnt/srv
        mount "$NVME_BOOT" /mnt/boot
        mount /dev/mapper/cryptdata /mnt/srv

        echo -e "''${GREEN}[9/12] Creating HDD keyfile and adding to LUKS...''${NC}"
        mkdir -p /mnt/etc/secrets
        dd if=/dev/urandom of=/mnt/etc/secrets/data-drive.key bs=4096 count=1 2>/dev/null
        chmod 400 /mnt/etc/secrets/data-drive.key
        cryptsetup luksAddKey "$HDD_DATA" /mnt/etc/secrets/data-drive.key

        echo ""
        echo -e "''${GREEN}[10/12] Adding passphrase backup to HDD...''${NC}"
        echo -e "''${YELLOW}Enter the SAME passphrase again (this is a backup in case NVMe fails).''${NC}"
        cryptsetup luksAddKey "$HDD_DATA"

        echo -e "''${GREEN}[11/12] Generating initrd SSH host key...''${NC}"
        mkdir -p /mnt/etc/secrets/initrd
        ssh-keygen -t ed25519 -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key -N ""
        echo ""
        echo -e "''${CYAN}initrd SSH host key fingerprint (save this!):''${NC}"
        ssh-keygen -lf /mnt/etc/secrets/initrd/ssh_host_ed25519_key.pub

        echo ""
        echo -e "''${GREEN}[12/12] Cloning NixOS configuration...''${NC}"
        CONFIG_DIR="/mnt/home/mac/Dev/nix_config"
        mkdir -p /mnt/home/mac/Dev
        git clone https://github.com/a-maccormack/nix_config.git "$CONFIG_DIR"

        # Get UUIDs
        BOOT_UUID=$(blkid -s UUID -o value "$NVME_BOOT")
        NVME_LUKS_UUID=$(blkid -s UUID -o value "$NVME_ROOT")
        HDD_LUKS_UUID=$(blkid -s UUID -o value "$HDD_DATA")

        echo ""
        echo -e "''${CYAN}Detected UUIDs:''${NC}"
        echo "  Boot:      $BOOT_UUID"
        echo "  NVMe LUKS: $NVME_LUKS_UUID"
        echo "  HDD LUKS:  $HDD_LUKS_UUID"

        # Update hardware-configuration.nix with actual UUIDs
        HWCONFIG="$CONFIG_DIR/hosts/homelab/hardware-configuration.nix"
        sed -i "s|<BOOT_UUID>|$BOOT_UUID|g" "$HWCONFIG"
        sed -i "s|<NVME_LUKS_UUID>|$NVME_LUKS_UUID|g" "$HWCONFIG"
        sed -i "s|<HDD_LUKS_UUID>|$HDD_LUKS_UUID|g" "$HWCONFIG"

        echo ""
        echo -e "''${GREEN}Installing NixOS (this may take a while)...''${NC}"
        nixos-install --flake "$CONFIG_DIR#homelab" --no-root-passwd

        echo -e "''${GREEN}Creating media directories on HDD...''${NC}"
        mkdir -p /mnt/srv/{media/{tv,movies,music},downloads,config}
        chown -R 1000:100 /mnt/srv

        echo -e "''${GREEN}Setting up Docker Compose...''${NC}"
        # Repo already cloned to $CONFIG_DIR (/mnt/home/mac/Dev/nix_config)
        # Symlink docker-compose directory for easy access
        ln -s /home/mac/Dev/nix_config/hosts/homelab/docker-compose /mnt/home/mac/docker-compose
        # Create .env from example (gitignored, so needs to be a real file)
        cp "$CONFIG_DIR/hosts/homelab/docker-compose/.env.example" "$CONFIG_DIR/hosts/homelab/docker-compose/.env"

        # Fix ownership
        chown -R 1000:100 /mnt/home/mac

        echo ""
        echo -e "''${GREEN}============================================''${NC}"
        echo -e "''${GREEN}   Installation Complete!''${NC}"
        echo -e "''${GREEN}============================================''${NC}"
        # Get current IP address
        LOCAL_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)

        echo ""
        echo -e "''${CYAN}Important information to save:''${NC}"
        echo ""
        echo -e "''${GREEN}Current IP address: $LOCAL_IP''${NC}"
        echo ""
        echo "initrd SSH host key fingerprint:"
        ssh-keygen -lf /mnt/etc/secrets/initrd/ssh_host_ed25519_key.pub
        echo ""
        echo "UUIDs (already written to config):"
        echo "  Boot:      $BOOT_UUID"
        echo "  NVMe LUKS: $NVME_LUKS_UUID"
        echo "  HDD LUKS:  $HDD_LUKS_UUID"
        echo ""
        echo ""
        echo -e "''${GREEN}Setting passwords...''${NC}"
        nixos-enter --root /mnt -c 'passwd root'
        nixos-enter --root /mnt -c 'passwd mac'

        echo -e "''${YELLOW}Next steps:''${NC}"
        echo "  1. Reboot and SSH to port 2222 to unlock LUKS:"
        echo -e "     ''${CYAN}ssh -p 2222 -i ~/.ssh/homelab_unlock root@$LOCAL_IP''${NC}"
        echo "  2. After unlock, SSH to the server:"
        echo -e "     ''${CYAN}ssh -i ~/.ssh/homelab mac@$LOCAL_IP''${NC}"
        echo "  3. Set up Tailscale: sudo tailscale up --ssh"
        echo "  4. Edit .env if needed: nano ~/docker-compose/.env"
        echo ""
        echo -e "''${YELLOW}Post-install backup (highly recommended):''${NC}"
        echo "  cryptsetup luksHeaderBackup $NVME_ROOT --header-backup-file ~/nvme-header.img"
        echo "  cryptsetup luksHeaderBackup $HDD_DATA --header-backup-file ~/hdd-header.img"
        echo ""
      '')
    ];

    # Welcome message
    services.getty.helpLine = lib.mkForce ''

      NixOS Homelab Server Installer
      ==============================

      Automated install (recommended):
        sudo install-homelab

      This will:
        - Set up LUKS encryption on NVMe (OS) and HDD (data)
        - Configure HDD auto-unlock via keyfile
        - Generate initrd SSH host key for remote unlock
        - Install NixOS with your homelab configuration

      Manual installation: See the plan at
        https://github.com/a-maccormack/nix_config

    '';
  };
}
