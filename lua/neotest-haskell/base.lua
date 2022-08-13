local lib = require('neotest.lib')

local M = {}

function M.is_test_file(file_path)
  return vim.endswith(file_path, "Spec.hs")
      or vim.endswith(file_path, "Test.hs")
end

function M.parse_positions(path)
  local query = [[
  ;; describe (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#match? @func_name "^describe$")) @test.definition
  ;; describe (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#match? @func_name "^describe$")) @test.definition
  ;; it (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#match? @func_name "^it$")) @test.definition
  ;; it (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#match? @func_name "^it$")) @test.definition
  ;; prop (unqualified)
  ((exp_apply
    (exp_name (variable) @func_name)
    (exp_literal) @test.name
  ) (#match? @func_name "^prop$")) @test.definition
  ;; prop (qualified)
  ((exp_apply
    (exp_name (qualified_variable (variable) @func_name))
    (exp_literal) @test.name
  ) (#match? @func_name "^prop$")) @test.definition
  ]]
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true })
end

return M
