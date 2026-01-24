{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:

let
  ivsc-driver-src = fetchFromGitHub {
    owner = "intel";
    repo = "ivsc-driver";
    rev = "10f440febe87419d5c82d8fe48580319ea135b54";
    sha256 = "sha256-jc+8geVquRtaZeIOtadCjY9F162Rb05ptE7dk8kuof0=";
  };
in
stdenv.mkDerivation rec {
  pname = "intel-ipu6-drivers";
  version = "0.0.0-unstable-2025-11-12";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu6-drivers";
    rev = "9766e218112f4173be9b0f06dfae27cb40c54f40";
    sha256 = "07k014f604jzsn5dkznkvc2crqz2v68vvqaxsddq50jmdz68qasf";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  patches = [
    "${src}/patches/0001-v6.10-IPU6-headers-used-by-PSYS.patch"
  ];

  postPatch = ''
    cp --no-preserve=mode --recursive --verbose \
      ${ivsc-driver-src}/backport-include \
      ${ivsc-driver-src}/drivers \
      ${ivsc-driver-src}/include \
      .
  '';

  KERNEL_SRC = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";

  buildPhase = ''
    runHook preBuild
    make -C $KERNEL_SRC M=$(pwd) KERNELRELEASE=${kernel.modDirVersion} modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make -C $KERNEL_SRC M=$(pwd) KERNELRELEASE=${kernel.modDirVersion} \
      INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=updates modules_install
    runHook postInstall
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "IPU6 kernel drivers";
    homepage = "https://github.com/intel/ipu6-drivers";
    license = licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
