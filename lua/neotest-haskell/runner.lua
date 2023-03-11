local hspec = require('neotest-haskell.hspec')
local async = require('neotest.async')
local lib = require('neotest.lib')
local Path = require('plenary.path')

local runner = {}

---Check if the given directory contains a file matching a list of patterns.
---@param directory string The directory to check for.
---@param patterns string[] The patterns to check for.
---@return boolean
local function directory_contains_file_matching(directory, patterns)
  for _, pattern in ipairs(patterns) do
    for _, file in ipairs(vim.fn.glob(Path:new(directory, pattern).filename, true, true)) do
      if Path:new(file):exists() then
        return true
      end
    end
  end
  return false
end

---Attempts to determine the package name.
---If a *.cabal is present, this is *.
---Otherwise, we assume the package name is the same as the directory name.
---@param package_root string The package root directory.
---@return string package_name The assumed package name.
local function get_package_name(package_root)
  for _, package_file_path in ipairs(async.fn.glob(Path:new(package_root, '*.cabal').filename, true, true)) do
    local package_file_name = package_file_path and vim.fn.fnamemodify(package_file_path, ':t')
    local package_name = package_file_name and package_file_name:gsub('.cabal', '')
    if package_name then
      return package_name
    end
  end
  -- XXX: Here, we assume the package is named the same as the directory.
  -- This is usually the case, but doesn't have to be.
  -- A more stable option would be to parse the package.yaml.
  return vim.fn.fnamemodify(package_root, ':t')
end

---Select a build tool from the given list of build tools preferring the first that can be used.
---@param test_file_path string A test file in a project.
---@param build_tools build_tool[] List of build tools to choose from.
---@return fun(neotest.Tree):neotest.RunSpec mk_command A function that builds the runner command using the selected build tool for a test tree.
function runner.select_build_tool(test_file_path, build_tools)
  -- A package always has a *.cabal file (or in rare cases just a package.yaml file).
  local package_root = lib.files.match_root_pattern('*.cabal', 'package.yaml')(test_file_path)
  if not package_root then
    error('No *.cabal or package.yaml in the given path or in any of its parents: ' .. test_file_path)
  end
  -- A project can be a package or a set of packages. The set of packages is usually defined
  -- in the cabal.project file, but it can also only be specified in a stack.yaml file. Any
  -- of these files is optional for a simple single package project.
  local project_dir_with_cabal_project = lib.files.match_root_pattern('cabal.project')(test_file_path)
  local project_dir_with_stack_yaml = lib.files.match_root_pattern('stack.yaml')(test_file_path)
  local project_root = project_dir_with_cabal_project or project_dir_with_stack_yaml or package_root
  local is_multi_package_project = package_root ~= project_root

  local selected_build_tool
  ---@type fun(neotest.Position):string[]
  local get_test_opts
  for _, build_tool in pairs(build_tools) do
    selected_build_tool = build_tool
    if build_tool == 'cabal' and directory_contains_file_matching(package_root, { '*.cabal' }) then
      get_test_opts = hspec.get_cabal_test_opts
      break
    elseif build_tool == 'stack' and project_dir_with_stack_yaml then
      get_test_opts = hspec.get_stack_test_opts
      break
    end
  end
  if not selected_build_tool or not get_test_opts then
    error('Cannot run tests for configured build tools: ' .. vim.inspect(build_tools))
  end

  local command = { selected_build_tool, 'test' }
  if is_multi_package_project then
    local package_name = get_package_name(package_root)
    table.insert(command, package_name)
  end
  return function(pos)
    local test_opts = pos and get_test_opts(pos)
    return test_opts and vim.list_extend(command, test_opts) or command
  end
end

return runner
