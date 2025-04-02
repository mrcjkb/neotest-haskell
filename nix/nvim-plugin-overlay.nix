{
  name,
  self,
}: final: prev: let
  luaPackages-override = luaself: luaprev: {
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
