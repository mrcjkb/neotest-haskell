local async = require('neotest.async')
local Path = require('plenary.path')
local lib = require('neotest.lib')
local base = require('neotest-haskell.base')


---@type neotest.Adapter
local HaskellNeotestAdapter = { name = "neotest-haskell" }

HaskellNeotestAdapter.root = lib.files.match_root_pattern("cabal.project", "stack.yaml")

function HaskellNeotestAdapter.is_test_file(file_path)
  return base.is_test_file(file_path)
end

  -- ;; describe (qualified)
  -- (exp_apply
  --   (exp_name (qualified_variable (_) (variable) @func_name) (#match? @func_name "^describe$"))
  --   (exp_literal) @test_path
  -- ) @test.definition

---@async
---@return neotest.Tree | nil
function HaskellNeotestAdapter.discover_positions(path)
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
  local result = lib.treesitter.parse_positions(path, query, { nested_namespaces = true })
  -- print("Treesitter query result:")
  -- print(vim.inspect(result))
  -- print("End of treesitter query result")
  return result
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function HaskellNeotestAdapter.build_spec(args)
  print("[DEBUG] Building spec...")
  -- local results_path = vim.fn.tempname()
  local tree = args.tree
  if not tree then
    return
  end
  -- print("[DEBUG] Tree: " .. vim.inspect(tree))
  local pos = args.tree:data()
  if pos.type == "dir" then
    return
  end
  print("[DEBUG] pos: " .. vim.inspect(pos))
  -- local filters = {}
  -- TODO
  return {}
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@return neotest.Result[]
function HaskellNeotestAdapter.results(spec, result)
  print("DEBUG: Collecting results...")
  -- TODO
  return {}
end

setmetatable(HaskellNeotestAdapter, {
  __call = function()
    return HaskellNeotestAdapter
  end,
})

return HaskellNeotestAdapter
