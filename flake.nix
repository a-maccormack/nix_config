{
  description = "NixOS multi-system setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix = {
      url = "github:NixOS/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , unstable
    , nix
    , nix-index-database
    , nixos-generators
    , home-manager
    , ...

    }@inputs:
    let
      lib = nixpkgs.lib.extend (
        self: super: {
          my = import ./lib { lib = self; };
        }
      );
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      nixosConfigurations = {
        "vm" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit lib;
          };

          modules = [
            ./hosts/vm/configuration.nix
            nix-index-database.nixosModules.nix-index
          ];
        };

        "x1-carbon-g10" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit lib;
          };

          modules = [
            ./hosts/x1-carbon-g10/configuration.nix
            nix-index-database.nixosModules.nix-index
          ];
        };

        "homelab" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit lib;
          };

          modules = [
            ./hosts/homelab/configuration.nix
            nix-index-database.nixosModules.nix-index
          ];
        };
      };

      packages = forEachSupportedSystem
        (
          { pkgs }:
          {
            wallpapers = pkgs.stdenv.mkDerivation {
              name = "wallpapers";
              src = ./assets/wallpapers;
              installPhase = ''
                mkdir -p $out/
                cp -Rf ./ $out/
              '';
            };

            iso = nixos-generators.nixosGenerate {
              specialArgs = {
                inherit inputs;
                inherit lib;
              };
              system = "x86_64-linux";
              format = "iso";
              modules = [
                ./systems/x86_64-iso
              ];
            };

            vm-iso = nixos-generators.nixosGenerate {
              specialArgs = {
                inherit inputs;
                inherit lib;
              };
              system = "x86_64-linux";
              format = "iso";
              modules = [
                ./systems/x86_64-vm-iso
              ];
            };

            homelab-iso = nixos-generators.nixosGenerate {
              specialArgs = {
                inherit inputs;
                inherit lib;
              };
              system = "x86_64-linux";
              format = "iso";
              modules = [
                ./systems/x86_64-homelab-iso
              ];
            };
          }
        );
    };
}
