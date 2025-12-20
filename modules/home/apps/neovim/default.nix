{ lib, config, pkgs, ... }:

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
        elixir-ls
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
  };
}
