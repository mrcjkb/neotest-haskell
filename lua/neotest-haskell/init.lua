local lib = require('neotest.lib')
local base = require('neotest-haskell.base')
local cabal = require("neotest-haskell.cabal")
local stack = require("neotest-haskell.stack")
local logger = require("neotest.logging")


---@type neotest.Adapter
local HaskellNeotestAdapter = { name = 'neotest-haskell' }


HaskellNeotestAdapter.root = base.match_package_root_pattern

local is_test_file = base.is_test_file

function HaskellNeotestAdapter.is_test_file(file_path)
  return is_test_file(file_path)
end


---@async
---@return neotest.Tree | nil
function HaskellNeotestAdapter.discover_positions(path)
  return base.parse_positions(path)
end


---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function HaskellNeotestAdapter.build_spec(args)
  local tree = args.tree
  if not tree then
    return
  end
  local pos = args.tree:data()
  if pos.type ~= "test" then
    return
  end

  local hspec_match = base.get_hspec_match(pos)
  local package_root = base.match_package_root_pattern(pos.path)
  local project_root = base.match_project_root_pattern(pos.path)

  local command = nil
  if lib.files.exists(project_root .. '/cabal.project') then
    return cabal.build_command(package_root, hspec_match)
  elseif lib.files.exists(project_root .. 'package.yaml') then
    return stack.build_command(project_root, package_root, hspec_match)
  else
    logger.error( 'Project is neither a Cabal nor a Stack project.')
  end

  if not command then
    return {}
  end

  return {
    command = command,
    context = {
      file = pos.path,
      pos_id = pos.id,
      pos_path = pos.path,
    },
  }
end


---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@return neotest.Result[]
function HaskellNeotestAdapter.results(spec, result)
  local pos_id = spec.context.pos_id
  if result.code == 0 then
    return { [pos_id] = {
      status = "passed"
    } }
  end
  print("Spec:")
  vim.pretty_print(spec)
  print("Result:")
  vim.pretty_print(result)
  local out_file = result.output
  if vim.tbl_contains(spec.command, 'cabal') then
    print('Out file: ' .. out_file)
    return cabal.results(out_file)
  end
  return stack.results(out_file)
end

setmetatable(HaskellNeotestAdapter, {
  __call = function(_, opts)
    is_test_file = opts.is_test_file or is_test_file
    return HaskellNeotestAdapter
  end,
})

return HaskellNeotestAdapter
