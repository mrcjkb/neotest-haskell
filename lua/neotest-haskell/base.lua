local lib = require('neotest.lib')
local logger = require("neotest.logging")

local M = {}

function M.is_test_file(file_path)
  return vim.endswith(file_path, "Spec.hs")
      or vim.endswith(file_path, "Test.hs")
end

M.match_package_root_pattern = lib.files.match_root_pattern('*.cabal', 'package.yaml')

M.match_project_root_pattern = lib.files.match_root_pattern("cabal.project", 'stack.yaml')

-- Wrapper around neotest.lib.treesitter.parse_positions
-- @type neotest.Tree
local function parse_positions(path, query)
  return lib.treesitter.parse_positions(path, query, { nested_tests = true })
end

-- @param test_name: The name of the test for which to query for a parent
-- @return a treesitter query for a 'describe'
-- with a child test that matches 'test_name'
-- @type string
-- NOTE: This query does not detect parent 'describe's defined in another function thatn the child (TODO?)
local function mk_parent_query(test_name)
  local test_name_escaped = vim.fn.escape(test_name, '"')
  return string.format([[
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

  ]], test_name_escaped
    , test_name_escaped
    , test_name_escaped
    , test_name_escaped
    , test_name_escaped
    , test_name_escaped
    )
end

-- @param path: Test file path
-- @type neotest.Tree
function M.parse_positions(path)
  local tests_query = [[
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
  return parse_positions(path, tests_query)
end

-- @param test_name: The test name to format
-- @return the name, formatted for a hspec --match expression
-- @type string
local function hspec_format(test_name)
  -- TODO: Escape '/' characters?
  return test_name:gsub('"', '')
end

-- Helper function for 'M.get_hspec_match(test_name, path)'
-- @parem acc: The accumulated result (formatted for a hspec --match expression)
-- @param test_name: The quoted, unformatted test name
-- @param path: The path to the file containing the tests
-- @return the hspec match for the test
-- @type string
local function get_hspec_match(acc, test_name, path)
  local parent_query = mk_parent_query(test_name)
  logger.debug('Querying treesitter for parent "describe": ' .. vim.inspect(parent_query))
  local parent_tree = parse_positions(path, parent_query)
  for _, parent_node in parent_tree:iter_nodes() do
    local data = parent_node:data()
    if data.type == "test" then
      local parent_name = data.name
      local parent_name_formatted = hspec_format(parent_name)
      return get_hspec_match(parent_name_formatted .. '/' .. acc, parent_name, path)
    end
  end
  return acc
end

-- Runs a treesitter query for the tests in the test file 'path',
-- and if there is a test that matches 'test_name',
-- prepends any parent 'describe's to the test name.
-- Example:
--  - test_name: "My test"
--  - Hspec tests in path:
--    ```
--    describe "Run" $ do
--      it "My test" $ do
--      ...
--    ```
--  - Result: "/Run/My test"
-- @param test_name: The quoted, unformatted test name
-- @param path: The path to the file containing the tests
-- @return the hspec match for the test (see example).
-- @type string
function M.get_hspec_match(test_name, path)
  local acc = hspec_format(test_name)
  return '"/' .. get_hspec_match(acc, test_name, path) .. '/"'
end

---@async
---@param out_path string: Path to machine readable cabal test results output file
---@return neotest.Result[]
function M.cabal_results(out_path)
  local success, data = pcall(lib.files.read, out_path)
  if not success then
    vim.notify('Failed to read cabal output.', vim.log.levels.ERROR)
    return {}
  end
  print('Data:')
  vim.pretty_print(data)
  return {} -- TODO
end

return M
