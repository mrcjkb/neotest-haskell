local hspec = require('neotest-haskell.hspec')
local treesitter = require('neotest-haskell.treesitter')
local position = require('neotest-haskell.position')
local results = require('neotest-haskell.results')

local sydtest = {}

sydtest.default_modules = { 'Test.Syd' }

sydtest.position_query = hspec.position_query .. treesitter.get_position_query('sydtest')

---Parse the positions in a test file.
---@async
---@param path string Test file path
---@return neotest.Tree
function sydtest.parse_positions(path)
  return position.parse_positions(path, sydtest.position_query)
end

---Parses sydtest --match filter expressions for the top-level test positions.
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs sydtest --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] match_opts The sydtest --match expression options.
local function parse_top_level_sydtest_nodes(mk_match_opts, pos)
  local function prepend_match_opt(match_opts, pos_name)
    return vim.list_extend(match_opts, mk_match_opts(position.format_name(pos_name)))
  end
  local function concat_match_opts(match_opts)
    return match_opts
  end
  local parse = position.mk_top_level_node_parser(prepend_match_opt, concat_match_opts)
  return parse(pos)
end

---Parses the sydtest --match expression from a position, starting at a child node, up to its parents.
---@param pos neotest.Tree The position of the test or namespace to get the match for.
---@return string sydtest_match_path The sydtest --match expression for the test.
local function parse_sydtest_tree(pos)
  local function format_result(result)
    return result
  end
  local function prepend_position(result, pos_name)
    return pos_name .. '.' .. result
  end
  local parse = position.mk_test_tree_parser(position.format_name, format_result, prepend_position)
  return parse(pos)
end

---Constructs the Hspec --match filter for a position.
---
---Example:
---
--- - position.name: "My test"
--- - Hspec tests in path:
---   ```haskell
---   describe "Run" $ do
---     it "My test" $ do
---     ...
---   ```
--- - Result: "/Run/My test"
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs sydtest --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] sydtest_match The sydtest match expression for the test or namespace (see example).
local function mk_sydtest_match_opts(mk_match_opts, pos)
  local data = pos:data()
  if data.type == 'file' then
    return parse_top_level_sydtest_nodes(mk_match_opts, pos)
  end
  return mk_match_opts(parse_sydtest_tree(pos))
end

---@param pos neotest.Tree The position.
---@return string[] test_opts The Cabal test options for matching an sydtest filter.
function sydtest.get_cabal_test_opts(pos)
  local function mk_match_opts(match_exp)
    return {
      '--test-option',
      '--filter',
      '--test-option',
      match_exp,
    }
  end
  local match_opts = mk_sydtest_match_opts(mk_match_opts, pos)
  return vim.list_extend(match_opts, {
    '--test-option',
    '--no-colour',
  })
end

---@param pos neotest.Tree The position.
---@return string[] test_opts The Stack test options for matching an sydtest filter.
function sydtest.get_stack_test_opts(pos)
  local function mk_match_opts(match_exp)
    return {
      '--ta',
      ('"--filter %s"'):format(match_exp),
    }
  end
  local match_opts = mk_sydtest_match_opts(mk_match_opts, pos)
  return vim.list_extend(match_opts, {
    '--ta',
    '--no-colour',
  })
end

local function get_failed_name(line, _, _)
  local m = line:match('%s*✗%s(.+)%s+%d+%.%d+%sms')
  return m and m:gsub('%s*$', '') -- trim trailing whitespace
end

local function get_succeeded_name(line, _, _)
  local m = line:match('%s*✓%s(.*)%s+%d+%.%d+%sms')
  return m and m:gsub('%s*$', '') -- trim trailing whitespace
end

local function get_skipped_name(line, _, _)
  local m = line:match('%s+(.*)')
  return m and m:gsub('%s*$', '') -- trim trailing whitespace
end

---Get the errors from a build output.
---@param raw_lines string[] The raw build output lines.
---@param test_name string The name of the test.
---@return neotest.Error[] hspec_errors The errors.
local function parse_errors(raw_lines, test_name)
  local util = require('neotest-haskell.strings')
  local failures_found = false
  local err_msg_pos_found = false
  local error_message = nil
  for _, line in ipairs(raw_lines) do
    local without_timing = line:gsub('%d+%.%d+%sms', '')
    local trimmed = util.trim(without_timing)
    if err_msg_pos_found and trimmed == '' then
      return { {
        message = error_message,
      } }
    elseif err_msg_pos_found then
      error_message = error_message and error_message .. '\n' .. trimmed or trimmed
    end
    local err_msg_pos_start_pattern = '✗%s%d+%s.+' .. util.escape(test_name) .. '.*'
    if failures_found and trimmed:match(err_msg_pos_start_pattern) then
      err_msg_pos_found = true
    elseif trimmed:match('Failures:') then
      failures_found = true
    end
  end
  return {}
end

sydtest.parse_results = results.mk_result_parser(parse_errors, get_failed_name, get_succeeded_name, get_skipped_name)

---@cast sydtest TestFrameworkHandler
return sydtest
