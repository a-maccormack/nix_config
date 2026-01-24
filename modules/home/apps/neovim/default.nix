{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{
  options.presets.home.apps.neovim.enable = mkEnableOption "Neovim editor";

  config = mkIf config.presets.home.apps.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        # LSP
        nvim-lspconfig

        # Completion
        nvim-cmp
        cmp-buffer
        cmp-path
        cmp_luasnip
        cmp-nvim-lsp
        cmp-nvim-lua

        # Snippets
        luasnip
        friendly-snippets

        # Syntax
        nvim-treesitter.withAllGrammars

        # Fuzzy finder
        telescope-nvim
        plenary-nvim

        # Formatting
        conform-nvim

        # Git
        gitsigns-nvim

        # Comments
        comment-nvim

        # Theme
        github-nvim-theme

        # Utilities
        undotree
        vim-better-whitespace
      ];

      extraPackages = with pkgs; [
        # LSP servers
        typescript-language-server
        pyright
        ruff
        lua-language-server
        rust-analyzer
        # elixir-ls removed - using standalone release to respect asdf's Elixir version
        terraform-ls
        nil

        # Formatters
        nodePackages.prettier
        stylua
        nixpkgs-fmt
      ];
    };

    # Recursive source for entire nvim config directory
    xdg.configFile."nvim" = {
      source = ./config;
      recursive = true;
    };

    # Clean up old nvim config before linking new one
    home.activation.cleanNvimConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        echo "Removing old nvim config directory..."
        rm -rf "$HOME/.config/nvim"
      fi
    '';

    # Download standalone elixir-ls (uses system Elixir from asdf)
    home.activation.installElixirLs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ELIXIR_LS_DIR="$HOME/.local/share/elixir-ls"
      ELIXIR_LS_VERSION="v0.30.0"
      VERSION_FILE="$ELIXIR_LS_DIR/.version"

      # Check if we need to install/update
      CURRENT_VERSION=""
      if [ -f "$VERSION_FILE" ]; then
        CURRENT_VERSION=$(cat "$VERSION_FILE")
      fi

      if [ "$CURRENT_VERSION" != "$ELIXIR_LS_VERSION" ]; then
        echo "Installing ElixirLS $ELIXIR_LS_VERSION..."
        rm -rf "$ELIXIR_LS_DIR"
        mkdir -p "$ELIXIR_LS_DIR"
        ${pkgs.curl}/bin/curl -fsSL "https://github.com/elixir-lsp/elixir-ls/releases/download/$ELIXIR_LS_VERSION/elixir-ls-$ELIXIR_LS_VERSION.zip" -o "/tmp/elixir-ls.zip"
        ${pkgs.unzip}/bin/unzip -o "/tmp/elixir-ls.zip" -d "$ELIXIR_LS_DIR"
        chmod +x "$ELIXIR_LS_DIR/language_server.sh"
        rm "/tmp/elixir-ls.zip"
        echo "$ELIXIR_LS_VERSION" > "$VERSION_FILE"
        echo "ElixirLS $ELIXIR_LS_VERSION installed to $ELIXIR_LS_DIR"
      fi
    '';
  };
}
