local lib = require('neotest.lib')
local Path = require('plenary.path')

local base = {}

---@param file_path string
---@return boolean
base.is_test_file = function(file_path)
  if not vim.endswith(file_path, '.hs') then
    return false
  end
  return vim.endswith(file_path, 'Spec.hs') or vim.endswith(file_path, 'Test.hs') or vim.endswith(file_path, 'Tests.hs')
end

---@param name string
---@return boolean
base.filter_dir = function(name)
  return name ~= 'dist-newstile' and name ~= '.stack-work'
end

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
---@alias build_tool 'stack' | 'cabal'

--- Select a build tool from the given list of build tools preferring the first that can be used.
---@param test_file_path string file in a project
---@param build_tools build_tool[] List of build tools to choose from
---@return table applicable build tool with metadata about the package
base.select_build_tool = function(test_file_path, build_tools)
  local ret = {}
  -- A package always has a *.cabal file (or in rare cases just a package.yaml file).
  ret.package_root = lib.files.match_root_pattern('*.cabal', 'package.yaml')(test_file_path)
  if not ret.package_root then
    error('No *.cabal or package.yaml in the given path or in any of its parents: ' .. test_file_path)
  end
  -- A project can be a package or a set of packages. The set of packages is usually defined
  -- in the cabal.project file, but it can also only be specified in a stack.yaml file. Any
  -- of these files is optional for a simple single package project.
  local project_dir_with_cabal_project = lib.files.match_root_pattern('cabal.project')(test_file_path)
  local project_dir_with_stack_yaml = lib.files.match_root_pattern('stack.yaml')(test_file_path)
  ret.project_root = project_dir_with_cabal_project or project_dir_with_stack_yaml or ret.package_root
  ret.is_multi_package_project = ret.package_root ~= ret.project_root

  for _, build_tool in pairs(build_tools) do
    if build_tool == 'cabal' and directory_contains_file_matching(ret.package_root, { '*.cabal' }) then
      ret.build_tool = 'cabal'
      return ret
    elseif build_tool == 'stack' and project_dir_with_stack_yaml then
      ret.build_tool = 'stack'
      return ret
    end
  end
  error('Cannot run tests for configured build tools: ' .. vim.inspect(build_tools))
end

return base
