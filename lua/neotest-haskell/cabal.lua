local async = require('neotest.async')
local lib = require('neotest.lib')
local logger = require("neotest.logging")
local Path = require('plenary.path')

local M = {}

function M.build_command(package_root, hspec_match)
  logger.debug('Building spec for Cabal project...')
  local command = nil
  for _, package_file_path in ipairs(async.fn.glob(Path:new(package_root, '*.cabal').filename, true, true)) do
    if lib.files.exists(package_file_path) then
      -- local package_cabal_file = package_root .. '/package.yaml'
      local package_file_name = vim.fn.fnamemodify(package_file_path, ':t')
      local package_name = package_file_name:gsub('.cabal', '')
      command = vim.tbl_flatten({
        'cabal',
        'new-run',
        package_name .. '-test',
        '--',
        '--match',
        hspec_match,
      })
      vim.notify('(async) Running: cabal new-run ' .. package_name .. '-test -- --match ' .. hspec_match)
      break
    end
  end
  return command
end

---@async
---@param out_path string: Path to cabal test results output file
---@return neotest.Result[]
function M.parse_results(out_path)
  local success, data = pcall(lib.files.read, out_path)
  if not success then
    vim.notify('Failed to read cabal output.', vim.log.levels.ERROR)
    return {}
  end
  print('Data:')
  vim.pretty_print(data)
  return {} -- TODO
end

return M
