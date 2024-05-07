---@toc neotest-haskell.contents

---@mod neotest-haskell.setup Setup

---@brief [[
---Make sure the Haskell parser for tree-sitter is installed:
--->lua
--- require('nvim-treesitter.configs').setup {
---   ensure_installed = {
---     'haskell',
---     --...,
---   },
--- }
---<
---Add `neotest-haskell` to your `neotest` adapters:
--->lua
--- require('neotest').setup {
---   -- ...,
---   adapters = {
---     -- ...,
---     require('neotest-haskell')
---   },
--- }
---<
---You can also pass a config to the setup. The following are the defaults:
--->lua
--- require('neotest').setup {
---   adapters = {
---     require('neotest-haskell') {
---       -- Default: Use stack if possible and then try cabal
---       build_tools = { 'stack', 'cabal' },
---       -- Default: Check for tasty first, then try hspec, and finally 'sydtest'
---       frameworks = { 'tasty', 'hspec', 'sydtest' },
---     },
---   },
--- }
---<
---Alternately, you can pair each test framework with a list of modules,
---used to identify the respective framework in a test file:
--->lua
--- require('neotest').setup {
---   adapters = {
---     require('neotest-haskell') {
---       frameworks = {
---         { framework = 'tasty', modules = { 'Test.Tasty', 'MyTestModule' }, },
---         'hspec',
---         'sydtest',
---       },
---     },
---   },
--- }
---<
---@brief ]]

---@mod neotest-haskell.options Options

---@class NeotestHaskellOpts
---@field build_tools build_tool[] | nil The build tools, ordered by priority. Default: `{ 'stack', 'cabal' }`.
---@field frameworks framework_opt[] | nil List of frameworks or framework specs, ordered by priority. Default: `{ 'tasty', 'hspec', 'sydtest' }`.
---@field is_test_file (fun(name:string):boolean) | nil Used to detect if a file is a test file.
---@field filter_dir (fun(name:string, rel_path:string, root:string):boolean) | nil Filter directories when searching for test files
---@see neotest

---@alias build_tool 'stack' | 'cabal'

---@alias framework_opt test_framework | FrameworkSpec

---@alias test_framework 'tasty' | 'hspec' | 'sydtest'

---@class FrameworkSpec
---@field framework test_framework
---@field modules string[] The modules to query for in test files, to determine if this framework can be used.

local base = require('neotest-haskell.base')
local runner = require('neotest-haskell.runner')

---@class neotest-haskell.Adapter: neotest.Adapter
local HaskellNeotestAdapter = { name = 'neotest-haskell' }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string|nil @Absolute root dir of test suite
---@see neotest.Adapter
---@private
function HaskellNeotestAdapter.root(dir)
  local lib = require('neotest.lib')
  local multi_package_or_stack_project_root_directory = lib.files.match_root_pattern('cabal.project', 'stack.yaml')(dir)
  return multi_package_or_stack_project_root_directory or lib.files.match_root_pattern('*.cabal', 'package.yaml')(dir)
end

---@type fun(name:string):boolean
---@private
local is_test_file = base.is_test_file

---@type fun(name:string, _:string, _:string):boolean
---@private
local filter_dir = base.filter_dir

local build_tools = runner.supported_build_tools

local frameworks = runner.supported_frameworks

---@async
---@param file_path string
---@return boolean
---@see neotest.Adapter
---@private
function HaskellNeotestAdapter.is_test_file(file_path)
  return is_test_file(file_path)
end

---Filter directories when searching for test files
---@async
---@return boolean
---@see neotest.Adapter
---@private
function HaskellNeotestAdapter.filter_dir(...)
  return filter_dir(...)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
---@private
function HaskellNeotestAdapter.discover_positions(file_path)
  local logger = require('neotest.logging')
  local handler = runner.select_framework(file_path, frameworks)
  local pos = handler.parse_positions(file_path)
  logger.debug('Found positions: ' .. vim.inspect(pos))
  return pos
end

---@param args neotest.RunArgs
---@return neotest.RunSpec|nil
---@private
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
---@private
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
  ---@param opts NeotestHaskellOpts
  __call = function(_, opts)
    local validate = require('neotest-haskell.validate')
    validate.validate(opts)
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
