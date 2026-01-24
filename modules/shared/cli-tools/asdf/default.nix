{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  # Build dependencies for erlang compilation
  erlangBuildInputs = with pkgs; [
    gnumake
    gcc
    autoconf
    openssl
    ncurses
    libxslt
    fop
    libxml2
    # OpenGL/wx support
    libGL
    libGLU
    libglvnd
    wxGTK32
    # ODBC support
    unixODBC
    # Java/jinterface support
    jdk
  ];

  # Library paths for erlang build
  libraryPath = lib.makeLibraryPath erlangBuildInputs;

  # Erlang/kerl environment setup - exported directly in shell init
  erlangEnv = with pkgs; ''
    # asdf erlang build environment
    export KERL_CONFIGURE_OPTIONS="--with-ssl=${openssl.out} --with-ssl-incl=${openssl.dev} --with-odbc=${unixODBC}"
    export KERL_BUILD_DOCS=no
    export LDFLAGS="-L${ncurses.out}/lib -L${openssl.out}/lib -L${libGL}/lib -L${libGLU}/lib -L${unixODBC}/lib"
    export CFLAGS="-O2 -g -I${ncurses.dev}/include -I${openssl.dev}/include -I${libglvnd.dev}/include -I${libGLU.dev}/include -I${unixODBC}/include"
    export CPPFLAGS="-I${ncurses.dev}/include -I${openssl.dev}/include -I${libglvnd.dev}/include -I${libGLU.dev}/include -I${unixODBC}/include"
    export LIBRARY_PATH="${libraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
  '';
in
{
  options.presets.shared.cli-tools.asdf.enable = mkEnableOption "asdf version manager";

  config = mkIf config.presets.shared.cli-tools.asdf.enable {
    home.packages =
      with pkgs;
      [
        asdf-vm
        unzip
        # Elixir runtime dependencies
        inotify-tools
        watchman
      ]
      ++ erlangBuildInputs;

    programs.zsh.initContent = ''
      ${erlangEnv}
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
    '';

    programs.bash.initExtra = ''
      ${erlangEnv}
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
    '';

    home.activation.asdfPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.asdf-vm}/bin:$PATH"
      export ASDF_DATA_DIR="''${ASDF_DATA_DIR:-$HOME/.asdf}"

      if [ ! -d "$ASDF_DATA_DIR/plugins/erlang" ]; then
        ${pkgs.asdf-vm}/bin/asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
      fi

      if [ ! -d "$ASDF_DATA_DIR/plugins/elixir" ]; then
        ${pkgs.asdf-vm}/bin/asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true
      fi
    '';
  };
}
