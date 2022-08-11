-- local lib = require('neotest.lib')

local M = {}

function M.is_test_file(file_path)
  return vim.endswith(file_path, "Spec.hs")
      or vim.endswith(file_path, "Test.hs")
end

return M
