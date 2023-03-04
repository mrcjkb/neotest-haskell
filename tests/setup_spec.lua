describe('Can set up neotest with neotest-haskell adapter', function()
  it('with default config (cabal and stack)', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell'),
      },
    }
  end)
  it('with cabal only', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { build_tools = { 'cabal' } },
      },
    }
  end)
  it('with stack only', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { build_tools = { 'stack' } },
      },
    }
  end)
end)
describe('Fails on invalid config', function()
  it('no build tool is specified', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { build_tools = {} },
        },
      }
    end)
  end)
  it('unknown build tool is specified', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { build_tools = { 'unknown' } },
        },
      }
    end)
  end)
end)
