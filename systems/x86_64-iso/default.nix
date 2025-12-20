{ pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  config = {
    # Flakes support (not in default installer)
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Your preferred tools
    environment.systemPackages = with pkgs; [
      neovim
      git
    ];
  };
}
