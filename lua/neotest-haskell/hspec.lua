local treesitter = require('neotest-haskell.treesitter')
local position = require('neotest-haskell.position')
local results = require('neotest-haskell.results')

local hspec = {}

hspec.default_modules = { 'Test.Hspec' }

hspec.position_query = treesitter.get_position_query('hspec')

---Parse the positions in a test file.
---@async
---@param path string Test file path
---@return neotest.Tree
function hspec.parse_positions(path)
  return position.parse_positions(path, hspec.position_query)
end

---Parses hspec --match filter expressions for the top-level test positions.
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs hspec --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] match_opts The hspec --match expression options.
local function parse_top_level_hspec_nodes(mk_match_opts, pos)
  local function prepend_match_opt(match_opts, pos_name)
    return vim.list_extend(match_opts, mk_match_opts('/' .. position.format_name(pos_name) .. '/'))
  end
  local function concat_match_opts(match_opts)
    return match_opts
  end
  local parse = position.mk_top_level_node_parser(prepend_match_opt, concat_match_opts)
  return parse(pos)
end

---Parses the hspec --match expression from a position, starting at a child node, up to its parents.
---@param pos neotest.Tree The position of the test or namespace to get the match for.
---@return string hspec_match_path The hspec --match expression for the test.
local function parse_hspec_tree(pos)
  local function format_result(result)
    return result
  end
  local function prepend_position(result, pos_name)
    return pos_name .. '/' .. result
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
---@param mk_match_opts fun(match_exp:string):string[] Function that constructs hspec --match expression options for a test.
---@param pos neotest.Tree The position to build the --match filter expression from.
---@return string[] hspec_match The hspec match expression for the test or namespace (see example).
local function mk_hspec_match_opts(mk_match_opts, pos)
  local data = pos:data()
  if data.type == 'file' then
    return parse_top_level_hspec_nodes(mk_match_opts, pos)
  end
  return mk_match_opts('/' .. parse_hspec_tree(pos) .. '/')
end

---@param pos neotest.Tree The position.
---@return string[] test_opts The Cabal test options for matching an hspec filter.
function hspec.get_cabal_test_opts(pos)
  local function mk_match_opts(match_exp)
    return {
      '--test-option',
      '-m',
      '--test-option',
      match_exp,
    }
  end
  local match_opts = mk_hspec_match_opts(mk_match_opts, pos)
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
      ('--match "%s"'):format(match_exp),
    }
  end
  local match_opts = mk_hspec_match_opts(mk_match_opts, pos)
  return vim.list_extend(match_opts, {
    '--ta',
    '--no-color --format=checks',
  })
end

local function get_failed_name(line, _, _)
  return line:match('%s*(.*)%s.✘')
end

local function get_succeeded_name(line, _, _)
  return line:match('%s*(.*)%s.✔')
end

local function get_skipped_name(line, _, _)
  return line:match('%s*(.*)%s%[‐%]')
end

---Get the errors from a build output.
---@param raw_lines string[] The raw build output lines.
---@param test_name string The name of the test.
---@return neotest.Error[] hspec_errors The errors.
local function parse_errors(raw_lines, test_name)
  local util = require('neotest-haskell.strings')
  local failures_found = false
  local pos_found = false
  local error_message = nil
  for _, line in ipairs(raw_lines) do
    local trimmed = util.trim(line)
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

hspec.parse_results = results.mk_result_parser(parse_errors, get_failed_name, get_succeeded_name, get_skipped_name)

---@cast hspec TestFrameworkHandler
return hspec
