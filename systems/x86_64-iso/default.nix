{ pkgs, ... }:
{
  imports = [ ];

  config = {
    system.stateVersion = "25.11";

    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

    };

    systemd.network.enable = true;

    networking = {
      useDHCP = true;
      useNetworkd = true;
      hostName = "nixos";
    };

    environment.systemPackages = with pkgs; [
      neovim
      git
    ];
  };
}
