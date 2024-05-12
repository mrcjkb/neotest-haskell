local compat = require('neotest-haskell.compat')
local runner = {}

---Check if the given directory contains a file matching a list of patterns.
---@param directory string The directory to check for.
---@param patterns string[] The patterns to check for.
---@return boolean
local function directory_contains_file_matching(directory, patterns)
  for _, pattern in ipairs(patterns) do
    for _, file in ipairs(vim.fn.glob(compat.joinpath(directory, pattern), true, true)) do
      if vim.fn.filereadable(file) == 1 then
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
---@return string | nil package_name The assumed package name.
local function get_package_name(package_root)
  local ok, nio = pcall(require, 'nio')
  if not ok then
    nio = require('neotest.async')
  end
  ---@diagnostic disable-next-line private -- nio.fn is private?
  local glob = nio.fn.glob
  for _, package_file_path in ipairs(glob(compat.joinpath(package_root, '*.cabal'), true, true)) do
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

---@param modules string[]
---@return string treesitter_query The query to match the modules
local function mk_module_query(modules)
  local filters = {}
  for i, module_name in ipairs(modules) do
    local filter = ([[
    ;;query
    (module_id) @mod%d
    (#eq? @mod%d "%s")
    ]]):format(i, i, module_name)
    table.insert(filters, filter)
  end
  return [[
  ;;query
  (module
  ]] .. table.concat(filters, '\n') .. [[
  ;;query
  )
  ]]
end

---Check if the test file has any of the specified imports
---@param test_file_content string The test file content
---@param qualified_modules string[] Qualified modules to check for, e.g. { 'Test.Tasty', 'MyTestRunner' }
---@return boolean
---@async
local function has_module(test_file_content, qualified_modules)
  local treesitter_hs = require('neotest-haskell.treesitter')
  for _, qualified_module in pairs(qualified_modules) do
    local modules = {}
    for module in qualified_module:gmatch('([^%.]+)') do
      table.insert(modules, module)
    end
    local query = mk_module_query(modules)
    ---@type FileContentRef
    local contentRef = { content = test_file_content }
    if treesitter_hs.has_matches(query, contentRef) then
      return true
    end
  end
  return false
end

---@type build_tool[]
runner.supported_build_tools = { 'stack', 'cabal' }

---@type test_framework[]
runner.supported_frameworks = { 'tasty', 'hspec', 'sydtest' }

---@param framework test_framework
---@return TestFrameworkHandler
local function get_handler(framework)
  return require('neotest-haskell.' .. framework)
end

---Select a test framework from the given list of test frameworks, preferring the first that can be used.
---If there is only one framework, it will
---@param test_file_path string A test file in a project.
---@param frameworks framework_opt[]
---@return TestFrameworkHandler handler
---@async
function runner.select_framework(test_file_path, frameworks)
  local lib = require('neotest.lib')
  local logger = require('neotest.logging')
  local content = lib.files.read(test_file_path)
  ---@type FrameworkSpec[]
  local framework_specs = {}
  for _, framework in pairs(frameworks) do
    if type(framework) == 'string' then
      ---@cast framework test_framework
      local handler = get_handler(framework)
      framework_specs[#framework_specs + 1] = {
        framework = framework,
        modules = handler.default_modules,
      }
    elseif type(framework) == 'table' then
      ---@cast framework FrameworkSpec
      framework_specs[#framework_specs + 1] = framework
    else
      error('Unexpected framework type: ' .. type(framework))
    end
  end
  for _, spec in pairs(framework_specs) do
    if has_module(content, spec.modules) then
      logger.debug('Selected Haskell framework: ' .. spec.framework)
      return get_handler(spec.framework)
    end
  end
  error('Could not find a test framework handler for ' .. test_file_path)
end

---Select a build tool from the given list of build tools, preferring the first that can be used.
---@param handler TestFrameworkHandler
---@param test_file_path string A test file in a project.
---@param build_tools build_tool[] List of build tools to choose from.
---@return fun(neotest.Tree):neotest.RunSpec mk_command A function that builds the runner command using the selected build tool for a test tree.
function runner.select_build_tool(handler, test_file_path, build_tools)
  local lib = require('neotest.lib')
  local logger = require('neotest.logging')
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
      get_test_opts = handler.get_cabal_test_opts
      break
    elseif build_tool == 'stack' and project_dir_with_stack_yaml then
      get_test_opts = handler.get_stack_test_opts
      break
    end
  end
  if not selected_build_tool or not get_test_opts then
    error('Cannot run tests for configured build tools: ' .. vim.inspect(build_tools))
  end

  logger.debug('Selected Haskell build tool: ' .. selected_build_tool)

  local command = { selected_build_tool, 'test' }
  if is_multi_package_project then
    local package_name = get_package_name(package_root)
    if package_name then
      table.insert(command, package_name)
    end
  end
  return function(pos)
    local test_opts = pos and get_test_opts(pos)
    return test_opts and vim.list_extend(command, test_opts) or command
  end
end

return runner
