local util = require('neotest-haskell.util')
local lib = require('neotest.lib')
local logger = require('neotest.logging')

local hspec = {}

local describe_query = [[
  ;; describe (unqualified)
  (_ (exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @namespace.name
  ) (#eq? @func_name "describe")) @namespace.definition

  ;; describe (qualified)
  (_ (exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @namespace.name
  ) (#eq? @func_name "describe")) @namespace.definition
]]

-- @param path: Test file path
-- @type neotest.Tree
function hspec.parse_positions(path)
  local tests_query = describe_query
    .. [[
  ;; it (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#eq? @func_name "it")) @test.definition

  ;; it (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#eq? @func_name "it")) @test.definition

  ;; prop (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#eq? @func_name "prop")) @test.definition

  ;; prop (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#eq? @func_name "prop")) @test.definition
  ]]
  return util.parse_positions(path, tests_query)
end

-- @param test_name: The test name to format
-- @return the name, formatted for a hspec --match expression
-- @type string
local function hspec_format(test_name)
  -- TODO: Escape '/' characters?
  return test_name:gsub('"', '')
end

--- Parses the top level hspec node in a file
--- @param mk_match_opts fun(match_exp:string):string[]
--- @param pos neotest.Tree
--- @return string[] match_opts The hspec match options
local function parse_top_level_hspec_nodes(mk_match_opts, pos)
  local match_opts = {}
  for _, node in pos:iter_nodes() do
    local data = node:data()
    if data.type == 'namespace' then
      local parent = node:parent()
      local parent_data = parent and parent:data()
      if not parent_data or parent_data.type ~= 'namespace' then
        vim.list_extend(match_opts, mk_match_opts('/' .. hspec_format(data.name) .. '/'))
      end
    end
  end
  return match_opts
end

--- Recursively parses the hspec tree, starting at a child node, up to its parents.
--- @param pos neotest.Tree The position of the test to get the match for
--- @return string hspec_match_path The hspec match path for the test
local function parse_hspec_tree(pos)
  local data = pos:data()
  local result = hspec_format(data.name)
  for parent in pos:iter_parents() do
    if not parent then
      return result
    end
    local parent_data = parent:data()
    if parent_data.type ~= 'namespace' then
      return result
    end
    result = hspec_format(parent_data.name) .. '/' .. result
  end
  return result
end

--- Gets the --match filter for a position
--- Example:
---  - position.name: "My test"
---  - Hspec tests in path:
---    ```
---    describe "Run" $ do
---      it "My test" $ do
---      ...
---    ```
---  - Result: "/Run/My test"
--- @param mk_match_opts fun(match_exp:string):string[]
--- @param pos neotest.Tree
--- @return string[] hspec_match The hspec match for the test (see example).
local function get_hspec_match(mk_match_opts, pos)
  local data = pos:data()
  if data.type == 'file' then
    return parse_top_level_hspec_nodes(mk_match_opts, pos)
  end
  return mk_match_opts('/' .. parse_hspec_tree(pos) .. '/')
end

--- @param pos neotest.Tree
--- @return table test_opts The cabal test options for matching an hspec filter
function hspec.get_cabal_test_opts(pos)
  local function mk_match_opts(match_exp)
    return {
      '--test-option',
      '-m',
      '--test-option',
      match_exp,
    }
  end
  local match_opts = get_hspec_match(mk_match_opts, pos)
  return vim.list_extend(match_opts, {
    '--test-option',
    '--no-color',
    '--test-option',
    '--format=checks',
  })
end

--- @param pos neotest.Tree
--- @return string[] test_opts The stack test options for matching an hspec filter
function hspec.get_stack_test_opts(pos)
  local function mk_match_opts(match_exp)
    return {
      '--ta',
      '--match "' .. match_exp .. '"',
    }
  end
  local match_opts = get_hspec_match(mk_match_opts, pos)
  return vim.list_extend(match_opts, {
    '--ta',
    '--no-color --format=checks',
  })
end

-- Get the error messages
local function get_hspec_errors(raw_lines, test_name)
  local failures_found = false
  local pos_found = false
  local error_message = nil
  for _, line in ipairs(raw_lines) do
    local trimmed = (line:match('^%s*(.*)') or line):gsub('%s*$', '')
    if pos_found and trimmed:match('To rerun use:') then
      return { {
        message = error_message,
      } }
    elseif pos_found then
      error_message = error_message and error_message .. '\n' .. trimmed or trimmed
    end
    if failures_found and trimmed:match('.*' .. util.escape(test_name) .. '.*') then
      pos_found = true
    elseif trimmed:match('Failures:') then
      failures_found = true
    end
  end
  return {}
end

--- Initialise an empty results table for each test node
--- in the given path. This is necessary to prevent neotest
--- from displaying parent nodes of succeeded tests as 'passed'
--- if an unrelated test has failed.
--- @param path string The test file path.
--- @return table initial_result A neotest result table with all positions initialised as empty.
local function init_empty_result(path)
  local init_result = {}
  -- TODO: Parse positions from file content instead
  local positions = hspec.parse_positions(path)
  if not positions then
    logger.warn('Could not get positions to initialise result for ' .. path)
    return init_result
  end
  for _, node in positions:iter_nodes() do
    local pos = node:data()
    if vim.tbl_contains({ 'test', 'namespace' }, pos.type) then
      init_result[pos.id] = {}
    end
  end
  return init_result
end

---@async
---@param context table: Spec context with the following fields:
--- TODO: Define emmylua class for context
--- - file: Absolute path to the test file
--- - pos_id: Postition ID of the test that was discovered - '<file>::"<test.name>"' [@see base.parse_positions]
--- - pos_path: Absolute path to the file containing the test (== file)
--- - tree: neotest.Tree
---
---@param out_path string: Path to an hspec test results output file
function hspec.parse_results(context, out_path)
  local pos_path = context.pos_path
  local result = init_empty_result(pos_path)
  local tree = context.tree

  --- Set the status of the test and its parents
  ---@param node neotest.Tree
  ---@param status string The neotest status
  ---@param errors table? The errors in case of failure
  local function set_test_statuses(node, status, errors)
    local data = node:data()
    if data then
      result[data.id] = {
        status = status,
        errors = errors,
      }
      local parent = node:parent()
      if parent then
        set_test_statuses(parent, status)
      end
    end
  end

  --- Set the status of the test and its parents
  ---@param test_name string The name of the test
  ---@param status string The neotest status
  ---@param errors table? The errors in case of failure
  local function set_test_status(test_name, status, errors)
    test_name = '"' .. test_name .. '"'
    local start = tree:parent() or tree
    for _, node in start:iter_nodes() do
      local data = node:data()
      if data and data.name == test_name then
        set_test_statuses(node, status, errors)
      end
    end
  end

  local pos_id = context.pos_id
  local success, data = pcall(lib.files.read, out_path)
  if not success then
    vim.notify('Failed to read hspec output.', vim.log.levels.ERROR)
    return { [pos_id] = {
      status = 'failed',
    } }
  end
  local lines = vim.split(data, '\n')
  local failure_positions = {}
  local success_positions = {}
  for _, line in ipairs(lines) do
    local failed = line:match('%s*(.*)%s.✘')
    local succeeded = line:match('%s*(.*)%s.✔')
    if failed then
      failure_positions[#failure_positions + 1] = failed
    elseif succeeded then
      success_positions[#success_positions + 1] = succeeded
    end
  end

  result[pos_id] = {
    status = 'failed',
  }
  for _, test_name in ipairs(success_positions) do
    set_test_status(test_name, 'passed')
  end
  for _, test_name in ipairs(failure_positions) do
    set_test_status(test_name, 'failed', get_hspec_errors(lines, test_name))
  end
  return result
end

return hspec
