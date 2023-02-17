local lib = require('neotest.lib')

local util = {}

-- Convenience wrapper around neotest.lib.treesitter.parse_positions
---@return table positions neotest.Tree
util.parse_positions = function(path, query)
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true, nested_tests = true })
end

---@type table<string,string>
local lua_match_matches = {
  ['^'] = '%^',
  ['$'] = '%$',
  ['('] = '%(',
  [')'] = '%)',
  ['%'] = '%%',
  ['.'] = '%.',
  ['['] = '%[',
  [']'] = '%]',
  ['*'] = '%*',
  ['+'] = '%+',
  ['-'] = '%-',
  ['?'] = '%?',
  ['\0'] = '%z',
}

---Escape special string.match characters
---@param str string
---@return string escaped_string
util.escape = function(str)
  local escaped_string = str:gsub('.', lua_match_matches)
  return escaped_string
end

return util
