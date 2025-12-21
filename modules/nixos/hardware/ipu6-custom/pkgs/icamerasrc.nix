{ lib, stdenv, fetchFromGitHub, pkg-config, autoreconfHook, gst_all_1, intel-ipu6-camera-hal }:

stdenv.mkDerivation rec {
  pname = "icamerasrc";
  version = "2024-09-26";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "icamerasrc";
    rev = "refs/tags/20240926_1446";
    sha256 = "sha256-BpIZxkPmSVKqPntwBJjGmCaMSYFCEZHJa4soaMAJRWE=";
  };

  nativeBuildInputs = [ pkg-config autoreconfHook ];
  buildInputs = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    intel-ipu6-camera-hal
  ];

  # Allow finding the HAL headers
  env.NIX_CFLAGS_COMPILE = "-I${intel-ipu6-camera-hal}/include/libcamhal";

  meta = with lib; {
    description = "GStreamer src plugin for IPU6";
    homepage = "https://github.com/intel/icamerasrc";
    license = licenses.lgpl21;
    platforms = [ "x86_64-linux" ];
  };
}
