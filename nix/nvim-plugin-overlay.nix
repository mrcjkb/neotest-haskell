{
  name,
  self,
}: final: prev: {
  neotest-haskell-dev = prev.vimUtils.buildVimPluginFrom2Nix {
    inherit name;
    src = self;
  };
}
