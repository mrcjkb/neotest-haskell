local Path = require('plenary.path')

local lib = require('neotest.lib')
local async = require('neotest.async')

-- XXX: Hack to allow testing parse_positions synchronously
async.util.scheduler = function()
  print('scheduler disabled')
end

---@param filename string
---@return string content
local function read_file(filename)
  local content
  local f = io.open(filename, 'r')
  assert(f ~= nil)
  content = f:read('*a')
  f:close()
  assert(content ~= nil)
  return content
end

lib.files.read = read_file

lib.treesitter.parse_positions = function(file_path, query, opts)
  opts = opts or {}
  local content = read_file(file_path)
  return lib.treesitter.parse_positions_from_string(file_path, content, query, opts)
end

local hspec = require('neotest-haskell.hspec')

local test_cwd = os.getenv('TEST_CWD')

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

local function parse_positions_sync(filename)
  return hspec.parse_positions(filename)
end

describe('hspec', function()
  describe('parse positions', function()
    it('unqualified imports 0', function()
      local test_file = Path:new(test_cwd .. '/fixtures/hspec/cabal/simple/test/FirstSpec.hs')
      local filename = test_file.filename
      local result = parse_positions_sync(filename)
      local filename_pos_id = filename
      assert_has_position(result, filename_pos_id)
      local ns_1_pos_id = filename_pos_id .. '::"section 1"'
      assert_has_position(result, ns_1_pos_id)
      local test_1_1_pos_id = ns_1_pos_id .. '::"is a tautology"'
      assert_has_position(result, test_1_1_pos_id)
      local test_1_2_pos_id = ns_1_pos_id .. '::"assumes that 2 is 1"'
      assert_has_position(result, test_1_2_pos_id)
      local ns_2_pos_id = filename_pos_id .. '::"section 2"'
      assert_has_position(result, ns_2_pos_id)
      local test_2_1_pos_id = ns_2_pos_id .. '::"only contains one test"'
      assert_has_position(result, test_2_1_pos_id)
    end)
  end)
  it('unqualified imports 1', function()
    local test_file = Path:new(test_cwd .. '/fixtures/hspec/cabal/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
    local filename = test_file.filename
    local result = parse_positions_sync(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"oneOf successful tests"'
    assert_has_position(result, ns_1_pos_id)
    local test_1_1_pos_id = ns_1_pos_id .. '::"returns one of the thing"'
    assert_has_position(result, test_1_1_pos_id)
    local test_1_2_pos_id = ns_1_pos_id .. '::"always has length 1"'
    assert_has_position(result, test_1_2_pos_id)
    local ns_2_pos_id = ns_1_pos_id .. '::"oneOf failing tests"'
    assert_has_position(result, ns_2_pos_id)
    local test_2_1_pos_id = ns_2_pos_id .. '::"returns two of the thing"'
    assert_has_position(result, test_2_1_pos_id)
  end)
  it('unqualified imports 2', function()
    local test_file = Path:new(test_cwd .. '/fixtures/hspec/stack/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
    local filename = test_file.filename
    local result = parse_positions_sync(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"Prelude.head"'
    assert_has_position(result, ns_1_pos_id)
    local test_1_1_pos_id = ns_1_pos_id .. '::"Returns the first element of a list"'
    assert_has_position(result, test_1_1_pos_id)
    local test_1_2_pos_id = ns_1_pos_id .. '::"Returns the first element of an arbitrary list"'
    assert_has_position(result, test_1_2_pos_id)
    local ns_2_pos_id = ns_1_pos_id .. '::"Empty list"'
    assert_has_position(result, ns_2_pos_id)
    local test_2_1_pos_id = ns_2_pos_id .. '::"Throws on empty list"'
    assert_has_position(result, test_2_1_pos_id)
    local ns_3_pos_id = filename_pos_id .. '::"Prelude.tail"'
    assert_has_position(result, ns_3_pos_id)
    local ns_4_pos_id = ns_3_pos_id .. '::"Single element list"'
    assert_has_position(result, ns_4_pos_id)
    local test_4_1_pos_id = ns_4_pos_id .. '::"Returns the empty list"'
    assert_has_position(result, test_4_1_pos_id)
  end)
  it('qualified imports', function()
    local test_file = Path:new(test_cwd .. '/fixtures/hspec/cabal/multi-package/subpackage2/test/Fix2/FixtureSpec.hs')
    local filename = test_file.filename
    local result = parse_positions_sync(filename)
    local filename_pos_id = filename
    assert_has_position(result, filename_pos_id)
    local ns_1_pos_id = filename_pos_id .. '::"twoOf successful tests"'
    assert_has_position(result, ns_1_pos_id)
    local test_1_1_pos_id = ns_1_pos_id .. '::"returns two of the thing"'
    assert_has_position(result, test_1_1_pos_id)
    local test_1_2_pos_id = ns_1_pos_id .. '::"always has length 2"'
    assert_has_position(result, test_1_2_pos_id)
    local ns_2_pos_id = ns_1_pos_id .. '::"twoOf failing tests"'
    assert_has_position(result, ns_2_pos_id)
    local test_2_1_pos_id = ns_2_pos_id .. '::"returns one of the thing"'
    assert_has_position(result, test_2_1_pos_id)
  end)

  describe('parse results', function()
    it('test file - failure', function()
      local test_file = Path:new(test_cwd .. '/fixtures/hspec/stack/multi-package/subpackage1/test/Fix1/FixtureSpec.hs')
      local filename = test_file.filename
      local tree = parse_positions_sync(filename)
      local test_result_file = Path:new(test_cwd .. '/fixtures/results/test_file_fail.txt')
      local result_filename = test_result_file.filename
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
        status = 'passed',
      }, results[filename .. '::"Prelude.head"::"Returns the first element of a list"'])
      assert.same({
        status = 'passed',
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
