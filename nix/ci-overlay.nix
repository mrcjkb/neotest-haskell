{
  self,
  plenary-nvim-src,
}: final: prev: let
  luaPackages-override = luaself: luaprev: {
    nvim-nio = luaself.callPackage (
      {
        buildLuarocksPackage,
        fetchurl,
        fetchzip,
        lua,
        luaOlder,
      }:
        buildLuarocksPackage {
          pname = "nvim-nio";
          version = "1.9.3-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/nvim-nio-1.9.3-1.rockspec";
              sha256 = "1hfn2kds0mmp10q5v7s6hlvxjcwksjyqcyalrqfxpzvs921klnby";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/nvim-neotest/nvim-nio/archive/8765cbc4d0c629c8158a5341e1b4305fd93c3a90.zip";
            sha256 = "0drzp2fyancyz57k8nkwc1bd7bksy1f8bpy92njiccpdflwhkyjm";
          };

          disabled = luaOlder "5.1";
          propagatedBuildInputs = [lua];
        }
    ) {};

    neotest = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      lua,
      luaOlder,
      nvim-nio,
      plenary-nvim,
    }:
      buildLuarocksPackage {
        pname = "neotest";
        version = "5.2.3-1";
        knownRockspec =
          (fetchurl {
            url = "mirror://luarocks/neotest-5.2.3-1.rockspec";
            sha256 = "16pwkwv2dmi9aqhp6bdbgwhksi891iz73rvksqmv136jx6fi7za1";
          })
          .outPath;
        src = fetchzip {
          url = "https://github.com/nvim-neotest/neotest/archive/5caac5cc235d495a2382bc2980630ef36ac87032.zip";
          sha256 = "1i1d6m17wf3p76nm75jk4ayd4zyhslmqi2pc7j8qx87391mnz2c4";
        };
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [lua nvim-nio plenary-nvim];
      }) {};

    luarocks-build-treesitter-parser = luaself.callPackage ({
      buildLuarocksPackage,
      luaOlder,
      luafilesystem,
      fetchurl,
      fetchzip,
      lua,
      ...
    }:
      buildLuarocksPackage {
        pname = "luarocks-build-treesitter-parser";
        version = "2.0.0-1";
        knownRockspec =
          (fetchurl {
            url = "mirror://luarocks/luarocks-build-treesitter-parser-2.0.0-1.rockspec";
            sha256 = "0ylax1r0yl5k742p8n0fq5irs2r632npigqp1qckfx7kwi89gxhb";
          })
          .outPath;
        src = fetchzip {
          url = "https://github.com/nvim-neorocks/luarocks-build-treesitter-parser/archive/v2.0.0.zip";
          sha256 = "0gqiwk7dk1xn5n2m0iq5c7xkrgyaxwyd1spb573l289gprvlrbn5";
        };

        disabled = luaOlder "5.1";
        propagatedBuildInputs = [lua luafilesystem];
      }) {};

    tree-sitter-haskell = luaself.callPackage (
      {
        buildLuarocksPackage,
        fetchurl,
        fetchzip,
        luarocks-build-treesitter-parser,
        ...
      }:
        buildLuarocksPackage {
          pname = "tree-sitter-haskell";
          version = "scm-1";
          knownRockspec = self + "/spec/fixtures/tree-sitter-haskell-scm-1.rockspec";
          src = fetchzip {
            url = "https://github.com/tree-sitter/tree-sitter-haskell/archive/e29c59236283198d93740a796c50d1394bccbef5.zip";
            sha256 = "03mk4jvlg2l33xfd8p2xk1q0xcansij2sfa98bdnhsh8ac1jm30h";
          };
          propagatedBuildInputs = [
            luarocks-build-treesitter-parser
          ];
        }
    ) {};
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackages-override;
  };

  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;

  tree-sitter-haskell-plugin = final.neovimUtils.buildNeovimPlugin {
    pname = "tree-sitter-haskell";
    version = "scm";
    src = final.lua51Packages.tree-sitter-haskell.src;
  };

  mkNeorocksTest = {
    name,
    nvim ? final.neovim-unwrapped,
  }: let
    nvim-wrapped = final.wrapNeovim nvim {
      configure = {
        packages.myVimPackage = {
          start = with final.vimPlugins; [
            final.neotest-haskell-dev # Queries need to be on the rtp
            plenary-nvim # XXX: This needs to be on the nvim rtp
            tree-sitter-haskell-plugin
          ];
        };
      };
    };
  in
    final.neorocksTest {
      inherit name;
      pname = "neotest-haskell";
      src = self;
      neovim = nvim-wrapped;
      luaPackages = ps:
        with ps; [
          neotest
          nvim-nio
        ];

      preCheck = ''
        # Neovim expects to be able to create log files, etc.
        export HOME=$(realpath .)
      '';
    };
in {
  inherit
    lua5_1
    lua51Packages
    ;
  nvim-stable-test = mkNeorocksTest {name = "nvim-stable-test";};
  nvim-nightly-test = mkNeorocksTest {
    name = "nvim-nightly-test";
    nvim = final.neovim-nightly;
  };
}
