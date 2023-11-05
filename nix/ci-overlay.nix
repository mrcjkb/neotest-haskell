# Add flake.nix test inputs as arguments here
{
  self,
  neodev-nvim,
  plenary-nvim,
  neotest,
}: final: prev:
with final.lib;
with final.stdenv; let
  nvim-nightly = final.neovim-nightly;

  neodev-plugin = final.pkgs.vimUtils.buildVimPlugin {
    name = "neodev.nvim";
    src = neodev-nvim;
  };

  plenary-plugin = final.pkgs.vimUtils.buildVimPlugin {
    name = "plenary.nvim";
    src = plenary-nvim;
  };

  neotest-plugin = final.pkgs.vimUtils.buildVimPlugin {
    name = "neotest";
    src = neotest;
  };

  # NOTE: Only the haskell parser is required
  nvim-treesitter-plugin = final.pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [p.haskell]);

  mkNeorocksTest = {
    name,
    nvim ? final.neovim-unwrapped,
    extraPkgs ? [],
  }: let
    nvim-wrapped = final.pkgs.wrapNeovim nvim {
      configure = {
        packages.myVimPackage = {
          start = [
            # Add plugin dependencies that aren't on LuaRocks here
            neotest-plugin
            plenary-plugin # NOTE: dependency of neotest
            nvim-treesitter-plugin
          ];
        };
      };
    };
  in
    final.pkgs.neorocksTest {
      inherit name;
      pname = "neotest-haskell";
      src = self;
      neovim = nvim-wrapped;

      # luaPackages = ps: with ps; [];

      preCheck = ''
        export HOME=$(realpath .)
        export TEST_CWD=$(realpath ./tests)
      '';

      buildPhase = ''
        mkdir -p $out
        cp -r tests $out
      '';
    };
in {
  nvim-stable-test = mkNeorocksTest {name = "neovim-stable-tests";};
  nvim-nightly-test = mkNeorocksTest {
    name = "neovim-nightly-tests";
    nvim = nvim-nightly;
  };
  inherit
    neodev-plugin
    plenary-plugin
    neotest-plugin
    ;
}
