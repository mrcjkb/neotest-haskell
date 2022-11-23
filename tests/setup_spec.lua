describe('Can set up neotest', function()
  it('with neotest-haskell apapter', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell'),
      },
    }
  end)
end)
