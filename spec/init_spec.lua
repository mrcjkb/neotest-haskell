describe('Can set up neotest with neotest-haskell adapter', function()
  local notify_once = stub(vim, 'notify_once')
  local notify = stub(vim, 'notify')
  local deprecate = stub(vim, 'deprecate')

  it('with default config (cabal and stack)', function()
    ---@diagnostic disable-next-line: missing-fields
    require('neotest').setup {
      adapters = {
        require('neotest-haskell'),
      },
    }
  end)
  it('with cabal only', function()
    ---@diagnostic disable-next-line: missing-fields
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { build_tools = { 'cabal' } },
      },
    }
  end)
  it('with stack only', function()
    ---@diagnostic disable-next-line: missing-fields
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { build_tools = { 'stack' } },
      },
    }
  end)
  it('with tasty only', function()
    ---@diagnostic disable-next-line: missing-fields
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { frameworks = { 'tasty' } },
      },
    }
  end)
  it('with hspec only', function()
    ---@diagnostic disable-next-line: missing-fields
    require('neotest').setup {
      adapters = {
        require('neotest-haskell') { frameworks = { 'hspec' } },
      },
    }
  end)
  it('with framework spec', function()
    ---@diagnostic disable-next-line: missing-fields
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
  it('no notifications at startup.', function()
    if not pcall(assert.stub(notify_once).called_at_most, 0) then
      -- fails and outputs arguments
      assert.stub(notify_once).called_with(nil)
    end
    if not pcall(assert.stub(notify).called_at_most, 0) then
      assert.stub(notify).called_with(nil)
    end
  end)
  it('no deprecation warnings at startup.', function()
    if not pcall(assert.stub(deprecate).called_at_most, 0) then
      assert.stub(deprecate).called_with(nil)
    end
  end)
end)

describe('Fails on invalid config', function()
  it('no build tool is specified', function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { build_tools = {} },
        },
      }
    end)
  end)
  it('unknown build tool is specified', function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { build_tools = { 'unknown' } },
        },
      }
    end)
  end)
  it('no framework is specified', function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { frameworks = {} },
        },
      }
    end)
  end)
  it('unknown framework is specified', function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require('neotest-haskell') { frameworks = { 'unknown' } },
        },
      }
    end)
  end)
  it('framework spec with empty modules list', function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
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
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
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
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
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
    assert.has_error(function()
      ---@diagnostic disable-next-line: missing-fields
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
