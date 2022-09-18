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
  if #captures > 1 then
    local coro = coroutine.create(
      function()
        vim.ui.select(
          captures,
          {prompt = "Select a test suite to run"},
          function(choice)
            coroutine.yield(choice)
          end
        )
      end
    )
    local ok, ret = coroutine.resume(coro)
    return ok and ret or captures[1]
  end
  return captures[1]
end

function M.build_command(package_root, hspec_match)
  logger.debug('Building spec for Cabal project...')
  local command = nil
  for _, package_file_path in ipairs(async.fn.glob(Path:new(package_root, '*.cabal').filename, true, true)) do
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
      vim.notify('(async) Running: cabal new-run ' .. test_suite_name .. '-test -- --match ' .. hspec_match)
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
