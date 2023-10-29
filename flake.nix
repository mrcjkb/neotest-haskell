{
  description = "A Neotest adapter for Haskell.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };

    # inputs for tests and lints
    neodev-nvim = {
      url = "github:folke/neodev.nvim";
      flake = false;
    };

    neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    neovim-nightly-overlay,
    pre-commit-hooks,
    neodev-nvim,
    plenary-nvim,
    neotest,
    ...
  }: let
    name = "neotest-haskell";

    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    ci-overlay = import ./nix/ci-overlay.nix {inherit (inputs) self neodev-nvim plenary-nvim neotest;};

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
          neovim-nightly-overlay.overlay
        ];
      };

      mkTypeCheck = {
        nvim-api ? [],
        disabled-diagnostics ? [],
      }:
        pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls.enable = true;
          };
          settings = {
            lua-ls = {
              config = {
                runtime.version = "LuaJIT";
                Lua = {
                  workspace = {
                    library =
                      nvim-api
                      ++ (with pkgs; [
                        "${neotest-plugin}/lua"
                        # FIXME:
                        # "${pkgs.luajitPackages.busted}"
                      ]);
                    checkThirdParty = false;
                    ignoreDir = [
                      ".git"
                      ".github"
                      ".direnv"
                      "result"
                      "nix"
                      "doc"
                      "tests" # neotest's types are not well-defined
                    ];
                  };
                  diagnostics = {
                    globals = [
                      "vim"
                      "describe"
                      "it"
                      "assert"
                    ];
                    libraryFiles = "Disable";
                    disable = disabled-diagnostics;
                  };
                };
              };
            };
          };
        };

      type-check-stable = mkTypeCheck {
        nvim-api = [
          "${pkgs.neovim}/share/nvim/runtime/lua"
          "${pkgs.neodev-plugin}/types/stable"
        ];
        disabled-diagnostics = [
          "duplicate-set-field" # neotest
          "undefined-doc-name"
          "redundant-parameter"
          "invisible"
        ];
      };

      type-check-nightly = mkTypeCheck {
        nvim-api = [
          "${pkgs.neovim-nightly}/share/nvim/runtime/lua"
          "${pkgs.neodev-plugin}/types/nightly"
        ];
        disabled-diagnostics = [
          "duplicate-set-field" # neotest
        ];
      };

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
        };
      };

      devShell = pkgs.mkShell {
        name = "neotest-haskell devShell";
        inherit (pre-commit-check) shellHook;
        buildInputs =
          (with pkgs; [
            zlib
          ])
          ++ (with pre-commit-hooks.packages.${system}; [
            alejandra
            lua-language-server
            stylua
            editorconfig-checker
            markdownlint-cli
          ]);
      };

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
