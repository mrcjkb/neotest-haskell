vim.env.PLENARY_TEST_TIMEOUT = 60000
vim.opt.runtimepath:append(vim.env.NEOTEST_HASKELL_DEV_DIR)
vim.opt.runtimepath:append(vim.env.TREE_SITTER_HASKELL_DIR)
vim.opt.runtimepath:append(vim.env.PLENARY_DIR)

local compat = require('neotest-haskell.compat')
local hspec = require('neotest-haskell.hspec')
local async = require('nio').tests

local test_cwd = vim.fn.getcwd()

---@param tree neotest.Tree
---@param pos_id string
local function has_position(tree, pos_id)
  for _, node in tree:iter_nodes() do
    local data = node:data()
    if data.id == pos_id then
      return true
    end
  end
  return false
end

local function assert_has_position(tree, pos_id)
  assert(has_position(tree, pos_id), 'Position ' .. pos_id .. ' not found in tree ' .. vim.inspect(tree))
end

local parse_positions = hspec.parse_positions

describe('hspec', function()
  describe('parse positions', function()
    async.it('unqualified imports 0', function()
      local test_file = compat.joinpath(test_cwd, 'spec/fixtures/hspec/cabal/simple/test/FirstSpec.hs')
      local filename = test_file
      local result = parse_positions(filename)
      local file_pos_id = filename
      assert_has_position(result, file_pos_id)
      local ns_1_pos_id = file_pos_id .. '::"section 1"'
      assert_has_position(result, ns_1_pos_id)
      assert_has_position(result, ns_1_pos_id .. '::"is a tautology"')
      assert_has_position(result, ns_1_pos_id .. '::"assumes that 2 is 1"')
      local ns_2_pos_id = file_pos_id .. '::"section 2"'
      assert_has_position(result, ns_2_pos_id)
      assert_has_position(result, ns_2_pos_id .. '::"only contains one test"')
    end)
  end)
  async.it('unqualified imports 1', function()
    local test_file =
      compat.joinpath(test_cwd, 'spec/fixtures/hspec/cabal/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
    local filename = test_file
    local result = parse_positions(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"oneOf successful tests"'
    assert_has_position(result, ns_1_pos_id)
    assert_has_position(result, ns_1_pos_id .. '::"returns one of the thing"')
    assert_has_position(result, ns_1_pos_id .. '::"always has length 1"')
    local ns_2_pos_id = ns_1_pos_id .. '::"oneOf failing tests"'
    assert_has_position(result, ns_2_pos_id)
    assert_has_position(result, ns_2_pos_id .. '::"returns two of the thing"')
    assert_has_position(result, ns_1_pos_id .. '::"skipped it"')
    assert_has_position(result, ns_1_pos_id .. '::"skipped prop"')
    local ns_3_pos_id = ns_1_pos_id .. '::"skipped describe"'
    assert_has_position(result, ns_3_pos_id .. '::"implicitly skipped it"')
  end)
  async.it('unqualified imports 2', function()
    local test_file =
      compat.joinpath(test_cwd, 'spec/fixtures/hspec/stack/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
    local filename = test_file
    local result = parse_positions(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"Prelude.head"'
    assert_has_position(result, ns_1_pos_id)
    assert_has_position(result, ns_1_pos_id .. '::"Returns the first element of a list"')
    assert_has_position(result, ns_1_pos_id .. '::"Returns the first element of an arbitrary list"')
    local ns_2_pos_id = ns_1_pos_id .. '::"Empty list"'
    assert_has_position(result, ns_2_pos_id)
    assert_has_position(result, ns_2_pos_id .. '::"Throws on empty list"')
    local ns_3_pos_id = filename_pos_id .. '::"Prelude.tail"'
    assert_has_position(result, ns_3_pos_id)
    local ns_4_pos_id = ns_3_pos_id .. '::"Single element list"'
    assert_has_position(result, ns_4_pos_id)
    assert_has_position(result, ns_4_pos_id .. '::"Returns the empty list"')
  end)
  async.it('qualified imports', function()
    local test_file =
      compat.joinpath(test_cwd, 'spec/fixtures/hspec/cabal/multi-package/subpackage2/test/Fix2/FixtureSpec.hs')
    local filename = test_file
    local result = parse_positions(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"twoOf successful tests"'
    assert_has_position(result, ns_1_pos_id)
    assert_has_position(result, ns_1_pos_id .. '::"returns two of the thing"')
    assert_has_position(result, ns_1_pos_id .. '::"always has length 2"')
    local ns_2_pos_id = ns_1_pos_id .. '::"twoOf failing tests"'
    assert_has_position(result, ns_2_pos_id)
    assert_has_position(result, ns_2_pos_id .. '::"returns one of the thing"')
    assert_has_position(result, ns_1_pos_id .. '::"skipped it"')
    assert_has_position(result, ns_1_pos_id .. '::"skipped prop"')
    local ns_3_pos_id = ns_1_pos_id .. '::"skipped describe"'
    assert_has_position(result, ns_3_pos_id .. '::"implicitly skipped it"')
  end)

  describe('parse results', function()
    async.it('test failure', function()
      local test_file =
        compat.joinpath(test_cwd, 'spec/fixtures/hspec/stack/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
      local filename = test_file
      local tree = parse_positions(filename)
      local test_result_file = compat.joinpath(test_cwd, 'spec/fixtures/results/hspec_test_file_fail.txt')
      local result_filename = test_result_file
      local context = {
        file = filename,
        pos_id = filename,
        type = 'file',
      }
      local results = hspec.parse_results(context, result_filename, tree)
      local failure = {
        status = 'failed',
        errors = {
          {
            message = 'Falsifiable (after 1 test):\n0\n[]\nexpected: 5\nbut got: 0\n',
          },
        },
      }
      assert.same(failure, results[filename])
      assert.same({
        status = 'failed',
      }, results[filename .. '::"Prelude.head"'])
      assert.same({
        status = 'passed',
      }, results[filename .. '::"Prelude.head"::"Empty list"'])
      assert.same({
        status = 'passed',
      }, results[filename .. '::"Prelude.head"::"Empty list"::"Throws on empty list"'])
      assert.same({
        status = 'skipped',
      }, results[filename .. '::"Prelude.head"::"Returns the first element of a list"'])
      assert.same(failure, results[filename .. '::"Prelude.head"::"Returns the first element of an arbitrary list"'])
      assert.same({
        status = 'passed',
      }, results[filename .. '::"Prelude.tail"'])
      assert.same({
        status = 'passed',
      }, results[filename .. '::"Prelude.tail"::"Single element list"::"Returns the empty list"'])
    end)
  end)
end)
