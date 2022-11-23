local lib = require('neotest.lib')

local M = {}

-- Wrapper around neotest.lib.treesitter.parse_positions
-- @type neotest.Tree
M.parse_positions = function(path, query)
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true, nested_tests = true })
end

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

-- Escape special string.match characters
M.escape = function(str)
  return str:gsub('.', lua_match_matches)
end

return M
