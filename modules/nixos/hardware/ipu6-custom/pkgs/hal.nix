{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libdrm, expat, intel-ipu6-camera-bins }:

stdenv.mkDerivation rec {
  pname = "intel-ipu6-camera-hal";
  version = "0.0.0-unstable-2025-06-27";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu6-camera-hal";
    rev = "c933525a6efe8229a7129b7b0b66798f19d2bef7";
    sha256 = "00whfzpr7af9fndg3861zjfyh3ygwsd3g801sdkl16cisz72qv35";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libdrm expat intel-ipu6-camera-bins ];

  PKG_CONFIG_PATH = "${intel-ipu6-camera-bins}/lib/pkgconfig";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DIPU_VERSIONS=ipu6ep"
    "-DUSE_PG_LITE_PIPE=ON"
    "-DBUILD_CAMHAL_ADAPTOR=ON"
    "-DBUILD_CAMHAL_PLUGIN=ON"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];

  env = {
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-error"
      "-I${intel-ipu6-camera-bins}/include/ipu6ep"
      "-I${intel-ipu6-camera-bins}/include/ipu6ep/ia_imaging"
      "-I${intel-ipu6-camera-bins}/include/ipu6ep/ia_camera"
    ];
    NIX_LDFLAGS = toString [
      "-L${intel-ipu6-camera-bins}/lib"
    ];
  };

  postInstall = ''
    mkdir -p $out/include/libcamhal
    cp -r $src/include/* $out/include/libcamhal/
  '';

  meta = with lib; {
    description = "IPU6 Camera HAL";
    homepage = "https://github.com/intel/ipu6-camera-hal";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
