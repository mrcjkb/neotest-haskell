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

return compat
