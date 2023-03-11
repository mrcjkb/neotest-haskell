local base = {}

---@async
---@param file_path string
---@return boolean
base.is_test_file = function(file_path)
  if not vim.endswith(file_path, '.hs') then
    return false
  end
  return vim.endswith(file_path, 'Spec.hs') or vim.endswith(file_path, 'Test.hs') or vim.endswith(file_path, 'Tests.hs')
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@return boolean
base.filter_dir = function(name, _, _)
  return name ~= 'dist-newstile' and name ~= '.stack-work'
end

return base
