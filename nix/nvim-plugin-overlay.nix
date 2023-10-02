{
  name,
  self,
}: final: prev: {
  neotest-haskell-dev = prev.vimUtils.buildVimPlugin {
    inherit name;
    src = self;
  };
}
