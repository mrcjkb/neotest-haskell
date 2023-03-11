local health = {}

local h = vim.health or require('health')

---@class LuaDependency
---@field module string The name of a module
---@field optional fun():boolean Function that returns whether the dependency is optional
---@field url string URL (markdown)
---@field info string Additional information

---@type LuaDependency[]
local lua_dependencies = {
  {
    module = 'neotest',
    optional = function()
      return false
    end,
    url = '[nvim-neotest/neotest](https://github.com/nvim-neotest/neotest)',
    info = '',
  },
  {
    module = 'plenary',
    optional = function()
      return false
    end,
    url = '[nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)',
    info = '',
  },
  {
    module = 'nvim-treesitter',
    optional = function()
      return false
    end,
    url = '[nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)',
    info = '',
  },
}

---@class ExternalDependency
---@field name string Name of the dependency
---@field get_binaries fun():string[]Function that returns the binaries to check for
---@field optional fun():boolean Function that returns whether the dependency is optional
---@field url string URL (markdown)
---@field info string Additional information
---@field extra_checks function Optional extra checks to perform if the dependency is installed

---@type ExternalDependency[]
local external_dependencies = {
  {
    name = 'Cabal',
    get_binaries = function()
      return { 'cabal' }
    end,
    optional = function()
      return true
    end,
    url = '[Cabal](https://www.haskell.org/cabal/)',
    info = 'Required for running tests in Cabal projects.',
  },
  {
    name = 'Stack',
    get_binaries = function()
      return { 'stack' }
    end,
    optional = function()
      return true
    end,
    url = '[Stack](https://docs.haskellstack.org/en/stable/)',
    info = 'Required for running tests in Stack projects.',
  },
}

---@param modname string
---@return boolean has_module
local function has_module(modname)
  local has_mod, _ = pcall(require, modname)
  return has_mod
end

---@param dep LuaDependency
local function check_lua_dependency(dep)
  if has_module(dep.module) then
    h.report_ok(dep.url .. ' installed.')
    return
  end
  if dep.optional() then
    h.report_warn(('%s not installed. %s %s'):format(dep.module, dep.info, dep.url))
  else
    h.report_error(('Lua dependency %s not found: %s'):format(dep.module, dep.url))
  end
end

---@param dep ExternalDependency
---@return boolean is_installed
---@return string|nil version
local check_installed = function(dep)
  local binaries = dep.get_binaries()
  for _, binary in ipairs(binaries) do
    if vim.fn.executable(binary) == 1 then
      local handle = io.popen(binary .. ' --version')
      if handle then
        local binary_version, error_msg = handle:read('*a')
        handle:close()
        if error_msg then
          return true
        end
        return true, binary_version
      end
      return true
    end
  end
  return false
end

---@param dep ExternalDependency
local function check_external_dependency(dep)
  local installed, mb_version = check_installed(dep)
  if installed then
    local version = mb_version and mb_version:sub(0, mb_version:find('\n') - 1) or '(unknown version)'
    h.report_ok(('%s: found %s'):format(dep.name, version))
    if dep.extra_checks then
      dep.extra_checks()
    end
    return
  end
  if dep.optional() then
    h.report_warn(([[
      %s: not found.
      Install %s for extended capabilities.
      %s
      ]]):format(dep.name, dep.url, dep.info))
  else
    h.report_error(([[
      %s: not found.
      haskell-tools.nvim requires %s.
      %s
      ]]):format(dep.name, dep.url, dep.info))
  end
end

function health.check()
  h.report_start('Checking for Lua dependencies')
  for _, dep in ipairs(lua_dependencies) do
    check_lua_dependency(dep)
  end

  h.report_start('Checking external dependencies')
  for _, dep in ipairs(external_dependencies) do
    check_external_dependency(dep)
  end
end

return health
