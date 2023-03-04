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

return base
