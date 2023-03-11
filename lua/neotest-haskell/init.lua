local base = require('neotest-haskell.base')
local runner = require('neotest-haskell.runner')
local hspec = require('neotest-haskell.hspec')
local logger = require('neotest.logging')
local lib = require('neotest.lib')

---@type neotest.Adapter
local HaskellNeotestAdapter = { name = 'neotest-haskell' }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string|nil @Absolute root dir of test suite
---@see neotest.Adapter
function HaskellNeotestAdapter.root(dir)
  local multi_package_or_stack_project_root_directory = lib.files.match_root_pattern('cabal.project', 'stack.yaml')(dir)
  return multi_package_or_stack_project_root_directory or lib.files.match_root_pattern('*.cabal', 'package.yaml')(dir)
end

---@type fun(name:string):boolean
local is_test_file = base.is_test_file

---@type fun(name:string, _:string, _:string):boolean
local filter_dir = base.filter_dir

---@type build_tool[]
local supported_build_tools = { 'stack', 'cabal' }
local build_tools = supported_build_tools
local function validate_build_tools(bts)
  if #bts == 0 then
    return false
  end
  for _, build_tool in ipairs(bts) do
    if not vim.tbl_contains(supported_build_tools, build_tool) then
      return false
    end
  end
  return true
end

---@async
---@param file_path string
---@return boolean
---@see neotest.Adapter
function HaskellNeotestAdapter.is_test_file(file_path)
  return is_test_file(file_path)
end

---Filter directories when searching for test files
---@async
---@return boolean
---@see neotest.Adapter
function HaskellNeotestAdapter.filter_dir(...)
  return filter_dir(...)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function HaskellNeotestAdapter.discover_positions(file_path)
  local pos = hspec.parse_positions(file_path)
  logger.debug('Found positions: ' .. vim.inspect(pos))
  return pos
end

---@param args neotest.RunArgs
---@return neotest.RunSpec|nil
function HaskellNeotestAdapter.build_spec(args)
  local supported_types = { 'test', 'namespace', 'file' }
  local tree = args and args.tree
  if not tree then
    return
  end
  local pos = args.tree
  local data = pos:data()
  if data.type == 'dir' then
    return
  end
  if not vim.tbl_contains(supported_types, data.type) then
    return
  end
  local mk_command = runner.select_build_tool(data.path, build_tools)
  return {
    command = mk_command(pos),
    ---@type RunContext
    context = {
      file = data.path,
      pos_id = data.id,
      type = data.type,
    },
  }
end

---@async
---@param spec neotest.RunSpec
---@param strategy_result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result> results
function HaskellNeotestAdapter.results(spec, strategy_result, tree)
  local pos_id = spec.context.pos_id
  if strategy_result.code == 0 then
    return {
      [pos_id] = { status = 'passed' },
    }
  end
  return hspec.parse_results(spec.context, strategy_result.output, tree)
end

setmetatable(HaskellNeotestAdapter, {
  __call = function(_, opts)
    vim.validate {
      build_tools = {
        opts.build_tools or build_tools,
        validate_build_tools,
        'at least one of ' .. table.concat(supported_build_tools, ', '),
      },
    }
    if opts.build_tools then
      build_tools = opts.build_tools
    end
    is_test_file = opts.is_test_file or is_test_file
    filter_dir = opts.filter_dir or filter_dir
    return HaskellNeotestAdapter
  end,
})

return HaskellNeotestAdapter
