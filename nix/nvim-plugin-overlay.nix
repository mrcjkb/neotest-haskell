{
  name,
  self,
}: final: prev: let
  luaPackages-override = luaself: luaprev: {
    tree-sitter-haskell = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luarocks-build-treesitter-parser,
    }:
      buildLuarocksPackage {
        pname = "tree-sitter-haskell";
        version = "0.0.1-1";
        knownRockspec =
          (fetchurl {
            url = "mirror://luarocks/tree-sitter-haskell-0.0.1-1.rockspec";
            sha256 = "11ai1qk7q6pm406992lqyb7khcf9qpqvxai9pvm36mmdyn60shps";
          })
          .outPath;
        src = fetchzip {
          url = "https://github.com/tree-sitter/tree-sitter-haskell/archive/a50070d5bb5bd5c1281740a6102ecf1f4b0c4f19.zip";
          sha256 = "0hi72f7d4y89i6zkzg9r2j16ykxcb4vh4gwaxg9hcqa95wpv9qw6";
        };
        nativeBuildInputs = [
          luarocks-build-treesitter-parser
        ];
        preBuild = ''
          export HOME=$(mktemp -d)
        '';
        buildInputs = [
          final.tree-sitter
        ];
        propagatedBuildInputs = [luarocks-build-treesitter-parser];
      }) {};

    neotest-haskell = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaOlder,
      neotest,
    }:
      buildLuarocksPackage {
        pname = "neotest-haskell";
        version = "scm-1";
        knownRockspec = "${self}/neotest-haskell-scm-1.rockspec";
        src = self;

        disabled = luaOlder "5.1";
        propagatedBuildInputs = [
          neotest
          luaself.tree-sitter-haskell
        ];
      }) {};
  };
in {
  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackages-override;
  };

  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;

  luajit = prev.luajit.override {
    packageOverrides = luaPackages-override;
  };

  luajitPackages = prev.luajitPackages // final.luajit.pkgs;

  neotest-haskell-dev = prev.neovimUtils.buildNeovimPlugin {
    luaAttr = final.lua51Packages.neotest-haskell;
  };
}
