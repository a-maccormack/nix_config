{ pkgs, config, ... }:

let
  firmware = pkgs.callPackage ./firmware.nix { };
  hal = pkgs.callPackage ./hal.nix {
    intel-ipu6-camera-bins = firmware;
  };
in
{
  drivers = pkgs.callPackage ./drivers.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
  inherit firmware;
  inherit hal;
  icamerasrc = pkgs.callPackage ./icamerasrc.nix {
    intel-ipu6-camera-hal = hal;
  };
}
