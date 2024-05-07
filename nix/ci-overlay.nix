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
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackages-override;
  };

  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;

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
            (nvim-treesitter.withPlugins (p: [p.haskell])) # TODO: replace with tree-sitter-haskell
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
