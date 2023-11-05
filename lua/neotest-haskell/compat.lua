---@diagnostic disable: deprecated, duplicate-doc-field
---@mod neotest-haskell.compat Functions for backward compatibility with older Neovim versions
---@brief [[

---WARNING: This is not part of the public API.
---Breaking changes to this module will not be reflected in the semantic versioning of this plugin.

---@brief ]]

local compat = {}

compat.joinpath = vim.fs.joinpath or function(...)
  return (table.concat({ ... }, '/'):gsub('//+', '/'))
end

-- TODO: Make `nio` compatible with luassert/busted
-- and then remove this workaround
compat.with_timeout = function(func, timeout)
  local tasks = require('nio.tasks')
  local success, err
  return function()
    local task = tasks.run(func, function(success_, err_)
      success = success_
      if not success_ then
        err = err_
      end
    end)

    vim.wait(timeout or 2000, function()
      return success ~= nil
    end, 20, false)

    if success == nil then
      error(string.format('Test task timed out\n%s', task.trace()))
    elseif not success then
      error(string.format('Test task failed with message:\n%s', err))
    end
  end
end

return compat
