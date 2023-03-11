local lib = require('neotest.lib')

local util = {}

---Convenience wrapper around neotest.lib.treesitter.parse_positions.
---@async
---@param path string Test file path
---@param query string tree-sitter query
---@param opts table? parse options
---@return neotest.Tree positions
util.parse_positions = function(path, query, opts)
  opts = vim.tbl_extend('keep', opts or {}, { nested_namespaces = true, nested_tests = false })
  return lib.treesitter.parse_positions(path, query, opts)
end

---Table mapping special characters in `string.match` to their escaped characters.
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

---Escape special string.match characters.
---@param str string
---@return string escaped_string
util.escape = function(str)
  local escaped_string = str:gsub('.', lua_match_matches)
  return escaped_string
end

return util
