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
  it('with tasty only', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { frameworks = { 'tasty' } },
      },
    }
  end)
  it('with hspec only', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { frameworks = { 'hspec' } },
      },
    }
  end)
  it('with framework spec', function()
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') {
          frameworks = {
            {
              framework = 'tasty',
              modules = { 'Test.Tasty', 'MyTestModule' },
            },
            'hspec',
          },
        },
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
  it('no framework is specified', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { frameworks = {} },
        },
      }
    end)
  end)
  it('unknown framework is specified', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { frameworks = { 'unknown' } },
        },
      }
    end)
  end)
  it('framework spec with empty modules list', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') {
            frameworks = {
              {
                framework = 'tasty',
                modules = {},
              },
            },
          },
        },
      }
    end)
  end)
  it('framework spec without modules', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') {
            frameworks = {
              {
                framework = 'tasty',
              },
            },
          },
        },
      }
    end)
  end)
  it('framework spec with unknown framework', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') {
            frameworks = {
              {
                framework = 'unknown',
                modules = { 'DummyModule' },
              },
            },
          },
        },
      }
    end)
  end)
  it('framework spec without framework field', function()
    assert.errors(function()
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') {
            frameworks = {
              {
                modules = { 'DummyModule' },
              },
            },
          },
        },
      }
    end)
  end)
end)
