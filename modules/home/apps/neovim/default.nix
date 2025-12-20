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

    # Lua config files
    xdg.configFile = {
      "nvim/init.lua".source = ./config/init.lua;
      "nvim/lua/scripts/init.lua".source = ./config/lua/scripts/init.lua;
      "nvim/lua/scripts/set.lua".source = ./config/lua/scripts/set.lua;
      "nvim/lua/scripts/remap.lua".source = ./config/lua/scripts/remap.lua;
      "nvim/after/plugin/lsp.lua".source = ./config/after/plugin/lsp.lua;
      "nvim/after/plugin/telescope.lua".source = ./config/after/plugin/telescope.lua;
      "nvim/after/plugin/treesitter.lua".source = ./config/after/plugin/treesitter.lua;
      "nvim/after/plugin/theme.lua".source = ./config/after/plugin/theme.lua;
      "nvim/after/plugin/gitsigns.lua".source = ./config/after/plugin/gitsigns.lua;
      "nvim/after/plugin/commentary.lua".source = ./config/after/plugin/commentary.lua;
      "nvim/after/plugin/cmp.lua".source = ./config/after/plugin/cmp.lua;
    };
  };
}
