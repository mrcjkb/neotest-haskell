local Path = require('plenary.path')

local sydtest = require('neotest-haskell.sydtest')
local async = require('nio').tests

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

local parse_positions = sydtest.parse_positions

describe('sydtest', function()
  local test_file = Path:new(test_cwd .. '/fixtures/sydtest/cabal/simple/test/SydtestFixtureSpec.hs')
  async.it('parse positions', function()
    local filename = test_file.filename
    local result = parse_positions(filename)
    local file_pos_id = filename
    assert_has_position(result, file_pos_id)
    local ns_1_pos_id = file_pos_id .. '::"Prelude.head"'
    assert_has_position(result, ns_1_pos_id)
    assert_has_position(result, ns_1_pos_id .. '::"Returns the first element of a list"')
    assert_has_position(result, ns_1_pos_id .. '::"Returns the first element of an arbitrary list"')
    local ns_2_pos_id = ns_1_pos_id .. '::"Empty list"'
    assert_has_position(result, ns_2_pos_id)
    assert_has_position(result, ns_2_pos_id .. '::"Throws on empty list"')
    local ns_3_pos_id = file_pos_id .. '::"Prelude.tail"'
    assert_has_position(result, ns_3_pos_id)
    local ns_4_pos_id = ns_3_pos_id .. '::"Single element list"'
    assert_has_position(result, ns_4_pos_id)
    assert_has_position(result, ns_4_pos_id .. '::"Returns the empty list"')
  end)
  describe('parse results', function()
    async.it('test failure', function()
      local filename = test_file.filename
      local tree = parse_positions(filename)
      local test_result_file = Path:new(test_cwd .. '/fixtures/sydtest/results/failure.txt')
      local result_filename = test_result_file.filename
      local context = {
        file = filename,
        pos_id = filename,
        type = 'file',
      }
      local results = sydtest.parse_results(context, result_filename, tree)
      assert.same('failed', results[filename].status)
      assert.same('failed', results[filename .. '::"Prelude.head"'].status)
      assert.same({
        status = 'skipped',
      }, results[filename .. '::"Prelude.head"::"Returns the first element of a list"'])
      assert.same(
        'failed',
        results[filename .. '::"Prelude.head"::"Returns the first element of an arbitrary list"'].status
      )
      assert.same({
        status = 'passed',
      }, results[filename .. '::"Prelude.head"::"Empty list"::"Throws on empty list"'])
    end)
  end)
end)
