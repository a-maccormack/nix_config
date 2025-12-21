{ lib, stdenv, fetchFromGitHub, pkg-config, autoreconfHook, gst_all_1, intel-ipu6-camera-hal, libdrm, libva }:

stdenv.mkDerivation rec {
  pname = "icamerasrc-ipu6ep";
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
    gst_all_1.gst-plugins-bad
    intel-ipu6-camera-hal
    libdrm
    libva
  ];

  # https://github.com/intel/ipu6-camera-hal/issues/1
  # https://github.com/intel/icamerasrc/issues/22
  preConfigure = ''
    export CHROME_SLIM_CAMHAL=ON
    export STRIP_VIRTUAL_CHANNEL_CAMHAL=ON
  '';

  NIX_CFLAGS_COMPILE = [
    "-Wno-error"
    "-I${gst_all_1.gst-plugins-base.dev}/include/gstreamer-1.0"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "GStreamer src plugin for IPU6EP";
    homepage = "https://github.com/intel/icamerasrc";
    license = licenses.lgpl21Plus;
    platforms = [ "x86_64-linux" ];
  };
}
