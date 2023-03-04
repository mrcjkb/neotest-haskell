local util = require('neotest-haskell.util')
local lib = require('neotest.lib')
local logger = require('neotest.logging')

local hspec = {}

-- @param test_name: The name of the test for which to query for a parent
-- @return a treesitter query for a 'describe'
-- with a child test that matches 'test_name'
-- @type string
-- NOTE: This query does not detect parent 'describe's defined in another function thatn the child (TODO?)
local function mk_parent_query(test_name)
  local test_name_escaped = vim.fn.escape(test_name, '"')
  return string.format(
    [[
  ;; describe (unqualified) with child that matches test_name (multiple queries)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  ))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition

  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (_ (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  )))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition

  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (_ (_ (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  ))))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition

  ; describe (unqualified, no do notation) with child that matches test_name
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (exp_apply
    (exp_literal) @child_name
  )
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition

  ;; describe (qualified) with child that matches test_name (multiple queries)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  ))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition

  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (_ (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  )))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition


  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (_ (_ (_ (_ (_ (exp_apply
    (exp_literal) @child_name
  ))))))
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition


  ; describe (qualified, no do notation) with child that matches test_name
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (exp_apply
    (exp_literal) @child_name
  )
  (#eq? @func_name "describe")
  (#eq? @child_name "%s")
  ) @test.definition
  ]],
    test_name_escaped,
    test_name_escaped,
    test_name_escaped,
    test_name_escaped,
    test_name_escaped,
    test_name_escaped,
    test_name_escaped,
    test_name_escaped
  )
end

local describe_query = [[
  ;; describe (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#eq? @func_name "describe")) @test.definition

  ;; describe (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#eq? @func_name "describe")) @test.definition
]]

-- @param path: Test file path
-- @type neotest.Tree
function hspec.parse_positions(path)
  local tests_query = describe_query
    .. [[
  ;; describe (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#eq? @func_name "describe")) @test.definition

  ;; describe (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#eq? @func_name "describe")) @test.definition

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
--- @param path string The test file path
--- @return string hspec_match_path The hspec match path for the top level node of the hspec tree
local function parse_top_level_hspec_node(path)
  local positions = util.parse_positions(path, describe_query)
  local top_level
  for _, node in positions:iter_nodes() do
    local data = node:data()
    if data.type == 'test' then
      top_level = (top_level and data.range[1] < top_level.range[1] and data or top_level) or data
    end
  end
  return top_level and hspec_format(top_level.name) or ''
end

--- Recursively parses the hspec tree, starting at a child node, up to its parents.
--- @param position table neotest.Position The position of the test to get the match for
--- @return string hspec_match_path The hspec match path for the test
local function parse_hspec_tree(position)
  local test_name = position.name
  local path = position.path
  local row = position.range[1]
  local parent_query = mk_parent_query(test_name)
  local parent_tree = util.parse_positions(path, parent_query)
  local nearest
  for _, parent_node in parent_tree:iter_nodes() do
    local data = parent_node:data()
    if data.type == 'test' then
      if data.range[1] <= row - 1 then
        nearest = parent_node
      else
        break
      end
    end
  end
  if not nearest then
    return hspec_format(test_name)
  end
  local parent_position = nearest:data()
  return parse_hspec_tree(parent_position) .. '/' .. hspec_format(test_name)
end

local function parse_hspec_match(position)
  if position.type == 'file' then
    return parse_top_level_hspec_node(position.path)
  end
  return parse_hspec_tree(position)
end

--- Runs a treesitter query for tests at a `neotest.Position`,
--- and if there is a test that matches <test_name>,
--- prepends any parent <describe>s to the test name.
--- Example:
---  - position.name: "My test"
---  - Hspec tests in path:
---    ```
---    describe "Run" $ do
---      it "My test" $ do
---      ...
---    ```
---  - Result: "/Run/My test"
--- @param pos table (neotest.Position) The position of the test to get the match for
--- @return string hspec_match The hspec match for the test (see example).
local function get_hspec_match(pos)
  local hspec_match = '/' .. parse_hspec_match(pos) .. '/'
  vim.notify('HSpec: --match: ' .. hspec_match, vim.log.levels.INFO)
  return hspec_match
end

--- @param pos table the position of the test to get the match for
--- @return table test_opts The cabal test options for matching an hspec filter
function hspec.get_cabal_test_opts(pos)
  return {
    '--test-option',
    '-m',
    '--test-option',
    get_hspec_match(pos),
    '--test-option',
    '--no-color',
    '--test-option',
    '--format=checks',
  }
end

--- @param pos neotest.Position The position of the test to get the match for
--- @return string[] test_opts The stack test options for matching an hspec filter
function hspec.get_stack_test_opts(pos)
  return {
    '--ta',
    '--match "' .. get_hspec_match(pos) .. '" --no-color --format=checks',
  }
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
  local positions = hspec.parse_positions(path)
  if not positions then
    logger.warn('Could not get positions to initialise result for ' .. path)
    return init_result
  end
  for _, node in positions:iter_nodes() do
    local pos = node:data()
    if pos.type == 'test' then
      init_result[pos.id] = {}
    end
  end
  return init_result
end

---@async
---@param context table: Spec context with the following fields:
--- - file: Absolute path to the test file
--- - pos_id: Postition ID of the test that was discovered - '<file>::"<test.name>"' [@see base.parse_positions]
--- - pos_path: Absolute path to the file containing the test (== file)
---@param out_path string: Path to an hspec test results output file
function hspec.parse_results(context, out_path)
  local pos_id = context.pos_id
  local pos_path = context.pos_path
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
  local result = init_empty_result(context.pos_path)

  result[pos_id] = {
    status = 'failed',
  }
  for _, pos in ipairs(failure_positions) do
    result[pos_path .. '::"' .. pos .. '"'] = {
      status = 'failed',
      errors = get_hspec_errors(lines, pos),
    }
  end
  for _, pos in ipairs(success_positions) do
    result[pos_path .. '::"' .. pos .. '"'] = {
      status = 'passed',
    }
  end
  return result
end

return hspec
