{
  description = "A Neotest adapter for Haskell.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neorocks.url = "github:nvim-neorocks/neorocks";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";

    git-hooks.url = "github:cachix/git-hooks.nix";

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    plenary-nvim-src = {
      url = "github:nvim-lua/plenary.nvim/";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    gen-luarc,
    git-hooks,
    flake-utils,
    plenary-nvim-src,
    ...
  }: let
    name = "neotest-haskell";

    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    ci-overlay = import ./nix/ci-overlay.nix {
      inherit
        (inputs)
        self
        plenary-nvim-src
        ;
    };

    nvim-plugin-overlay = import ./nix/nvim-plugin-overlay.nix {
      inherit name;
      inherit self;
    };
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          ci-overlay
          nvim-plugin-overlay
          neorocks.overlays.default
          gen-luarc.overlays.default
        ];
      };

      luarc-plugins = with pkgs.lua51Packages; (with pkgs.vimPlugins; [
        neotest
        nvim-nio
      ]);

      luarc-nightly = pkgs.mk-luarc {
        nvim = pkgs.neovim-nightly;
        plugins = luarc-plugins;
      };

      luarc-stable = pkgs.mk-luarc {
        nvim = pkgs.neovim-unwrapped;
        plugins = luarc-plugins;
        disabled-diagnostics = [
          "duplicate-set-field" # neotest
          "undefined-doc-name"
          "redundant-parameter"
          "invisible"
        ];
      };

      type-check-nightly = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          lua-ls = {
            enable = true;
            settings.configuration = luarc-nightly;
          };
        };
      };

      type-check-stable = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          lua-ls = {
            enable = true;
            settings.configuration = luarc-stable;
          };
        };
      };

      pre-commit-check = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
        };
      };

      devShell = pkgs.nvim-nightly-test.overrideAttrs (oa: {
        name = "neotest-haskell devShell";
        shellHook = ''
          ${pre-commit-check.shellHook}
          ln -fs ${pkgs.luarc-to-json luarc-nightly} .luarc.json
          export NEOTEST_HASKELL_DEV_DIR=${pkgs.neotest-haskell-dev}
          export TREE_SITTER_HASKELL_DIR=${pkgs.tree-sitter-haskell-plugin}
          # FIXME: Needed by neotest
          export PLENARY_DIR=${pkgs.vimPlugins.plenary-nvim}
        '';
        buildInputs =
          self.checks.${system}.pre-commit-check.enabledPackages
          ++ (with pkgs; [
            lua-language-server
          ])
          ++ oa.buildInputs
          ++ oa.propagatedBuildInputs;
        doCheck = false;
      });

      docgen = pkgs.callPackage ./nix/docgen.nix {};
    in {
      devShells = {
        default = devShell;
        inherit devShell;
      };

      packages = rec {
        default = nvim-plugin;
        nvim-plugin = pkgs.neotest-haskell-dev;
        inherit docgen;
      };

      checks = {
        inherit
          pre-commit-check
          type-check-stable
          type-check-nightly
          ;
        inherit
          (pkgs)
          nvim-stable-test
          nvim-nightly-test
          ;
      };
    })
    // {
      overlays = {
        inherit nvim-plugin-overlay;
        default = nvim-plugin-overlay;
      };
    };
}
