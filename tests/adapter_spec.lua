local base = require('neotest-haskell.base')

describe('adapter', function()
  it('recognises file paths in test directory', function()
    assert.is_true(base.is_test_file('some/project/test/Properties.hs'))
  end)
  it('recognises file paths in spec directory', function()
    assert.is_true(base.is_test_file('some/project/spec/Properties.hs'))
  end)
  it('recognises *Spec.hs files', function()
    assert.is_true(base.is_test_file('some/project/SomeSpec.hs'))
  end)
  it('recognises *Test.hs files', function()
    assert.is_true(base.is_test_file('some/project/SomeTest.hs'))
  end)
  it('does not recognise non-test files', function()
    assert.is_false(base.is_test_file('some/project/Data/List.hs'))
  end)
end)
