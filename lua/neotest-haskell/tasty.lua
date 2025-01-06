local treesitter = require('neotest-haskell.treesitter')
local util = require('neotest-haskell.strings')
local position = require('neotest-haskell.position')
local results = require('neotest-haskell.results')
local hspec = require('neotest-haskell.hspec')

local tasty = {}

tasty.default_modules = { 'Test.Tasty' }

tasty.position_query = hspec.position_query .. treesitter.get_position_query('tasty')

---Parse the positions in a test file.
---@async
---@param path string Test file path
---@return neotest.Tree
function tasty.parse_positions(path)
  return position.parse_positions(path, tasty.position_query)
end

---Format a test name for use in a filter expression.
---@param name string The test name to format.
---@return string formatted_name
local function format_position_name(name)
  return '/' .. position.format_name(name) .. '/'
end

---Parses tasty --pattern filter expressions for the top-level test positions.
---@param pos neotest.Tree The position to build the --pattern filter expression from.
---@return string|nil pattern The tasty --pattern expression.
local function parse_top_level_tasty_nodes(pos)
  local function prepend_subpatterns(subpatterns, pos_name)
    table.insert(subpatterns, format_position_name(pos_name))
    return subpatterns
  end
  local function concat_subpatterns(subpatterns)
    if not subpatterns or #subpatterns == 0 then
      local logger = require('neotest.logging')
      logger.error('Could not detect tasty top level nodes.')
      return nil
    end
    return '$0~' .. table.concat(subpatterns, '||')
  end
  local parse = position.mk_top_level_node_parser(prepend_subpatterns, concat_subpatterns)
  return parse(pos)
end

---Parses the tasty --filter expression from a position, starting at a child node, up to its parents.
---@param pos neotest.Tree The position of the test or namespace to get the pattern for.
---@return string|nil pattern The tasty --pattern expression for the test.
local function parse_tasty_tree(pos)
  local function format_result(result)
    if not result or result == '' then
      local logger = require('neotest.logging')
      logger.error('Could not detect any tasty patterns.')
      return nil
    end
    return '$0~' .. result
  end
  local function prepend_position(result, pos_name)
    return pos_name .. (result and '&&' .. result or '')
  end
  local parse = position.mk_test_tree_parser(format_position_name, format_result, prepend_position)
  return parse(pos)
end

---Constructs the Tasty --pattern filter for a position.
---Example:
---
--- - position.name: "My test"
--- - Tasty tests in path:
---   ```haskell
---   testGroup "Run" [
---     testCase "My test" $ do --...
---   ]
---   ```
--- - Result: "$0 ~ /Run.My test/"
---@param pos neotest.Tree The position to build the --pattern filter expression from.
---@return string|nil pattern The tasty pattern expression for the test or namespace (see example).
local function mk_tasty_pattern(pos)
  local data = pos:data()
  if data.type == 'file' then
    return parse_top_level_tasty_nodes(pos)
  end
  return parse_tasty_tree(pos)
end

---@param pos neotest.Tree The position.
---@return string[] test_opts The Cabal test options for matching a tasty filter.
function tasty.get_cabal_test_opts(pos)
  local pattern = mk_tasty_pattern(pos)
  return pattern
      and {
        '--test-option',
        '--color',
        '--test-option',
        'never',
        '--test-option',
        '-p',
        '--test-option',
        pattern,
      }
    or {}
end

---@param pos neotest.Tree The position.
---@return string[] test_opts The Stack test options for matching a tasty filter.
function tasty.get_stack_test_opts(pos)
  local pattern = mk_tasty_pattern(pos)
  return pattern and {
    '--ta',
    '-p "' .. pattern .. '"',
  } or {}
end

local function get_failed_name(line, lines, idx)
  local test_name = line:match('%s*(.*):%s*FAIL')
  if not lines or #lines == idx then
    return test_name
  end
  local next_line = lines[idx + 1]
  if not next_line:match('# PENDING') then
    return test_name
  end
end

local function get_succeeded_name(line, _, _)
  return line:match('%s*(.*):%s*OK')
end

local function get_skipped_name(line, lines, idx)
  local test_name = line:match('%s*(.*):%s*FAIL')
  if lines and #lines > idx then
    local next_line = lines[idx + 1]
    if next_line:match('# PENDING') then
      return test_name
    end
  end
end

---@param line string
---@return boolean
local function is_error_message_line_candidate(line)
  return not (
    line:match(util.escape('Use -p ')) ~= nil
    or line:match(util.escape('tests failed (0.00s)')) ~= nil
    or get_failed_name(line) ~= nil
    or get_succeeded_name(line) ~= nil
  )
end

---Get the errors from a build output.
---@param raw_lines string[] The raw build output lines.
---@param test_name string The name of the test.
---@return neotest.Error[] tasty_errors The errors.
local function parse_errors(raw_lines, test_name)
  for idx, line in ipairs(raw_lines) do
    local trimmed = util.trim(line)
    local failed = get_failed_name(trimmed)
    if failed and trimmed:match('.*' .. util.escape(test_name) .. '.*') then
      local next_idx = idx + 1
      local error_message = nil
      while raw_lines[next_idx] and is_error_message_line_candidate(raw_lines[next_idx]) do
        local trimmed_error_msg_line = util.trim(raw_lines[next_idx])
        error_message = error_message and error_message .. '\n' .. trimmed_error_msg_line or trimmed_error_msg_line
        next_idx = next_idx + 1
      end
      return { {
        message = error_message,
      } }
    end
  end
  return {}
end

tasty.parse_results = results.mk_result_parser(parse_errors, get_failed_name, get_succeeded_name, get_skipped_name)

---@cast tasty TestFrameworkHandler
return tasty
