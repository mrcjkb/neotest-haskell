{ name, self }:
final: prev: {
  haskell-tools-nvim-dev = prev.vimUtils.buildVimPluginFrom2Nix {
    inherit name;
    src = self;
  };
}
