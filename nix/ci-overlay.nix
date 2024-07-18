{
  self,
  plenary-nvim-src,
}: final: prev: let
  tree-sitter-haskell-plugin = final.neovimUtils.buildNeovimPlugin {
    pname = "tree-sitter-haskell";
    src = final.lua51Packages.tree-sitter-haskell.src;
  };

  mkNeorocksTest = {
    name,
    nvim ? final.neovim-unwrapped,
  }:
    final.neorocksTest {
      inherit name;
      pname = "neotest-haskell";
      src = self;
      neovim = nvim;
      luaPackages = ps:
        with ps; [
          neotest
          nvim-nio
          tree-sitter-haskell
        ];

      preCheck = ''
        # Neovim expects to be able to create log files, etc.
        export HOME=$(realpath .)
        # These have to be on the rtp for queries to work
        export NEOTEST_HASKELL_DEV_DIR=${final.neotest-haskell-dev}
        export TREE_SITTER_HASKELL_DIR=${tree-sitter-haskell-plugin}
      '';
    };
in {
  nvim-stable-test = mkNeorocksTest {name = "nvim-stable-test";};
  nvim-nightly-test = mkNeorocksTest {
    name = "nvim-nightly-test";
    nvim = final.neovim-nightly;
  };
}
