local base = require('neotest-haskell.base')
local hspec = require('neotest-haskell.hspec')
local cabal = require('neotest-haskell.cabal')
local stack = require('neotest-haskell.stack')
local logger = require('neotest.logging')
local lib = require('neotest.lib')

---@type neotest.Adapter
local HaskellNeotestAdapter = { name = 'neotest-haskell' }

---@type fun(file:string):(string|nil)
HaskellNeotestAdapter.root = function(file)
  local multi_package_or_stack_project_root_directory =
    lib.files.match_root_pattern('cabal.project', 'stack.yaml')(file)
  if not multi_package_or_stack_project_root_directory then
    return lib.files.match_root_pattern('*.cabal', 'package.yaml')(file)
  end
end

---@type fun(name:string):boolean
local is_test_file = base.is_test_file

---@type fun(name:string):boolean
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

---@type fun(name:string):boolean
function HaskellNeotestAdapter.is_test_file(file_path)
  return is_test_file(file_path)
end

---@type fun(name:string):boolean
function HaskellNeotestAdapter.filter_dir(...)
  return filter_dir(...)
end

---@async
---@param path string The file path
---@return neotest.Tree|nil pos
function HaskellNeotestAdapter.discover_positions(path)
  local pos = hspec.parse_positions(path)
  logger.debug('Found positions: ' .. vim.inspect(pos))
  return pos
end

---@async
function HaskellNeotestAdapter.build_spec(args)
  local supported_types = { 'test', 'file' }
  local tree = args and args.tree
  if not tree then
    return nil
  end
  local pos = args.tree:data()
  if not vim.tbl_contains(supported_types, pos.type) then
    return nil
  end

  local mkCommand = function(command)
    return {
      command = command,
      context = {
        file = pos.path,
        pos_id = pos.id,
        pos_path = pos.path,
      },
    }
  end

  local build_tool = base.select_build_tool(pos.path, build_tools)

  if build_tool.build_tool == 'stack' then
    return mkCommand(stack.build_command(build_tool.project_root, build_tool.package_root, pos))
  elseif build_tool.build_tool == 'cabal' then
    if build_tool.is_multi_package_project then
      return mkCommand(cabal.build_command(pos, build_tool.package_root))
    else
      return mkCommand(cabal.build_command(pos))
    end
  end

  logger.error('Project is neither a Cabal nor a Stack project.')
end

---@async
function HaskellNeotestAdapter.results(spec, result)
  local pos_id = spec.context.pos_id
  if result.code == 0 then
    return {
      [pos_id] = {
        status = 'passed',
      },
    }
  end
  if vim.tbl_contains(spec.command, 'cabal') then
    return cabal.parse_results(spec.context, result.output)
  end
  return stack.parse_results(spec.context, result.output)
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
