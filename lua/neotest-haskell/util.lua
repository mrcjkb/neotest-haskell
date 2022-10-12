local lib = require('neotest.lib')

local M = {}

-- Wrapper around neotest.lib.treesitter.parse_positions
-- @type neotest.Tree
M.parse_positions = function(path, query)
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true, nested_tests = true, })
end

return M
