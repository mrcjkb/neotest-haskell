local async = require('neotest.async')
local Path = require('plenary.path')
local lib = require('neotest.lib')
local base = require('neotest-haskell.base')


local HaskellNeotestAdapter = { name = "neotest-haskell" }

---@type neotest.Adapter
HaskellNeotestAdapter.root = lib.files.match_root_pattern("haskell")

function HaskellNeotestAdapter.is_test_file(file_path)
  return base.is_test_file(file_path)
end

---@async
---@return neotest.Tree | nil
function HaskellNeotestAdapter.discover_positions(path)
  local query = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$")
      arguments: (arguments (_) @namespace.name (function_definition))
  )) @namespace.definition
  ;; it blocks
  ((function_call
      name: (identifier) @func_name
      arguments: (arguments (_) @test.name (function_definition))
  ) (#match? @func_name "^it$")) @test.definition
  ;; prop blocks
  ((function_call
      name: (identifier) @func_name
      arguments: (arguments (_) @test.name (function_definition))
  ) (#match? @func_name "^prop$")) @test.definition
  ;; qualified describe blocks (e.g. Test.describe)
  ((function_call
      name: (
        dot_index_expression 
          field: (identifier) @func_name
      )
      arguments: (arguments (_) @test.name (function_definition))
    ) (#match? @func_name "^describe$")) @test.definition
  ;; qualified it blocks (e.g. Test.it)
  ((function_call
      name: (
        dot_index_expression 
          field: (identifier) @func_name
      )
      arguments: (arguments (_) @test.name (function_definition))
    ) (#match? @func_name "^it$")) @test.definition
  ;; qualified prop blocks (e.g. Test.prop)
  ((function_call
      name: (
        dot_index_expression 
          field: (identifier) @func_name
      )
      arguments: (arguments (_) @test.name (function_definition))
    ) (#match? @func_name "^prop$")) @test.definition
  ]]
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true })
end

return HaskellNeotestAdapter
