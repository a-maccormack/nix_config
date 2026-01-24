{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "intel-ipu6-camera-bins";
  version = "0.0.0-unstable-2025-05-23";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu6-camera-bins";
    rev = "30e87664829782811a765b0ca9eea3a878a7ff29";
    sha256 = "073yd1s68anhg99aaz12ybvl8kji1hd3jxr08pkni8vpmnwg7wv0";
  };

  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    cp -rL include $out/
    cp -r lib $out/

    # Create symlinks for .so files (needed for linking)
    for lib in $out/lib/*.so.0; do
      ln -sf "$(basename "$lib")" "''${lib%.0}"
    done

    # Create aliased pkg-config files
    cp $out/lib/pkgconfig/ia_imaging-ipu6ep.pc $out/lib/pkgconfig/ia_imaging.pc
    sed -i 's/Name: .*/Name: ia_imaging/' $out/lib/pkgconfig/ia_imaging.pc
    cp $out/lib/pkgconfig/libgcss-ipu6ep.pc $out/lib/pkgconfig/libiacss.pc
    sed -i 's/Name: .*/Name: libiacss/' $out/lib/pkgconfig/libiacss.pc

    # Fix prefix in pkg-config files
    sed -i "s|^prefix=.*|prefix=$out|g" $out/lib/pkgconfig/*.pc
  '';

  meta = with lib; {
    description = "IPU6 firmware";
    homepage = "https://github.com/intel/ipu6-camera-bins";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
