local base = require('neotest-haskell.base')
local runner = require('neotest-haskell.runner')
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

---@param supported_elems any[]
---@param list any[]
local function validate_is_supported(supported_elems, list)
  if #list == 0 then
    return false
  end
  for _, elem in ipairs(list) do
    if not vim.tbl_contains(supported_elems, elem) then
      return false
    end
  end
  return true
end

---@type build_tool[]
local supported_build_tools = { 'stack', 'cabal' }
local build_tools = supported_build_tools
local function validate_build_tools(bts)
  return validate_is_supported(supported_build_tools, bts)
end

---@type test_framework[]
local supported_frameworks = { 'tasty', 'hspec' }
local frameworks = supported_frameworks
local function validate_frameworks(fws)
  return validate_is_supported(supported_frameworks, fws)
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
  local handler = runner.select_framework(file_path, frameworks)
  local pos = handler.parse_positions(file_path)
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
  local handler = runner.select_framework(data.path, frameworks)
  local mk_command = runner.select_build_tool(handler, data.path, build_tools)
  return {
    command = mk_command(pos),
    ---@type RunContext
    context = {
      file = data.path,
      pos_id = data.id,
      type = data.type,
      handler = handler,
    },
  }
end

---@async
---@param spec neotest.RunSpec
---@param strategy_result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result> results
function HaskellNeotestAdapter.results(spec, strategy_result, tree)
  ---@type RunContext
  local context = spec.context
  local pos_id = context.pos_id
  if strategy_result.code == 0 then
    return {
      [pos_id] = { status = 'passed' },
    }
  end
  local parse_results = context.handler.parse_results
  if parse_results then
    return parse_results(spec.context, strategy_result.output, tree)
  end
  return {
    [pos_id] = { status = 'failed' },
  }
end

setmetatable(HaskellNeotestAdapter, {
  __call = function(_, opts)
    vim.validate {
      build_tools = {
        opts.build_tools or build_tools,
        validate_build_tools,
        'at least one of ' .. table.concat(supported_build_tools, ', '),
      },
      frameworks = {
        opts.frameworks or frameworks,
        validate_frameworks,
        'at least one of ' .. table.concat(supported_frameworks, ', '),
      },
    }
    if opts.build_tools then
      build_tools = opts.build_tools
    end
    if opts.frameworks then
      frameworks = opts.frameworks
    end
    is_test_file = opts.is_test_file or is_test_file
    filter_dir = opts.filter_dir or filter_dir
    return HaskellNeotestAdapter
  end,
})

return HaskellNeotestAdapter
