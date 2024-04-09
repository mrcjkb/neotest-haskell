# Add flake.nix test inputs as arguments here
{
  self,
  neodev-nvim,
  plenary-nvim,
  neotest,
  nvim-nio,
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

  nio-plugin = final.pkgs.vimUtils.buildVimPlugin {
    name = "nvim-nio";
    src = nvim-nio;
  };

  nvim-treesitter-plugin = final.pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [p.haskell]);

  mkPlenaryTest = {
    nvim ? final.neovim-unwrapped,
    name,
  }: let
    nvim-wrapped = final.pkgs.wrapNeovim nvim {
      configure = {
        customRC = ''
          lua << EOF
          vim.cmd('runtime! plugin/plenary.vim')
          EOF
        '';
        packages.myVimPackage = {
          start = [
            final.neotest-haskell-dev
            plenary-plugin
            nvim-treesitter-plugin
            neotest-plugin
            nio-plugin
          ];
        };
      };
    };
  in
    mkDerivation {
      inherit name;

      phases = [
        "unpackPhase"
        "buildPhase"
        "checkPhase"
      ];

      src = self;

      doCheck = true;

      buildInputs = with final; [
        nvim-wrapped
        makeWrapper
      ];

      buildPhase = ''
        mkdir -p $out
        cp -r tests $out
      '';

      checkPhase = ''
        export HOME=$(realpath .)
        export TEST_CWD=$(realpath $out/tests)
        cd $out
        nvim --headless --noplugin -c "PlenaryBustedDirectory tests {nvim_cmd = 'nvim'}"
      '';
    };
in {
  nvim-stable-test = mkPlenaryTest {name = "nvim-stable-test";};
  nvim-nightly-test = mkPlenaryTest {
    name = "nvim-nightly-test";
    nvim = nvim-nightly;
  };
  inherit
    neodev-plugin
    plenary-plugin
    neotest-plugin
    nvim-treesitter-plugin
    ;
}
