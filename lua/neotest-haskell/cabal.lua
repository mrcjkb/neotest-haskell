local async = require('neotest.async')
local lib = require('neotest.lib')
local logger = require("neotest.logging")
local Path = require('plenary.path')

local M = {}

local function assume_test_suite_name(cabal_file_path)
  logger.debug('Assuming <cabal-file-name>-test.')
  local package_file_name = vim.fn.fnamemodify(cabal_file_path, ':t')
  local package_name = package_file_name:gsub('.cabal', '')
  return package_name .. '-test'
end

local function get_test_suite_name(cabal_file_path)
  local success, data = pcall(lib.files.read, cabal_file_path)
  if not success then
    vim.notify('Failed to read cabal file.', vim.log.levels.ERROR)
    return assume_test_suite_name(cabal_file_path)
  end
  local captures = {}
  for capture in string.gmatch(data, 'test%-suite (.-)\n') do
     table.insert(captures, capture)
  end
  if #captures == 0 then
    logger.error('Cound not extract test suite name(s) from cabal file.')
    return assume_test_suite_name(cabal_file_path)
  end
  -- if #captures > 1 then
    -- TODO: Find solution for this.
    -- [1]: Compare source directories
    -- [2]: On multiple results, run all tests
    -- Cannot use vim.ui.input because this is called within a loop callback
  -- end
  return captures[1]
end

local function get_package_file(package_root)
  for _, package_file_path in ipairs(async.fn.glob(Path:new(package_root, '*.cabal').filename, true, true)) do
    return package_file_path
  end
end

function M.build_command(package_root, hspec_match)
  logger.debug('Building spec for Cabal project...')
  local command = nil
  local package_file_path = get_package_file(package_root)
  if lib.files.exists(package_file_path) then
    local test_suite_name = get_test_suite_name(package_file_path)
    command = vim.tbl_flatten({
      'cabal',
      'new-run',
      test_suite_name,
      '--',
      '--match',
      hspec_match,
    })
    print('(async) Running: cabal new-run ' .. test_suite_name .. ' -- --match ' .. hspec_match)
  end
  return command
end

---@async
---@param out_path string: Path to cabal test results output file
---@return neotest.Result[]
function M.parse_results(out_path)
  vim.pretty_print(out_path)
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
