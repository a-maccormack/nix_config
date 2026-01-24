<p align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="120" alt="Nix Logo"/>
</p>

<h1 align="center">Nix Flakes Configuration</h1>

<p align="center">
  <em>A modular, reproducible NixOS setup with Flakes and Home-Manager</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NixOS-25.11-5277C3?style=flat-square&logo=nixos&logoColor=white" alt="NixOS"/>
  <img src="https://img.shields.io/badge/Flakes-Enabled-informational?style=flat-square&logo=snowflake&logoColor=white" alt="Flakes"/>
  <img src="https://img.shields.io/badge/Home--Manager-Integrated-yellow?style=flat-square" alt="Home-Manager"/>
  <img src="https://img.shields.io/badge/Hyprland-Wayland-blueviolet?style=flat-square" alt="Hyprland"/>
  <img src="https://img.shields.io/badge/Arch-x86__64-orange?style=flat-square" alt="x86_64"/>
</p>

---

## Devices

| Host | Type | CPU | Storage | Key Features |
|------|------|-----|---------|--------------|
| `x1-carbon-g10` | ThinkPad Laptop | Intel 12th Gen (Alder Lake) | LUKS Encrypted | IPU6 Camera, Tailscale VPN, Bluetooth, Thunderbolt 3 |
| `vm` | Virtual Machine | QEMU/KVM | ext4 | Docker, Testing Environment |
| `x86_64-iso` | Install Media | Generic | Live | Minimal bootable ISO with Flakes |

---

## Directory Structure

```
nix_config/
├── flake.nix                 # Flake definition & inputs
├── flake.lock                # Reproducible dependency lock
│
├── hosts/                    # Per-machine configurations
│   ├── vm/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── x1-carbon-g10/
│       ├── configuration.nix
│       └── hardware-configuration.nix
│
├── modules/
│   ├── nixos/                # System-level modules
│   │   ├── desktop/          # Hyprland, Ly, SDDM, 1Password
│   │   ├── hardware/         # IPU6 camera stack
│   │   ├── system/           # Boot, Nix settings, GC
│   │   └── virtualisation/   # Docker, Tailscale
│   │
│   ├── home/                 # Home-Manager modules
│   │   ├── apps/             # Firefox, Neovim
│   │   ├── desktop/          # Waybar, Fuzzel, Hypridle
│   │   └── shell/            # Zsh, Tmux, Bash
│   │
│   └── shared/               # Cross-platform packages
│       ├── apps/             # GUI applications
│       └── cli-tools/        # 35+ CLI utilities
│
├── systems/
│   └── x86_64-iso/           # Bootable ISO builder
│
├── lib/                      # Helper functions
│   └── default.nix           # mkOpt, enabled, disabled
│
└── assets/
    └── wallpapers/
```

---

## Features

### Desktop Environment
| Component | Tool | Description |
|-----------|------|-------------|
| Window Manager | Hyprland | Dynamic tiling Wayland compositor |
| Status Bar | Waybar | Customizable top panel |
| App Launcher | Fuzzel | Fast Wayland-native launcher |
| Terminal | Kitty | GPU-accelerated terminal |
| Login Manager | Ly | Minimal TUI display manager |
| Notifications | SwayNC | Notification center |
| Idle Manager | Hypridle | Auto-lock & screen timeout |
| Screen Lock | Hyprlock | Secure Wayland lock screen |

### Development Tools
```
Languages     │ Node.js, Python (uv/pyenv), Erlang/Elixir (asdf)
Containers    │ Docker
IaC           │ Terraform, Ansible
Cloud         │ AWS CLI, Google Cloud SDK
Version Ctrl  │ Git (SSH signing), GitHub CLI
AI            │ Claude CLI, Gemini CLI
Editors       │ Neovim, Vim, VS Code
API Testing   │ Postman, Ngrok
Databases     │ Antares SQL Client
```

### Security Tools
| Tool | Purpose |
|------|---------|
| 1Password | Password & secrets management |
| Burp Suite | Web app security testing |
| FFUF | Web fuzzing |
| Nuclei | Vulnerability scanning |
| Nmap | Network discovery |
| SecLists | Wordlists & payloads |

### Productivity
- **Office**: LibreOffice (Writer, Calc, Impress)
- **Notes**: Obsidian
- **Documents**: Evince PDF Viewer
- **Cloud Storage**: Dropbox
- **Media**: VLC, Shotcut, Spotify
- **Communication**: Slack, Telegram

### Hardware Support
- **Camera**: Custom Intel IPU6 stack with v4l2-relayd (ipu6ep platform)
- **Bluetooth**: Full support with Blueman GUI
- **Display**: HiDPI scaling (1.5x @ 2880x1800)
- **Keyboard**: Dual layouts (US-intl/Spanish) with Super+I toggle

---

## Quick Start

### Validate Configuration
```bash
nix flake check --impure
```

### Deploy to a Host
```bash
# Replace <hostname> with: vm, x1-carbon-g10
sudo nixos-rebuild switch --flake .#<hostname>
```

### Build Installation ISO
```bash
nix build .#iso

# Result in: ./result/iso/
```

### Update Flake Inputs
```bash
nix flake update
```

### Garbage Collection
```bash
# Clean old generations (auto-enabled, but manual)
sudo nix-collect-garbage -d
```

### Format Nix Files
```bash
nix run .#formatter.x86_64-linux -- **/*.nix
```

---

## Module System

This config uses an **auto-discovery pattern** for modules. Simply create a new directory with a `default.nix` and it's automatically imported.

### Preset Pattern
```nix
# modules/nixos/<category>/<name>/default.nix
{ lib, config, ... }:
{
  options.presets.<category>.<name>.enable =
    lib.mkEnableOption "Description";

  config = lib.mkIf config.presets.<category>.<name>.enable {
    # Your configuration here
  };
}
```

### Enable in Host Config
```nix
# hosts/<hostname>/configuration.nix
{
  presets.desktop.hyprland.enable = true;
  presets.virtualisation.docker.enable = true;
  presets.shared.cli-tools.enable = true;
}
```

### Available Preset Categories

| Category | Scope | Examples |
|----------|-------|----------|
| `presets.system.*` | NixOS | boot, nix/flakes, nix/gc |
| `presets.desktop.*` | NixOS | hyprland, ly, 1password |
| `presets.virtualisation.*` | NixOS | docker, tailscale |
| `presets.hardware.*` | NixOS | ipu6-custom |
| `presets.home.shell.*` | Home-Manager | zsh, tmux, bash |
| `presets.home.apps.*` | Home-Manager | firefox, neovim |
| `presets.home.desktop.*` | Home-Manager | waybar, fuzzel, hypridle |
| `presets.shared.*` | Both | cli-tools, apps/* |

---

## Adding a New Host

```bash
# 1. Create host directory
mkdir -p hosts/<hostname>

# 2. Generate hardware config
sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix

# 3. Create configuration.nix (copy from existing host and modify)
cp hosts/vm/configuration.nix hosts/<hostname>/configuration.nix

# 4. Add to flake.nix nixosConfigurations
```

---

## Keybindings (Hyprland)

| Key | Action |
|-----|--------|
| `Super + Return` | Open terminal (Kitty) |
| `Super + D` | App launcher (Fuzzel) |
| `Super + Q` | Close window |
| `Super + H/J/K/L` | Focus window (vim-style) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + I` | Toggle keyboard layout |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |

---

## License

This configuration is provided as-is for personal use and reference.
