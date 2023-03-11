local util = require('neotest-haskell.util')
local lib = require('neotest.lib')

local hspec = {}

local describe_query = [[
  ;; describe (unqualified)
  (_ (_ (exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @namespace.name
  ) (#eq? @func_name "describe"))) @namespace.definition

  ;; describe (qualified)
  (_ (_ (exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @namespace.name
  ) (#eq? @func_name "describe"))) @namespace.definition
]]

---Parse the positions in a test file.
---@async
---@param path string Test file path
---@return neotest.Tree
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

---Format a test name for an hspec filter expression.
---@param test_name string The test name to format.
---@return string formatted_name Formatted for a hspec --match expression.
local function hspec_format(test_name)
  -- TODO: Escape '/' characters?
  local formatted_name = test_name:gsub('"', '')
  return formatted_name
end

---Parses hspec --match filter expressions for the top-level test positions.
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs hspec --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] match_opts The hspec --match expression options.
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

---Parses the hspec --match expression from a position, starting at a child node, up to its parents.
---@param pos neotest.Tree The position of the test or namespace to get the match for.
---@return string hspec_match_path The hspec --match expression for the test.
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

---Gets the --match filter for a position.
---Example:
--- - position.name: "My test"
--- - Hspec tests in path:
---   ```
---   describe "Run" $ do
---     it "My test" $ do
---     ...
---   ```
--- - Result: "/Run/My test"
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs hspec --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] hspec_match The hspec match expression for the test or namespace (see example).
local function get_hspec_match(mk_match_opts, pos)
  local data = pos:data()
  if data.type == 'file' then
    return parse_top_level_hspec_nodes(mk_match_opts, pos)
  end
  return mk_match_opts('/' .. parse_hspec_tree(pos) .. '/')
end

---@param pos neotest.Tree The position.
---@return table test_opts The Cabal test options for matching an hspec filter.
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

---@param pos neotest.Tree The position.
---@return string[] test_opts The Stack test options for matching an hspec filter.
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

---Get the errors from a build output.
---@param raw_lines string[] The raw build output lines.
---@param test_name string The name of the test.
---@return neotest.Error[] hspec_errors The errors.
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

---Get the file root from a test tree.
---@param tree neotest.Tree The test tree.
---@return neotest.Tree file_root The file root position.
local function get_file_root(tree)
  for _, node in tree:iter_parents() do
    local data = node and node:data()
    if data and not vim.tbl_contains({ 'test', 'namespace' }, data.type) then
      return node
    end
  end
  return tree
end

---@async
---@param context RunContext The run context.
---@param out_path string Path to an hspec test results output file.
---@param tree neotest.Tree The test tree at the position that was run.
---@return table<string, neotest.Result> results
function hspec.parse_results(context, out_path, tree)
  ---@type table<string, neotest.Result>
  local results = {}

  ---Set the status of the test and maybe its parents.
  ---@param node neotest.Tree
  ---@param status string The neotest status
  ---@param errors neotest.Error[]? The errors in case of failure
  local function set_test_statuses(node, status, errors)
    local data = node:data()
    if data then
      results[data.id] = {
        status = status,
        errors = errors,
      }
      local parent = node:parent()
      if parent and context.type == 'file' then
        set_test_statuses(parent, status)
      end
    end
  end

  ---Set the status of the test and maybe its parents.
  ---@param test_name string The name of the test.
  ---@param status string The neotest status.
  ---@param errors neotest.Error[]? The errors in case of failure.
  local function set_test_status(test_name, status, errors)
    test_name = '"' .. test_name .. '"'
    for _, node in get_file_root(tree):iter_nodes() do
      local data = node:data()
      if data and data.name == test_name and data.type == 'test' then
        set_test_statuses(node, status, errors)
      end
    end
  end

  local pos_id = context.pos_id
  local success, data = pcall(lib.files.read, out_path)
  if not success then
    return {}
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

  ---@type neotest.Result
  local failed = { status = 'failed' }
  local file_result = failed
  file_result.errors = {}
  results[pos_id] = failed
  for _, test_name in ipairs(success_positions) do
    set_test_status(test_name, 'passed')
  end
  for _, test_name in ipairs(failure_positions) do
    local errors = get_hspec_errors(lines, test_name)
    set_test_status(test_name, 'failed', errors)
    vim.list_extend(file_result.errors, errors)
  end
  results[context.file] = file_result
  return results
end

return hspec
